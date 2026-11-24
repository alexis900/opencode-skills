# Secure operations: backups, network, secrets and incidents

Applies to every engine. These are the controls that keep a hardened database
from becoming an unhardened one after the first incident or release.

## 1. Network and exposure

- Database subnets are private. Public ingress is a finding, not a design.
- Three planes: application, replication and administration. Separate subnets,
  security groups and credentials where possible.
- Administration through a bastion/VPN/zero-trust proxy with MFA, never a
  direct public port.
- Egress restrictions too: a compromised database must not reach the internet.
- Default deny firewall rules, then allow by source IP and port. Review after
  every topology change.
- Private endpoints for managed services; disable public network access
  explicitly and verify from outside the VPC.

## 2. Identity and secrets

- One credential per application and environment. No shared DBA accounts.
- Secrets in a manager (Vault, AWS/GCP/Azure secret manager, KMS) or injected
  at runtime. Never in repos, images, CI variables, logs or tickets.
- Rotation process defined and tested: create new, deploy, revoke old, verify.
  Short-lived credentials from IAM where supported.
- Human access through SSO with MFA and just-in-time elevation; break-glass
  account sealed, audited and rotated after use.
- Service accounts have owners and expiry; orphaned accounts are removed.

## 3. Backups and restore verification

| Control | Requirement |
| --- | --- |
| Scope | Full instance plus PITR logs/WAL/binlog/oplog |
| Encryption | At rest with KMS/HSM-managed keys, keys backed up separately |
| Isolation | Off-host, separate account/project, immutability where possible |
| Retention | Defined by policy and tested deletion |
| Restore test | At least quarterly, timed, into an isolated environment |
| Integrity | Checksums/`RESTORE VERIFYONLY`/restore logs reviewed |
| Access | Restore requires a privileged, audited role |

- Record RPO/RTO and compare with business requirements; publish the gap.
- Backups are a data copy: apply the same access and encryption rules as
  production.
- Test the restore of the **keys** too. An encrypted backup with a lost key is
  unrecoverable.
- Never restore production data into staging without masking.

## 4. Patching and supply chain

- Track engine, driver, ORM, extension and backup-tool CVEs. Critical remote
  issues get an emergency window.
- Read release notes for security-relevant changes before upgrading.
- Extension modules only from official repos or vendored, signed artifacts.
  Review `shared_preload_libraries`, `plugin-load-add`, CLR assemblies, custom
  MongoDB roles and SQL Server assemblies.
- Drivers pinned and updated; no floating `latest` in production.
- Build images from minimal bases, no DB client tools on application hosts
  unless needed.

## 5. Monitoring and detection

Alert at minimum on:
- Authentication failures by account and source IP; spikes and new geographies.
- New superuser/sysadmin/root grants, role membership changes, `GRANT`/`REVOKE`.
- DDL in production outside the migration window.
- Backup failures, missed schedules, WAL/binlog/oplog gaps, replica lag.
- Connections from unexpected networks or unusual clients.
- Data volume anomalies, mass `DELETE`/`DROP`, unusual `COPY`/`SELECT INTO`.
- Configuration drift from the approved baseline.

Baseline and diff configuration; treat manual changes as incidents until proven
otherwise. Keep an inventory with owners and versions.

## 6. Audit evidence and read-only assessment

- Use a dedicated read-only audit role. Do not run assessments as superuser
  unless a check requires it, and document when it does.
- Run scripts with `-X`/`--no-defaults`-style flags where available so local
  client config cannot inject commands.
- Capture output to a file with timestamp, engine version, host and role used.
- Redact hostnames, IPs, usernames and data values before sharing externally;
  keep the raw evidence in the restricted case folder.
- Never paste production data into tickets or chat. Use counts and samples with
  masked values.
- Preserve logs and snapshots before remediation during a suspected incident.

## 7. Incident response runbook

1. **Declare and scope.** Who, what, since when, which systems, what data.
2. **Preserve.** Snapshot volumes, export logs to immutable storage, record
   current sessions and configuration.
3. **Contain.** Revoke credentials/sessions, remove network paths, disable
   compromised accounts, block attacker IPs at the firewall. Prefer
   containment over a rushed cleanup.
4. **Eradicate.** Patch the entry point, remove persistence (triggers, jobs,
   users, extension hooks, scheduled events, startup procedures), rotate every
   secret that touched the host.
5. **Recover.** Restore from a verified clean backup; validate integrity and
   application behavior; monitor closely.
6. **Notify.** Follow legal/regulatory timelines for personal data breaches.
7. **Postmortem.** Timeline, root cause, control gaps, actions with owners and
   dates. Add a regression test for the failed control.

Do not delete evidence, do not "fix forward" on a compromised host without
preserving state, and do not reuse credentials that may have been exposed.

## 8. Change management

- Every change has an owner, ticket, window, verification and rollback.
- Destructive statements (`DROP`, `TRUNCATE`, mass `UPDATE`/`DELETE`, role
  changes) require review and, where possible, a transaction or backup first.
- Migrations run with a dedicated role from the pipeline, never by hand with a
  superuser.
- Configuration changes go through IaC or a reviewed runbook; drift is detected
  and corrected.
