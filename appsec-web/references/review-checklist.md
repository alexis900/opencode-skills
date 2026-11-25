# Review checklist and negative tests

Mark **Pass / Fail / N/A**, attach evidence (file:line, request/response,
header dump) and turn each Fail into a ticket with severity, owner and date.
ASVS references are indicative, not a certification.

## Critical

| ID | Control | Verification |
| --- | --- | --- |
| C1 | No authentication bypass on any route | Route inventory vs auth middleware; unauthenticated request to every endpoint |
| C2 | Object-level authorization on every ID | Two-user test across read/write/delete/export |
| C3 | Tenant isolation server-side | Cross-tenant read/write/search/export test |
| C4 | No SQL/NoSQL/command injection in reachable paths | Code review of query/shell construction; payload tests |
| C5 | No RCE sink fed by user input | `eval`, `exec`, template compile, deserialization review |
| C6 | Secrets not exposed to client or repo | Bundle scan, env audit, secret scanning |
| C7 | Password reset and MFA flows cannot be bypassed | Token TTL/single-use, replay, enumeration tests |
| C8 | Admin surface protected by policy + stronger auth | Normal-user access test, MFA check |
| C9 | JWT/OAuth validation complete | `alg`, signature, `iss`/`aud`/`exp`, `state`, PKCE, `redirect_uri` |
| C10 | Uploads cannot become executable or traverse paths | Malicious filename/content test, storage location check |

## High

| ID | Control | Verification |
| --- | --- | --- |
| H1 | Output encoding by context; no unsanitized HTML | Stored/reflected XSS tests, sink review |
| H2 | CSRF protection on state changes | Cross-site form/fetch test |
| H3 | CORS exact allowlist, no reflection | `Origin` probe, credentials check |
| H4 | SSRF blocked for user URLs | Internal IP/metadata/redirect tests |
| H5 | Session rotation, revocation, timeouts | Login/privilege/logout tests |
| H6 | Rate limits on auth and expensive routes | Burst test returns 429 |
| H7 | Security headers and HSTS present | Header dump at edge and origin |
| H8 | No mass assignment of privileged fields | Extra-field injection test |
| H9 | Errors and logs free of secrets/PII | Trigger errors, inspect responses/logs |
| H10 | Dependencies free of known critical CVEs | SCA report, lockfile review |

## Medium

| ID | Control | Verification |
| --- | --- | --- |
| M1 | Input size/depth limits and timeouts | Oversized body, deep JSON, slow upstream |
| M2 | Open redirect protection | `next`, `returnTo`, `redirect_uri` payloads |
| M3 | Cache keys isolate tenants and auth | Shared cache inspection |
| M4 | Webhook signature and replay protection | Invalid/old signature test |
| M5 | WebSocket auth per message/subscription | Cross-room and expired-token tests |
| M6 | GraphQL depth/complexity and field auth | Deep query and cross-tenant node test |
| M7 | TLS configuration modern | Protocol/cipher scan |
| M8 | Third-party scripts pinned with SRI | HTML review, CSP report |
| M9 | Account enumeration resistance | Timing/status/body comparison |
| M10 | Logging and alerting cover security events | Denied action produces alert |

## Low

| ID | Control | Verification |
| --- | --- | --- |
| L1 | Framework fingerprint headers removed | Header dump |
| L2 | Unused debug/internal endpoints disabled | Route and port inventory |
| L3 | Security contact and disclosure policy | Published policy |
| L4 | Dependency update cadence defined | CI/Dependabot config |

## Negative tests (must fail)

1. Unauthenticated request to a protected endpoint → 401.
2. User A requests user B's object by ID → 404/403, no data.
3. Tenant A queries tenant B data, including search and export → empty/denied.
4. Read-only role performs write → 403, no state change.
5. Expired/revoked token → 401; reused refresh token → family revoked.
6. `alg: none` or swapped-algorithm JWT → rejected.
7. `Origin: https://evil.example` on a credentialed request → no ACAO header.
8. Cross-site state-changing request without CSRF token → rejected.
9. `file://`, `http://169.254.169.254`, `http://127.0.0.1` as a fetched URL →
   blocked.
10. `<script>` payload in every stored field → rendered inert.
11. `__proto__`/`$ne`/`$where` in JSON body → rejected by schema.
12. 10 MB body / 10k-deep JSON → rejected with 413/400.
13. Upload of `.html`, `.svg` with script, or `../../x` filename → rejected or
    stored inert.
14. Login 100x wrong password → rate limited, no lockout of the real user.

## Evidence template

```text
Finding:      <short title>
Severity:     Critical | High | Medium | Low
CWE / ASVS:   CWE-xxx / Vx.y.z
Where:        path:line, endpoint, config
Evidence:     redacted request/response, header dump, test output
Impact:       what an attacker gains, in plain language
Fix:          structural change + code pointer
Test:         regression test name and result
Owner / due:  name / date
Retest:       date and result
```

Keep raw evidence in the restricted case folder. Never paste production data,
tokens or personal data into tickets or chat.
