#!/usr/bin/env bash
# Read-only MySQL/MariaDB security audit. Changes nothing.
#
# Connection: a client option file with 600 permissions, default ~/.my.cnf.
# Override with MYSQL_DEFAULTS_FILE=/path/to/file. Never put a password in the
# command line or in shell history.
#
# Usage: mysql-audit.sh [--help]

set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

if ! command -v mysql >/dev/null 2>&1; then
  echo "mysql client not found in PATH" >&2
  exit 1
fi

CNF="${MYSQL_DEFAULTS_FILE:-$HOME/.my.cnf}"
if [[ ! -r "$CNF" ]]; then
  echo "No readable client option file at $CNF." >&2
  echo "Create it with chmod 600 and [client] user/password/host, or set MYSQL_DEFAULTS_FILE." >&2
  exit 1
fi

MYSQL=(mysql --defaults-file="$CNF" --batch --raw --connect-timeout=10)

run() {
  local title="$1" sql="$2"
  printf '\n### %s\n' "$title"
  if ! "${MYSQL[@]}" -e "$sql" 2>/dev/null; then
    printf '[!] not permitted with the current account, or unsupported in this version\n'
  fi
}

printf '# MySQL/MariaDB security audit\n# client config: %s\n# Read-only: no changes.\n' "$CNF"

run "version" "SELECT VERSION() AS version, @@version_comment AS comment;"

run "network and TLS" "SHOW VARIABLES WHERE Variable_name IN
 ('bind_address','port','skip_networking','require_secure_transport','have_ssl',
  'tls_version','ssl_ca','ssl_cert','skip_name_resolve');"

run "authentication and safety" "SHOW VARIABLES WHERE Variable_name IN
 ('local_infile','secure_file_priv','skip_symbolic_links','sql_mode',
  'log_bin','log_bin_trust_function_creators','validate_password.policy',
  'audit_log_policy','server_audit_logging','max_connections','wait_timeout');"

run "accounts" "SELECT user, host, plugin FROM mysql.user ORDER BY user, host;"

run "accounts without password" "SELECT user, host FROM mysql.user
WHERE authentication_string IS NULL OR authentication_string = '';"

run "anonymous accounts" "SELECT user, host FROM mysql.user WHERE user = '';"

run "remote wildcard accounts" "SELECT user, host FROM mysql.user
WHERE host IN ('%','0.0.0.0/0','::/0') ORDER BY user, host;"

run "global privileges" "SELECT grantee, privilege_type
FROM information_schema.user_privileges
WHERE privilege_type IN ('SUPER','FILE','PROCESS','SHUTDOWN','CREATE USER',
  'RELOAD','REPLICATION SLAVE','GRANT OPTION','SYSTEM_VARIABLES_ADMIN')
ORDER BY grantee, privilege_type;"

run "database-level grants" "SELECT user, host, db FROM mysql.db
ORDER BY user, host, db;"

run "databases and sizes (MB)" "SELECT table_schema AS db,
  ROUND(SUM(data_length+index_length)/1024/1024,1) AS mb
FROM information_schema.tables
GROUP BY table_schema ORDER BY SUM(data_length+index_length) DESC;"

run "sessions" "SELECT user, host, db, command, time, state
FROM information_schema.processlist ORDER BY time DESC;"

run "replication" "SHOW REPLICA STATUS;"

printf '\n# Done. MariaDB users: replace SHOW REPLICA STATUS with SHOW SLAVE STATUS if needed.\n'
