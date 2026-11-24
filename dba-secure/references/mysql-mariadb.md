# MySQL / MariaDB: hardening and audit

References: MySQL 8.0/8.4 LTS and MariaDB 10.11/11.x. Many settings are shared,
but `audit_log`, `validate_password` and plugin names differ.

## 1. Network and TLS

```ini
[mysqld]
bind-address = 10.0.0.10
require_secure_transport = ON
tls_version = TLSv1.2,TLSv1.3
ssl_ca = /etc/mysql/certs/ca.pem
ssl_cert = /etc/mysql/certs/server.pem
ssl_key = /etc/mysql/certs/server-key.pem
skip_name_resolve = ON
```

- `bind-address` on the private interface; never `0.0.0.0` in production.
- Verify: `SHOW VARIABLES LIKE 'have_ssl';` and
  `SHOW VARIABLES LIKE 'require_secure_transport';`
- MariaDB: `SHOW VARIABLES LIKE 'have_ssl';` returns `YES` when TLS is active.

## 2. Authentication and accounts

```sql
CREATE USER 'app_rw'@'10.0.1.%' IDENTIFIED BY :pw
  REQUIRE SSL WITH MAX_USER_CONNECTIONS 50 PASSWORD EXPIRE INTERVAL 180 DAY;
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'app_rw'@'10.0.1.%';

-- root locally only, with a strong plugin
ALTER USER 'root'@'localhost' IDENTIFIED BY :rootpw;
```

- MySQL 8 defaults to `caching_sha2_password`. Remove `mysql_native_password`
  once all clients support it.
- MariaDB: `mysql_native_password` or `ed25519`; consider `unix_socket` for
  local administration and disable remote `root` access.
- No anonymous accounts: `SELECT user, host FROM mysql.user WHERE user = '';`
  must return nothing.
- Avoid `%` unless truly required, and always with TLS and a firewall.
- Check for empty `authentication_string` (blank password).
- `mysql.user` needs privileges; if unavailable, report the visibility gap.

## 3. Privileges

```sql
SHOW GRANTS FOR 'app_rw'@'10.0.1.%';

-- Look for dangerous global privileges
SELECT grantee, privilege_type FROM information_schema.user_privileges
WHERE privilege_type IN ('SUPER','FILE','PROCESS','SHUTDOWN','CREATE USER',
                         'RELOAD','REPLICATION SLAVE','GRANT OPTION');

-- Grants with DB/table wildcards
SELECT user, host, db FROM mysql.db WHERE db IN ('%','');
```

- The application must not have `SUPER`, `FILE`, `PROCESS` or `GRANT OPTION`.
- `FILE` allows reading and writing OS files: critical.
- `secure_file_priv` to a dedicated directory not writable by the application.
- `local_infile = OFF` unless justified.

## 4. Server hardening

```ini
local_infile = OFF
secure_file_priv = /var/lib/mysql-files
skip_symbolic_links = ON
sql_mode = STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
max_connections = 300
wait_timeout = 600
interactive_timeout = 600
```

- `STRICT` prevents silent truncation that corrupts data.
- Disable obsolete engines (`MyISAM` unless documented legacy).
- Enable `log_bin` with enough retention for PITR and replicas.
- `performance_schema` helps detect anomalous statements.

## 5. Auditing

MySQL Enterprise / Community:
```ini
[mysqld]
plugin-load-add = audit_log.so
audit_log_format = JSON
audit_log_policy = ALL          # or LOGINS, QUERIES depending on volume
audit_log_file = /var/log/mysql/audit.log
```

MariaDB:
```ini
[mysqld]
plugin-load-add = server_audit
server_audit_events = CONNECT,QUERY_DDL,QUERY_DML,TABLE
server_audit_logging = ON
server_audit_file_path = /var/log/mysql/server_audit.log
```

- Plugin-free alternative: slow query log plus `general_log` only temporarily
  and carefully (it leaks data).
- Redact and rotate logs; ship them off-host.

## 6. Backups

- `XtraBackup`/`mariabackup` for physical backups with binlogs for PITR.
- `mysqldump --single-transaction --routines --triggers --events` for logical.
- Encrypt (`--encrypt` in XtraBackup or GPG), verify by restoring, measure RTO.
- Never leave dumps with `DEFINER` for deleted accounts or plaintext passwords.

## 7. Audit queries

```sql
SELECT VERSION();
SHOW VARIABLES WHERE Variable_name IN
 ('bind_address','require_secure_transport','have_ssl','tls_version',
  'local_infile','secure_file_priv','skip_name_resolve','log_bin',
  'validate_password.policy','audit_log_policy');

SELECT user, host, plugin FROM mysql.user ORDER BY user, host;
SELECT user, host FROM mysql.user
 WHERE authentication_string IS NULL OR authentication_string = '';
SELECT user, host FROM mysql.user WHERE user = '';

SELECT grantee, privilege_type FROM information_schema.user_privileges
 ORDER BY grantee, privilege_type;

SELECT table_schema, table_name, table_rows,
       ROUND((data_length+index_length)/1024/1024,1) AS mb
FROM information_schema.tables
ORDER BY data_length DESC LIMIT 20;

SHOW PROCESSLIST;
SHOW REPLICA STATUS;   -- MySQL 8.0.22+; MariaDB: SHOW SLAVE STATUS
SELECT * FROM performance_schema.events_statements_summary_by_digest
 ORDER BY SUM_TIMER_WAIT DESC LIMIT 20;
```

## 8. Engine-specific risks

- `skip-grant-tables` in production: anyone gets in without a password. If used
  for recovery, do it on an isolated instance and revert immediately.
- `CREATE USER ... IDENTIFIED BY ''` or passwordless users on host `%`.
- `GRANT ALL ON *.* TO 'app'@'%'` is full instance compromise.
- `DEFINER` views with elevated privileges can escalate rights. Review
  `information_schema.views` and `SHOW CREATE VIEW`.
- Triggers and `EVENT` objects with a superuser `DEFINER`.
- MariaDB `unix_socket` for `root` is good local practice but blocks remote
  login: verify administration goes through SSH or VPN.
