#!/usr/bin/env bash
# Read-only web security header/TLS/CORS triage. GET/HEAD/OPTIONS only.
# Only run against systems you own or are authorized to assess.
#
# Usage: web-headers-audit.sh --authorized https://app.example.com/path

set -euo pipefail

if [[ "${1:-}" != "--authorized" || -z "${2:-}" ]]; then
  cat >&2 <<'EOF'
Usage: web-headers-audit.sh --authorized https://app.example.com/path

Sends GET/HEAD/OPTIONS requests and prints security headers, cookie flags,
CORS behavior and TLS acceptance. Changes nothing. The --authorized flag is a
deliberate confirmation that you are allowed to test the target.
EOF
  exit 2
fi

URL="$2"
if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

CURL=(curl -sS --max-time 15 -A "appsec-web-audit/1.0")
hdr() { "${CURL[@]}" -D - -o /dev/null "$@" | tr -d '\r'; }

printf '# Target: %s\n# Read-only: GET/HEAD/OPTIONS only.\n' "$URL"

echo
echo "### Response headers"
HDR="$(hdr "$URL")"
printf '%s\n' "$HDR" | head -n 1
printf '%s\n' "$HDR" | grep -iE '^(strict-transport-security|content-security-policy|content-security-policy-report-only|x-content-type-options|x-frame-options|referrer-policy|permissions-policy|cross-origin-opener-policy|cross-origin-resource-policy|cross-origin-embedder-policy|set-cookie|server|x-powered-by|access-control-allow-origin|access-control-allow-credentials):' \
  || echo "(none of the expected headers present)"

echo
echo "### Baseline headers"
for h in strict-transport-security content-security-policy x-content-type-options \
         referrer-policy permissions-policy; do
  if printf '%s\n' "$HDR" | grep -qi "^${h}:"; then
    echo "ok   $h"
  else
    echo "MISS $h"
  fi
done

echo
echo "### Cookie flags"
COOKIES="$(printf '%s\n' "$HDR" | grep -i '^set-cookie:' || true)"
if [[ -z "$COOKIES" ]]; then
  echo "(no Set-Cookie on this response)"
else
  while IFS= read -r line; do
    name="$(printf '%s' "$line" | sed -E 's/^[Ss]et-[Cc]ookie:[[:space:]]*([^=]+)=.*/\1/')"
    missing=""
    printf '%s' "$line" | grep -qi ';[[:space:]]*httponly' || missing="$missing HttpOnly"
    printf '%s' "$line" | grep -qi ';[[:space:]]*secure'   || missing="$missing Secure"
    printf '%s' "$line" | grep -qi ';[[:space:]]*samesite' || missing="$missing SameSite"
    if [[ -z "$missing" ]]; then
      echo "ok   $name"
    else
      echo "WEAK $name -> missing:$missing"
    fi
  done <<< "$COOKIES"
fi

echo
echo "### CORS with foreign Origin"
CORS="$(hdr -H 'Origin: https://evil.example' "$URL")"
if printf '%s\n' "$CORS" | grep -qiE '^(access-control-allow-origin|access-control-allow-credentials):'; then
  printf '%s\n' "$CORS" | grep -iE '^(access-control-allow-origin|access-control-allow-credentials):'
  if printf '%s\n' "$CORS" | grep -qi '^access-control-allow-origin:[[:space:]]*\*'; then
    echo "CHECK wildcard ACAO; critical if combined with credentials"
  fi
else
  echo "no CORS headers (good default)"
fi

echo
echo "### TLS"
"${CURL[@]}" -o /dev/null -w 'request ok: HTTP %{http_version}, verify result %{ssl_verify_result}\n' "$URL" 2>/dev/null \
  || echo "request failed (DNS, connection or certificate)"
for v in tlsv1.0 tlsv1.1; do
  if "${CURL[@]}" --"$v" -o /dev/null "$URL" 2>/dev/null; then
    echo "WEAK accepted: $v"
  else
    echo "ok   rejected: $v"
  fi
done
for v in tlsv1.2 tlsv1.3; do
  if "${CURL[@]}" --"$v" -o /dev/null "$URL" 2>/dev/null; then
    echo "ok   accepted: $v"
  else
    echo "note rejected: $v (client or server limitation)"
  fi
done

if [[ "$URL" == https://* ]]; then
  HTTP_URL="http://${URL#https://}"
  echo
  echo "### HTTP to HTTPS"
  "${CURL[@]}" -o /dev/null -w 'status %{http_code} -> %{redirect_url}\n' "$HTTP_URL" 2>/dev/null \
    || echo "no HTTP listener or connection failed"
fi

echo
echo "### OPTIONS"
"${CURL[@]}" -X OPTIONS -o /dev/null -D - "$URL" 2>/dev/null | tr -d '\r' \
  | grep -iE '^(allow|access-control-allow-methods):' || echo "no Allow header"

echo
echo "# Done. Verify findings in context; headers at the edge and origin can differ."
