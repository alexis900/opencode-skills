#!/usr/bin/env bash
# Read-only pattern triage for a source repository. Candidates, not verdicts.
#
# Usage: repo-appsec-scan.sh /path/to/repo
#
# Prints file:line matches for high-signal risky constructs and secret shapes.
# It does not modify files, run code or contact the network.

set -euo pipefail

if [[ -z "${1:-}" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: repo-appsec-scan.sh /path/to/repo

Scans source files for high-signal application security patterns:
secrets, dangerous sinks, TLS verification disabled, weak randomness and
permissive CORS. Results are candidates that need manual review; there are
false positives and the absence of matches is not proof of safety.
EOF
  exit 0
fi

ROOT="$1"
if [[ ! -d "$ROOT" ]]; then
  echo "not a directory: $ROOT" >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  SEARCH=(rg -n --no-heading --color never -S
    -g '*.{ts,tsx,js,jsx,mjs,cjs,py,go,java,kt,rb,php,cs,rs,scala,swift}'
    -g '!node_modules' -g '!vendor' -g '!dist' -g '!build' -g '!.git')
else
  SEARCH=(grep -rnIE --exclude-dir=node_modules --exclude-dir=vendor
    --exclude-dir=dist --exclude-dir=build --exclude-dir=.git
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx'
    --include='*.py' --include='*.go' --include='*.java' --include='*.rb'
    --include='*.php' --include='*.cs' --include='*.rs')
fi

section() {
  local title="$1" pattern="$2" out
  printf '\n### %s\n' "$title"
  out="$("${SEARCH[@]}" -e "$pattern" "$ROOT" 2>/dev/null | head -n 40 || true)"
  if [[ -z "$out" ]]; then
    echo "(no matches)"
  else
    printf '%s\n' "$out"
  fi
}

printf '# AppSec pattern triage\n# root: %s\n# engine: %s\n# Read-only.\n' \
  "$ROOT" "${SEARCH[0]}"

section "Secret-like assignments" \
  '(password|passwd|secret|api[_-]?key|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}'
section "Cloud and provider keys" \
  'AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'
section "Dynamic code execution" \
  'eval\(|new Function\('
section "HTML injection sinks" \
  'dangerouslySetInnerHTML|innerHTML[[:space:]]*='
section "Shell and process execution" \
  'exec\(|os\.system|subprocess\.(call|run|Popen)|child_process'
section "Unsafe deserialization" \
  'pickle\.loads|yaml\.load\(|Marshal\.load'
section "TLS verification disabled" \
  'verify[[:space:]]*=[[:space:]]*False|rejectUnauthorized:[[:space:]]*false|InsecureSkipVerify'
section "JWT decoded without verification" \
  'jwt\.decode\('
section "Permissive CORS" \
  'Access-Control-Allow-Origin[^,;]*\*'
section "Tokens in browser storage" \
  'localStorage\.(setItem|getItem)'
section "Weak hashing" \
  'md5\(|sha1\('
section "Non-cryptographic randomness" \
  'Math\.random\(\)'
section "SQL built with interpolation" \
  '`[^`]*(SELECT|INSERT|UPDATE|DELETE)[^`]*\$\{'

printf '\n# Done. Triage each hit in context; do not report a finding without a path.\n'
