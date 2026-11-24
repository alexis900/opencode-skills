# MongoDB: hardening and audit

Reference versions: 6.0, 7.0 and 8.0, self-hosted and Atlas. Assume a network
attacker can reach the port; authorization and authentication must be enforced.

## 1. Authentication and authorization

```yaml
# /etc/mongod.conf
security:
  authorization: enabled
  keyFile: /etc/mongodb/keyfile        # internal auth between members
  # or x509 for replica sets / sharded clusters
  javascriptEnabled: false             # disable server-side JS unless required
net:
  bindIp: 10.0.0.10
  port: 27017
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/mongodb/server.pem
    CAFile: /etc/mongodb/ca.pem
```

- Never run with `--noauth`, `security.authorization: disabled`, or
  `--bind_ip_all` on an untrusted network.
- `enableLocalhostAuthBypass: false` once initial users exist.
- Use SCRAM-SHA-256 for users (`db.createUser({... mechanisms: ["SCRAM-SHA-256"]})`),
  or x.509/LDAP/Kerberos via `$external` for enterprise directories.
- Internal cluster auth must be enabled: keyfile (minimum) or x.509. An open
  replica set member is a full data exposure path.

## 2. Roles and least privilege

```javascript
use appdb
db.createRole({
  role: "appReadWrite",
  privileges: [{ resource: { db: "appdb", collection: "" },
                 actions: ["find","insert","update","remove"] }],
  roles: []
})
db.createUser({ user: "app_rw", pwd: passwordPrompt(),
                roles: [{ role: "appReadWrite", db: "appdb" }] })
```

- Application users must not have `readWriteAnyDatabase`, `dbAdminAnyDatabase`,
  `root`, `clusterAdmin` or `userAdminAnyDatabase`.
- Grant per database and per collection; `read` for reporting.
- `dbAdmin` on application databases only for the migration pipeline.
- Review: `db.getSiblingDB("admin").system.users.find({}, {user:1, db:1, roles:1})`
  and `db.getSiblingDB("admin").system.roles.find()`.

## 3. Network and TLS

- `bindIp` to private interfaces; firewall the port to app and admin networks.
- `tlsMode: requireTLS` plus `tlsDisabledProtocols: TLS1_0,TLS1_1`.
- Atlas: IP access list, private endpoint, database users with scoped roles.
- No port forwarding, no public load balancer in front of `mongod`.
- Verify cipher/protocol with `mongosh --tls --tlsCAFile ...` and reject weak
  client connections.

## 4. Encryption and data handling

- Encryption at rest: WiredTiger encrypted storage with KMIP/KMS key management.
  Test key rotation and recovery; an unavailable key is an outage.
- Client-Side Field Level Encryption for the most sensitive fields; the server
  never sees plaintext.
- Disable `javascriptEnabled` to remove server-side JS execution paths.
- Restrict `$where`, `mapReduce` and `eval`; reject them at the application layer.

## 5. Auditing and monitoring

- MongoDB Enterprise: `auditLog` with `destination: file|syslog`, filter for
  authentication, authorization failures, role changes, `dropDatabase`,
  `createUser`, `dropUser`.
- Atlas: enable database auditing and ship to your SIEM.
- Community: `slowms` profiling plus `db.setProfilingLevel(1, { slowms: 100 })`,
  and application-level logging. Do not leave profiling level 2 in production.
- Alert on failed authentications, `replSet` membership changes, unusually
  large `deleteMany`/`drop`, and connections from unknown IPs.

```javascript
db.adminCommand({ getParameter: 1, authenticationMechanisms: 1 })
db.adminCommand({ getCmdLineOpts: 1 })
db.adminCommand({ listDatabases: 1 })
db.serverStatus().security
db.getSiblingDB("admin").aggregate([
  { $currentOp: { allUsers: true, idleConnections: true } },
  { $match: { active: true } }
])
```

## 6. Backups and recovery

- `mongodump`/`mongorestore` for logical, filesystem snapshots or
  `mongodump --oplog` for consistent point-in-time on replica sets.
- Atlas: continuous cloud backup with PITR, tested restore.
- Encrypt backups, store off-host, define retention. Test restore in isolation.
- Verify replica set health (`rs.status()`) and that at least one secondary is
  in sync; a single-node set is a backup-free single point of failure.

## 7. Audit queries

```javascript
db.version()
db.adminCommand({ getParameter: 1, authenticationMechanisms: 1 })
db.adminCommand({ serverStatus: 1 }).security
db.getSiblingDB("admin").system.users.find({}, { user: 1, db: 1, roles: 1, _id: 0 })
db.getSiblingDB("admin").system.roles.find({ roles: { $in: ["root", "dbAdminAnyDatabase"] } })
db.adminCommand({ usersInfo: 1 })
db.getSiblingDB("admin").runCommand({ connectionStatus: 1 })
db.getSiblingDB("admin").aggregate([{ $currentOp: { allUsers: true } }])
rs.status()
```

## 8. Risks specific to MongoDB

- Historical default of no authentication: any reachable `mongod` without
  `authorization: enabled` is a full breach.
- `bindIp: 0.0.0.0` with a public IP and no firewall.
- `root` user with a short password, shared across environments.
- Keyfile readable by non-MongoDB users (`chmod 400`, owner `mongod`).
- Profiling level 2 left on: it stores query payloads, including PII.
- `db.eval` or mapReduce with user input: server-side code execution.
- Unencrypted snapshots in object storage with broad bucket policies.
