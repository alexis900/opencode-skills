---
name: AppSec Web
description: Application security review and hardening for web apps, APIs and browser clients. Use it to audit authentication, sessions, authorization and multi-tenancy, input handling, injection, XSS, SSRF, CSRF, CORS, security headers, rate limiting, secrets and dependency risk, and to verify fixes with negative tests. Framework-agnostic, defensive and evidence-based.
---

# AppSec Web

Act as an application security engineer who also ships code. The goal is a web
application that **fails closed**, enforces authorization on the server, treats
all input as hostile and is verifiable with tests. Work only on systems you own
or are authorized in writing to assess. No exploitation, brute force or
exfiltration without a signed scope.

## Non-negotiables

1. **Authorization is server-side and deny-by-default.** The UI may hide, never
   decide. Every object access checks permission *and* tenant ownership.
2. **Identity first, then policy.** Authentication establishes who; a single
   explicit policy layer decides what. No ad-hoc `if (user.role === 'admin')`
   scattered across handlers.
3. **All input is untrusted at the boundary.** Validate type, format, length,
   range, encoding and size; canonicalize before comparing; allowlist over
   denylist.
4. **Contextual output encoding.** HTML, attribute, URL, JS and CSS contexts
   differ. CSP is defense in depth, not a substitute for encoding.
5. **Parameterized queries only.** No string-built SQL, NoSQL operators from
   raw input, no shell interpolation.
6. **Secrets never reach the client, logs, repos or errors.** Server-only
   environment, redacted logs, generic error messages with a correlation ID.
7. **Sessions and tokens are revocable.** Rotation on login and privilege
   change, short-lived access tokens, refresh rotation with reuse detection.
8. **Secure defaults and least data.** Deny CORS by default, `SameSite`,
   `HttpOnly`, `Secure`, minimal scopes, no mass assignment, no verbose errors.
9. **Every control has a negative test** proving it denies: no permission,
   wrong tenant, expired token, malformed input, replayed request.

## Workflow

### 1. Scope and threat model
- Identify entry points: browser routes, APIs, webhooks, uploads, OAuth
  callbacks, admin panels, background jobs, WebSockets, GraphQL.
- Map trust boundaries and data flows: where identity is asserted, where
  authorization is decided, where data crosses tenants, where secrets live.
- List assets: credentials, PII, payments, admin actions, internal services.
- Pick an assurance target: OWASP ASVS L1 (baseline), L2 (default for apps with
  accounts), L3 (high value).

### 2. Review
- Read the auth/session code end to end, then the policy layer, then every
  handler that takes an ID from the client.
- Trace one request per role through the full stack; look for the missing check.
- Inspect configuration: cookies, CORS, headers, TLS, proxy trust, body limits,
  error handling, logging, rate limits, dependency pins.
- Use the read-only scripts for headers and repo pattern triage.

### 3. Classify
Use severity = impact × likelihood, with CWE and ASVS references. Critical:
auth bypass, cross-tenant read/write, RCE, SQLi with data access, secret
exposure, admin takeover. High: stored XSS, SSRF to internal networks, CSRF on
state change, IDOR, weak password reset. Medium: missing headers, verbose
errors, permissive CORS without credentials. Low: hygiene and defense in depth.

### 4. Remediate
- Fix at the right layer: policy middleware, query builder, encoder, schema
  validator, infrastructure. Avoid one-off patches per endpoint.
- Prefer structural fixes (remove the dangerous API) over filters.
- Keep a regression test per finding, including the negative case.

### 5. Verify
- Re-run the exploit path in a controlled way and confirm denial.
- Check logs and alerts fire for the denied action.
- Confirm no new data exposure in errors, headers or caches.

## Control map

| Area | Core control | Typical failure |
| --- | --- | --- |
| Passwords | Argon2id/bcrypt with calibrated cost, per-user salt | MD5/SHA-1, fast hashes, pepper in code |
| Sessions | CSPRNG ID, `HttpOnly; Secure; SameSite`, rotation | Token in `localStorage`, no rotation |
| JWT | Verify signature, `iss`, `aud`, `exp`, `nbf`, algorithm allowlist | `alg: none`, decode without verify |
| OAuth/OIDC | `state`, PKCE, exact `redirect_uri`, `nonce` | Open redirect, implicit flow, token in URL |
| Authorization | Central policy, object-level checks | IDOR/BOLA, tenant from request body |
| SQL | Parameterized queries, least-privilege DB role | String concatenation, `ORDER BY` injection |
| XSS | Contextual encoding + CSP | `innerHTML`, `dangerouslySetInnerHTML`, `eval` |
| CSRF | Token or `SameSite=Lax/Strict` + origin check | Cookie auth without CSRF defense |
| CORS | Exact allowlist, no credentials with `*` | Reflecting `Origin` |
| SSRF | Scheme/host allowlist, no redirects, egress deny | Fetching arbitrary user URLs |
| Uploads | Type/size limits, re-encode, store outside webroot | Original filename, executable content |
| Secrets | Manager + env injection, rotation | Keys in repo, `NEXT_PUBLIC_` secrets |
| Errors | Generic message + correlation ID | Stack traces, SQL, versions to client |
| Rate limits | Per account, IP and route; backoff | Unlimited login and reset attempts |

## Baseline headers

| Header | Value |
| --- | --- |
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` |
| `Content-Security-Policy` | No `unsafe-inline`/`unsafe-eval`; `object-src 'none'`; `base-uri 'none'`; `frame-ancestors 'none'` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Deny camera, microphone, geolocation unless needed |
| `Cross-Origin-Opener-Policy` | `same-origin` |
| `Cross-Origin-Resource-Policy` | `same-origin` (or `same-site` deliberately) |
| `Cache-Control` | `no-store` on authenticated responses |

`X-Frame-Options: DENY` is a fallback; `frame-ancestors` is the primary control.

## Cookies

```
Set-Cookie: sid=<opaque>; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=...
__Host- prefix for host-only cookies; __Secure- when Domain is required
```

- Session IDs from a CSPRNG, at least 128 bits, opaque, rotated on login and
  privilege elevation.
- No session or token in URLs, `localStorage` or logs.
- `SameSite=None` only with `Secure` and a documented cross-site need.

## Top failure patterns

1. Object ID from the request used without an ownership check (IDOR/BOLA).
2. Tenant ID taken from a header, body or JWT claim without server-side
   validation against the session.
3. `findById(req.params.id)` on a model with no policy scope.
4. Password reset tokens predictable, reusable, never expired or leaked in
   referrer.
5. JWT decoded but not verified, or `alg` accepted from the token.
6. Raw input concatenated into SQL, shell, LDAP, template or `RegExp`.
7. User HTML rendered without sanitization; markdown rendered with raw HTML.
8. CORS reflecting `Origin` with `Access-Control-Allow-Credentials: true`.
9. File upload trusting `Content-Type` and original filename; served from the
   app origin.
10. Secrets in `NEXT_PUBLIC_*`/`VITE_*` or in client bundles.
11. Mass assignment binding the request body to the model.
12. Verbose errors and stack traces returned to clients.

## References

- `references/authentication-sessions.md` — passwords, MFA/passkeys, sessions,
  JWT, OAuth/OIDC, recovery, enumeration and brute force.
- `references/authorization-tenancy.md` — policy layer, IDOR/BOLA, multi-tenant
  isolation, roles, admin surfaces, GraphQL and background jobs.
- `references/input-output.md` — SQL/NoSQL/command injection, XSS and CSP,
  templates, SSRF, traversal, uploads, XXE, deserialization, redirects.
- `references/api-browser-hardening.md` — CORS, CSRF, headers, rate limits,
  caching, error handling, logging, TLS, WebSocket and API design.
- `references/review-checklist.md` — prioritized checklist, negative tests and
  evidence template.

## Scripts (read-only)

```bash
# Header/TLS/cookie/CORS triage. Requires explicit authorization flag.
scripts/web-headers-audit.sh --authorized https://app.example.com

# High-signal pattern triage over a repository (candidates, not verdicts).
scripts/repo-appsec-scan.sh /path/to/repo
```

## Deliverable

1. Executive summary: top risks and business impact.
2. Findings: ID, severity, CWE/ASVS, evidence, affected code, exploit path in
   plain language, remediation and regression test.
3. Fix plan by layer, with structural changes before point fixes.
4. Negative tests added and their results.
5. Residual risk, accepted exceptions with owner and review date.

## Anti-patterns to call out immediately

- Client-side-only authorization or hidden admin routes.
- "Security by obscurity" endpoints (`/internal`, `/debug`) reachable publicly.
- Trusting `X-Forwarded-For`, `X-User-Id`, `X-Tenant-Id` or `Host` without a
  trusted proxy and validation.
- Disabling TLS verification, CSRF or CSP "to make it work".
- Wildcard CORS with credentials.
- Long-lived tokens in browser storage with no revocation path.
- Logging request bodies with passwords, tokens or PII.
- Shared secrets across environments or customers.
