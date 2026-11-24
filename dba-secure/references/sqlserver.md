# SQL Server: hardening and audit

Reference versions: 2019 and 2022, on-premises and Azure SQL Managed Instance.
Prefer Windows/Entra authentication; treat SQL logins as the exception.

## 1. Authentication and surface area

- Disable the `sa` account or set a long random password and keep it disabled:
  `ALTER LOGIN [sa] DISABLE;`
- Prefer Windows/Entra authentication; if mixed mode is required, document why
  and enforce password policy on SQL logins.
- Remove the `BUILTIN\Administrators` login if present; administrators should
  connect through a dedicated DBA group.
- Disable unused protocols and services: Named Pipes/BACP if unused, SQL Browser
  unless required, `xp_cmdshell`, `Ole Automation`, `Agent XPs` where not used.

```sql
-- Surface area
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 0; RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 0; RECONFIGURE;
EXEC sp_configure 'clr enabled', 0; RECONFIGURE;   -- enable only if needed
```

- Review `sys.configurations` for every value you did not expect.
- `clr strict security` stays on. Signed assemblies only.

## 2. Network and TLS

- Force encryption on the instance and use a valid certificate, not the
  self-signed one for production.
- Restrict the port to application and administration subnets; no public
  endpoints. Azure: private endpoint, no public network access.
- Disable TLS 1.0/1.1 at the OS level as well (`Schannel` registry or Linux
  `openssl.cnf`), not only in SQL Server.
- Verify: `SELECT session_id, encrypt_option FROM sys.dm_exec_connections;`

## 3. Logins, roles and permissions

```sql
-- Logins with sysadmin or control
SELECT p.name, p.type_desc, p.is_disabled
FROM sys.server_principals p
JOIN sys.server_role_members rm ON rm.member_principal_id = p.principal_id
JOIN sys.server_principals r ON r.principal_id = rm.role_principal_id
WHERE r.name = 'sysadmin';

SELECT pr.name AS grantee, pe.permission_name, pe.state_desc
FROM sys.server_permissions pe
JOIN sys.server_principals pr ON pr.principal_id = pe.grantee_principal_id
WHERE pe.permission_name IN ('CONTROL SERVER','ALTER ANY LOGIN','IMPERSONATE ANY LOGIN');

-- SQL logins with weak policy
SELECT name, is_policy_checked, is_expiration_checked, is_disabled
FROM sys.sql_logins;

-- Orphaned users
SELECT dp.name, dp.type_desc FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON sp.sid = dp.sid
WHERE dp.type IN ('S','U','G') AND sp.sid IS NULL;
```

- Application uses a database role with `SELECT/INSERT/UPDATE/DELETE/EXECUTE`
  only; no `db_owner`, no `db_datawriter` at server scope.
- `guest` disabled in user databases; `public` holds no data permissions.
- Review `sys.database_permissions` and `sys.database_role_members` per database.
- Contained databases: if used, `ALTER DATABASE ... SET CONTAINMENT = PARTIAL`
  must be a deliberate decision. `TRUSTWORTHY ON` must be off.

## 4. Data protection

- TDE for data at rest, with certificate/key backup to a KMS or HSM. Losing the
  key loses the database.
- Always Encrypted or Dynamic Data Masking for sensitive columns; masking is
  not encryption and does not stop a privileged reader.
- Row-Level Security for tenant isolation:
  `CREATE SECURITY POLICY ... ADD FILTER PREDICATE ... WITH (STATE = ON);`
- Backup encryption: `BACKUP DATABASE ... WITH ENCRYPTION (ALGORITHM = AES_256,
  SERVER CERTIFICATE = BackupCert);`
- Column-level `GRANT`/`DENY` and views for least-data exposure.

## 5. Auditing

```sql
-- Server audit to a file or security log
CREATE SERVER AUDIT dba_audit TO FILE (FILEPATH = '/var/opt/mssql/audit/');
ALTER SERVER AUDIT dba_audit WITH (STATE = ON);

CREATE SERVER AUDIT SPECIFICATION dba_audit_spec
FOR SERVER AUDIT dba_audit
ADD (FAILED_LOGIN_GROUP), ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP), ADD (DATABASE_PERMISSION_CHANGE_GROUP);
ALTER SERVER AUDIT SPECIFICATION dba_audit_spec WITH (STATE = ON);
```

- Database-level audit specs for `SELECT` on sensitive tables and for
  `DATABASE_OBJECT_CHANGE_GROUP`.
- Ship audit files off-host and restrict file access; local admins can tamper.
- Extended Events for performance plus security telemetry (deadlocks, errors).
- Alert on `18456` (login failed) spikes, `sysadmin` changes and backup failures.

## 6. Backups and recovery

- Full + differential + transaction log backups; `RECOVERY FULL` and log chain
  integrity verified with `RESTORE VERIFYONLY`.
- Test restores including point-in-time, and measure RTO/RPO.
- Backups encrypted, off-host, with retention and immutability where possible.
- Check `msdb.dbo.backupset` for the last successful backup per database, and
  `sys.dm_database_backups` / `msdb` history for failures.
- `CHECKDB` with `DATA_PURITY` on a schedule; corruption is an availability
  incident, not a cosmetic one.

## 7. Audit queries

```sql
SELECT @@VERSION;
SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') AS windows_only_auth;
SELECT name, value_in_use FROM sys.configurations ORDER BY name;
SELECT * FROM sys.dm_exec_connections WHERE encrypt_option <> 'TRUE';
SELECT name, is_disabled FROM sys.server_principals WHERE type IN ('S','U','G');
SELECT name, is_policy_checked, is_expiration_checked FROM sys.sql_logins;
SELECT database_id, name, state_desc, recovery_model_desc, is_trustworthy_on
FROM sys.databases;
SELECT * FROM sys.server_audits;
```

## 8. Risks specific to SQL Server

- `xp_cmdshell` enabled: OS command execution from SQL.
- `TRUSTWORTHY ON` plus `db_owner` impersonation paths.
- `IMPERSONATE` granted widely.
- Linked servers with `sa` or a sysadmin mapping.
- Jobs (`msdb.dbo.sysjobs`) running as sysadmin with weak script permissions.
- `sa` enabled with a blank/weak password.
- Backup files readable by OS users or on a share without ACLs.
