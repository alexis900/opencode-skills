# PostgreSQL: hardening and audit

Goal: no unnecessary exposure, separated identities, `scram-sha-256`, TLS, RLS
where needed, useful auditing and tested recovery. Reference versions: 15, 16
and 17.

## 1. Network exposure

```conf
# postgresql.conf
listen_addresses = '10.0.0.10'      # never '*'
port = 5432
ssl = on
ssl_min_protocol_version = 'TLSv1.2'  # TLSv1.3 if clients support it
ssl_ciphers = 'HIGH:!aNULL:!MD5'
password_encryption = 'scram-sha-256'
```

- The port must only be reachable from the application and administration
  networks. Verify with `ss -ltnp` and an authorized scan from another network.
- Do not run everything through `pgbouncer` in `session` mode: use
  `transaction` and cap `max_client_conn`. A pooler replaces neither
  authentication nor TLS.
- Replicas: TLS between nodes too; the replica's `pg_hba` restricts to the
  primary's IP.

## 2. Authentication (`pg_hba.conf`)

```conf
# TYPE  DATABASE  USER      ADDRESS        METHOD
local   all       postgres                 peer
hostssl all       app_rw    10.0.1.0/24    scram-sha-256
hostssl all       app_ro    10.0.1.0/24    scram-sha-256
hostssl replication repl    10.0.2.0/24    scram-sha-256
hostnossl all     all       0.0.0.0/0      reject
```

- Explicitly reject `hostnossl`; do not rely on `ssl=on` alone.
- `trust`, cleartext `password` and `md5` are forbidden where migration is
  feasible.
- `md5` to `scram-sha-256` migration: set
  `password_encryption = scram-sha-256`, force a password change for every role,
  then remove the `md5` lines from `pg_hba.conf`.
- `pg_hba.conf` is the real ingress control: review it on every network change.
- Verify with `SELECT * FROM pg_hba_file_rules;` (superuser required) and
  `SELECT pg_reload_conf();` after editing.

## 3. Roles and privileges

```sql
-- Application role: no superuser login, no CREATEDB/CREATEROLE
CREATE ROLE app_rw LOGIN PASSWORD :'pw' NOSUPERUSER NOCREATEDB NOCREATEROLE
  NOINHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT 50
  VALID UNTIL '2027-01-01';

GRANT CONNECT ON DATABASE appdb TO app_rw;
GRANT USAGE ON SCHEMA app TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO app_rw;
ALTER DEFAULT PRIVILEGES IN SCHEMA app
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_rw;

-- Nobody creates objects in public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE appdb FROM PUBLIC;
```

- Separate `app_rw`, `app_ro`, `migrator` (DDL) and `dba`. The application does
  not run DDL.
- `migrator` is only used from the pipeline with ephemeral credentials.
- Audit memberships: `SELECT r.rolname AS role, m.rolname AS member, am.admin_option
  FROM pg_auth_members am JOIN pg_roles r ON r.oid = am.roleid
  JOIN pg_roles m ON m.oid = am.member ORDER BY 1,2;`
- Login roles without a password: `SELECT rolname FROM pg_authid
  WHERE rolcanlogin AND rolpassword IS NULL;` (superuser).
- Check `rolvaliduntil`, `rolconnlimit` and orphaned accounts after offboarding.

## 4. Row Level Security (multi-tenant)

```sql
ALTER TABLE app.document ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.document FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON app.document
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::uuid);
```

- `FORCE` prevents the table owner from bypassing the policy.
- `tenant_id` is set inside the transaction:
  `SET LOCAL app.tenant_id = '...'` from the backend, **never** from an
  unvalidated client parameter.
- Mandatory negative test: tenant A can neither read nor write tenant B.

## 5. Encryption

- In transit: TLS with valid certificates; renew before expiry.
- At rest: volume encryption (LUKS, EBS, KMS) or `pgcrypto` for specific
  columns. `pgcrypto` does not encrypt indexes or support `LIKE`; plan searches.
- Secrets: `password_encryption = scram-sha-256`. Never put plaintext
  `ALTER ROLE ... PASSWORD 'text'` in versioned scripts.

## 6. Auditing and logs

```conf
logging_collector = on
log_connections = on
log_disconnections = on
log_checkpoints = on
log_lock_waits = on
log_min_duration_statement = 1000
log_statement = 'ddl'
log_line_prefix = '%m [%p] %q%u@%d/%a '
log_error_verbosity = default
```

- `pgaudit` to audit DDL, writes and reads of sensitive data:
  `shared_preload_libraries = 'pgaudit'` and
  `pgaudit.log = 'ddl, role, write'` (add `read` only for critical tables).
- Redact: do not log parameters containing PII. Use views/roles that limit
  sensitive columns.
- Retain and ship to an external immutable collector; local logs can be wiped
  after a compromise.
- Treat `log_statement = 'all'` in production as a finding: noisy and it leaks
  data.

## 7. Backups and recovery

- `pg_basebackup` plus continuous WAL archiving (`archive_mode = on`) for PITR.
- Encrypt backups (GPG/KMS), store off-host with defined retention. Restore in
  an isolated environment and measure RTO.
- `pg_dump` for portability, never as the only strategy.
- Check `pg_stat_archiver`: `failed_count` must be 0.

## 8. Useful audit queries

```sql
SELECT version();
SHOW ssl; SHOW ssl_min_protocol_version; SHOW password_encryption;

SELECT name, setting, source FROM pg_settings
WHERE name IN ('listen_addresses','ssl','password_encryption','log_connections',
               'log_statement','log_min_duration_statement','archive_mode');

SELECT rolname FROM pg_roles WHERE rolsuper ORDER BY 1;

SELECT n.nspname, has_schema_privilege('public', n.nspname, 'CREATE') AS public_can_create
FROM pg_namespace n WHERE n.nspname NOT LIKE 'pg_%';

SELECT datname, datacl FROM pg_database ORDER BY 1;
SELECT extname, extversion FROM pg_extension ORDER BY 1;

SELECT pid, usename, application_name, client_addr, state,
       now() - backend_start AS age
FROM pg_stat_activity WHERE backend_type = 'client backend';

SELECT * FROM pg_stat_replication;
SELECT slot_name, active, restart_lsn FROM pg_replication_slots;
```

## 9. Containment settings

```conf
statement_timeout = '30s'            -- tune per workload
idle_in_transaction_session_timeout = '60s'
lock_timeout = '10s'
max_connections = 200                -- with a pooler in front
```

- Without timeouts, one stuck query or transaction can exhaust the service.
- `superuser_reserved_connections` leaves the DBA headroom.
- Cap per-session `work_mem` to avoid OOM under concurrency.

## 10. Vulnerabilities and patching

- Keep the engine current; track security advisories for PostgreSQL and every
  extension (PostGIS, pg_partman, pgcrypto, etc.).
- Extensions only from system packages or signed sources; review
  `shared_preload_libraries` on every change.
- Deny `plpython`/`plperlu` to non-admin roles unless required.
- `COPY ... FROM PROGRAM` and `lo_import` are superuser-only: never grant
  superuser to the application.
