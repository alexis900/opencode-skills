#!/usr/bin/env bash
# Read-only PostgreSQL security audit. Changes nothing.
#
# Connection: standard libpq environment variables (PGHOST, PGPORT, PGUSER,
# PGDATABASE) or a ~/.pgpass file. Never pass a password on the command line.
#
# Usage: pg-audit.sh [--help]

set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "psql not found in PATH" >&2
  exit 1
fi

export PGAPPNAME="dba-audit"
PSQL=(psql -X -q -A -F '|' -v ON_ERROR_STOP=1)

run() {
  local title="$1" sql="$2"
  printf '\n### %s\n' "$title"
  if ! "${PSQL[@]}" -c "$sql" 2>/dev/null; then
    printf '[!] not permitted with the current role, or unsupported in this version\n'
  fi
}

printf '# PostgreSQL security audit\n'
printf '# host=%s port=%s user=%s db=%s\n' \
  "${PGHOST:-socket}" "${PGPORT:-5432}" "${PGUSER:-$USER}" "${PGDATABASE:-$USER}"
printf '# Read-only: no data or configuration is modified.\n'

run "version" "SELECT version();"

run "key settings" "SELECT name, setting, unit, source FROM pg_settings
WHERE name IN ('listen_addresses','port','ssl','ssl_min_protocol_version',
  'ssl_ciphers','password_encryption','log_connections','log_disconnections',
  'log_statement','log_min_duration_statement','archive_mode','fsync',
  'statement_timeout','idle_in_transaction_session_timeout','lock_timeout',
  'superuser_reserved_connections','max_connections')
ORDER BY name;"

run "superusers" "SELECT rolname, rolcanlogin, rolvaliduntil
FROM pg_roles WHERE rolsuper ORDER BY 1;"

run "login roles without password" "SELECT rolname FROM pg_authid
WHERE rolcanlogin AND rolpassword IS NULL ORDER BY 1;"

run "role memberships" "SELECT r.rolname AS role, m.rolname AS member, am.admin_option
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
ORDER BY 1, 2;"

run "pg_hba rules" "SELECT line_number, type, database, user_name, address,
  auth_method, error FROM pg_hba_file_rules ORDER BY line_number;"

run "schemas where PUBLIC can create" "SELECT nspname
FROM pg_namespace
WHERE nspname NOT LIKE 'pg_%' AND nspname <> 'information_schema'
  AND has_schema_privilege('public', nspname, 'CREATE')
ORDER BY 1;"

run "database ACLs" "SELECT datname, datacl FROM pg_database ORDER BY 1;"

run "installed extensions" "SELECT extname, extversion FROM pg_extension ORDER BY 1;"

run "database sizes (MB)" "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database ORDER BY pg_database_size(datname) DESC;"

run "sessions by user and state" "SELECT usename, state, count(*) AS sessions,
  count(*) FILTER (WHERE client_addr IS NOT NULL) AS tcp
FROM pg_stat_activity
WHERE backend_type = 'client backend'
GROUP BY usename, state ORDER BY sessions DESC;"

run "idle in transaction over 5 minutes" "SELECT pid, usename, client_addr,
  now() - state_change AS idle_for
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - state_change > interval '5 minutes'
ORDER BY idle_for DESC;"

run "replication" "SELECT client_addr, state, sync_state, sent_lsn, replay_lsn
FROM pg_stat_replication ORDER BY client_addr;"

run "WAL archiver" "SELECT archived_count, failed_count, last_archived_time,
  last_failed_time FROM pg_stat_archiver;"

run "tables without primary key" "SELECT n.nspname AS schema, c.relname AS table
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog','information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_constraint p
    WHERE p.conrelid = c.oid AND p.contype = 'p')
ORDER BY 1, 2 LIMIT 50;"

printf '\n# Done. Review each section and keep the output with timestamp and role used.\n'
