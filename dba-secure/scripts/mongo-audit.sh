#!/usr/bin/env bash
# Read-only MongoDB security audit. Changes nothing.
#
# Connection: pass a URI with a read-only audit user via MONGO_URI, including
# TLS options where required. Avoid typing passwords in shell history; prefer
# a mongosh config or an environment variable read by your shell profile.
#
# Usage: MONGO_URI='mongodb://audit@host:27017/?authSource=admin&tls=true' mongo-audit.sh

set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

if ! command -v mongosh >/dev/null 2>&1; then
  echo "mongosh not found in PATH" >&2
  exit 1
fi

if [[ -z "${MONGO_URI:-}" ]]; then
  echo "Set MONGO_URI to a read-only audit connection string." >&2
  exit 1
fi

JS="$(cat <<'EOF'
function section(title, fn) {
  print("\n### " + title);
  try { printjson(fn()); }
  catch (e) { print("[!] " + e.message); }
}

print("# MongoDB security audit\n# Read-only: no changes.");

section("version and build", () => db.version());
section("authentication mechanisms",
  () => db.adminCommand({ getParameter: 1, authenticationMechanisms: 1 }));
section("command line options",
  () => db.adminCommand({ getCmdLineOpts: 1 }).parsed);
section("security configuration",
  () => db.adminCommand({ serverStatus: 1 }).security);
section("current connection",
  () => db.getSiblingDB("admin").runCommand({ connectionStatus: 1, showPrivileges: true }));
section("users",
  () => db.getSiblingDB("admin").system.users
    .find({}, { user: 1, db: 1, roles: 1, _id: 0 }).toArray());
section("privileged roles",
  () => db.getSiblingDB("admin").system.roles.find(
    { roles: { $in: ["root", "dbAdminAnyDatabase", "readWriteAnyDatabase",
                     "clusterAdmin", "userAdminAnyDatabase"] } },
    { role: 1, db: 1, roles: 1, _id: 0 }).toArray());
section("databases", () => db.adminCommand({ listDatabases: 1, nameOnly: true }));
section("collections per database", () => {
  const rows = [];
  db.adminCommand({ listDatabases: 1, nameOnly: true }).databases.forEach(d => {
    const s = db.getSiblingDB(d.name);
    rows.push({ db: d.name, collections: s.getCollectionNames().length });
  });
  return rows;
});
section("replica set", () => rs.status());
section("session count",
  () => db.getSiblingDB("admin").aggregate([
    { $currentOp: { allUsers: true, idleConnections: true } },
    { $count: "sessions" }
  ]).toArray());
section("running operations",
  () => db.getSiblingDB("admin").aggregate([
    { $currentOp: { allUsers: true } },
    { $match: { active: true } },
    { $project: { op: 1, ns: 1, secs_running: 1, client: 1 } }
  ]).toArray());
EOF
)"

printf '# MongoDB security audit\n# Read-only: no data or configuration is modified.\n'
mongosh "$MONGO_URI" --quiet --eval "$JS"
printf '\n# Done. Review TLS mode, authorization, users and replica set health.\n'
