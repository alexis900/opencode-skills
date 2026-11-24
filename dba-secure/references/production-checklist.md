# Production checklist

Prioritized controls with verification. Use it as the backbone of an audit:
mark **Pass / Fail / N/A**, attach evidence, and turn every Fail into a ticket
with an owner and a date. Severity is the default risk when the control is
missing.

## Critical — fix before anything else

| ID | Control | Verification |
| --- | --- | --- |
| C1 | Database port not reachable from the internet | External authorized scan; `ss -ltnp`; cloud security group/NSG review |
| C2 | No passwordless or `trust`/`skip-grant-tables`/`--noauth` access | `pg_hba_file_rules`, `mysql.user`, `sys.sql_logins`, `security.authorization` |
| C3 | No shared or default superuser credential for applications | Role/privilege inventory per engine |
| C4 | Superuser (`postgres`/`root`/`sa`/`root@mongo`) restricted to local admin paths | Login sources, `pg_hba`, `mysql.user` hosts, `bindIp`, `sa` disabled |
| C5 | TLS enforced, not optional | `hostssl`/`require_secure_transport`/Force Encryption/`requireTLS` |
| C6 | Backups encrypted and stored off-host | Backup config, key management, storage bucket ACL |
| C7 | At least one verified restore within the last quarter | Restore report with timestamp and RTO |
| C8 | Engine not on a version with a known remotely exploitable CVE | Version vs vendor advisories, patch date |
| C9 | No production data copy unmasked outside production | Data flow inventory, staging sampling |

## High — fix within the current cycle

| ID | Control | Verification |
| --- | --- | --- |
| H1 | Application roles lack DDL and admin privileges | Grants review, negative test |
| H2 | `PUBLIC` has no write/DDL on application schemas | `has_schema_privilege`, `mysql.db`, `sys.database_permissions` |
| H3 | Authentication audit trail enabled and shipped off-host | `pgaudit`/`audit_log`/SQL Audit/Mongo audit log |
| H4 | Failed logins and privilege changes generate alerts | SIEM rule test |
| H5 | Credentials rotatable and rotated on schedule | Rotation runbook and last rotation date |
| H6 | Secrets not present in repo, image, CI variables or logs | Secret scanning, log sampling |
| H7 | RLS/tenant isolation where multi-tenant | Policy inventory + cross-tenant negative test |
| H8 | Administrative access via MFA-protected path | Bastion/SSO config, break-glass review |
| H9 | Encryption at rest where required by policy | Volume/KMS/TDE configuration |
| H10 | Timeouts and connection limits set | `statement_timeout`, `wait_timeout`, `CONNECTION LIMIT` |

## Medium — plan and schedule

| ID | Control | Verification |
| --- | --- | --- |
| M1 | Password policy enforced for SQL/DB logins | `validate_password`, `is_policy_checked`, Mongo SCRAM policy |
| M2 | Orphaned and dormant accounts removed | Last-login data, HR/offboarding cross-check |
| M3 | Least-data exposure: views/column grants for sensitive data | Schema and grant review |
| M4 | Backup retention and deletion tested | Retention policy vs actual objects |
| M5 | Monitoring covers replication, locks, disk, connections | Dashboard and alert coverage |
| M6 | Data volume and mass-change anomalies detected | Query/log telemetry |
| M7 | Log retention and redaction defined | Log config and sample inspection |
| M8 | Extension/module inventory with provenance | `pg_extension`, plugins, CLR, custom roles |
| M9 | Configuration baselined and drift-detected | IaC or config diff report |
| M10 | Staging and dev use synthetic or masked data | Sampling check |

## Low — hygiene

| ID | Control | Verification |
| --- | --- | --- |
| L1 | Naming and ownership documented per database | Inventory |
| L2 | Runbooks for restore, failover, rotation | Document review |
| L3 | Unused features disabled (`xp_cmdshell`, JS, BACP) | `sys.configurations`, `mongod.conf` |
| L4 | Client tooling version pinned on admin hosts | Package inventory |

## Negative tests to run (must fail)

1. Connect without TLS → rejected.
2. Connect with an expired/self-signed client certificate → rejected.
3. Application role runs `CREATE TABLE`/`DROP TABLE` → denied.
4. Application role reads another tenant's row → denied or empty.
5. Reporting role writes → denied.
6. Login from a non-allowed subnet → blocked at network layer.
7. Login with a revoked credential or after rotation → rejected.
8. Restore attempt with an unauthorized role → denied and audited.
9. Disabled `sa`/`root` remote login → rejected.
10. Oversized or malformed input hits validation before reaching SQL.

## Evidence pack

For each finding: ID, severity, engine/version, exact command and output
(redacted), timestamp, role used, impact, remediation, owner, due date, and
retest result. Keep raw evidence in the restricted case folder, never in chat
or tickets.
