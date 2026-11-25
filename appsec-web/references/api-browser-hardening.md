# API and browser hardening

## 1. CORS

- Deny by default. Allow only exact origins from a configured list; never
  reflect `Origin` blindly.
- `Access-Control-Allow-Credentials: true` requires an exact origin, never `*`.
- Limit methods and headers; set `Vary: Origin` when the response varies.
- Preflight responses must not leak data; do not treat CORS as authorization.
- Do not enable CORS for admin or internal APIs unless strictly required.

```ts
// Express: exact allowlist, credentials only for known origins
app.use(cors({
  origin: (origin, cb) => cb(null, allowed.has(origin)),
  credentials: true,
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
}));
```

## 2. CSRF

- Needed whenever authentication is cookie-based and the request changes state.
- Defenses: `SameSite=Lax/Strict`, synchronizer token or double-submit with a
  signed value, and `Origin`/`Sec-Fetch-Site` validation.
- Apply to form posts, JSON APIs accepting `text/plain` or form content, and
  logout if it has side effects.
- Do not rely on a custom header alone if CORS is permissive.
- Token must be bound to the session and validated server-side.

## 3. Security headers

| Header | Recommended |
| --- | --- |
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` |
| `Content-Security-Policy` | nonce/hash based, `default-src 'self'`, `object-src 'none'`, `base-uri 'none'`, `frame-ancestors 'none'` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` (or `no-referrer` on token pages) |
| `Permissions-Policy` | disable unused features |
| `Cross-Origin-Opener-Policy` | `same-origin` |
| `Cross-Origin-Resource-Policy` | `same-origin` |
| `Cache-Control` | `no-store` for authenticated/sensitive responses |

- Remove `X-Powered-By`, `Server` version details and framework fingerprints.
- Apply headers at the edge and in the app; verify both paths.

## 4. TLS and transport

- TLS 1.2 minimum, 1.3 preferred; modern cipher suites; HSTS after verifying
  all subdomains support HTTPS.
- Redirect HTTP to HTTPS with 301/308; no mixed content.
- Validate upstream certificates; never `rejectUnauthorized: false` or
  `verify=False` outside a documented local test.
- Internal service-to-service traffic also uses TLS or mTLS.

## 5. Rate limiting and abuse

- Limits per account, IP, token and route; stricter on login, reset, register,
  OTP, search, export and AI endpoints.
- Use a shared store (Redis) behind multiple instances; key on trusted client
  identity, not spoofable headers.
- Return `429` with `Retry-After`; avoid leaking whether an account exists.
- Add bot defenses where needed; monitor for distributed low-and-slow attempts.

## 6. Caching

- `Cache-Control: no-store` on authenticated and personalized responses.
- `Vary` on `Authorization`, `Cookie`, `Origin` where relevant.
- Never cache responses containing tokens, PII or per-tenant data in shared
  caches/CDNs without explicit keys.
- Purge on permission or data change; avoid cache-key collisions across tenants.

## 7. Errors and logging

- Client: stable error code, generic message, correlation ID. No stack traces,
  SQL, file paths, versions or internal hostnames.
- Server: structured logs with actor, tenant, action, resource, result,
  correlation ID. Redact passwords, tokens, cookies, authorization headers, PII.
- Do not log full request bodies by default; sample and mask when needed.
- Security events: auth failures, authorization denials, privilege changes,
  secret access, admin actions, exports.
- Never log secrets even at debug level; configure redaction at the logger.

## 8. API design

- Authenticate every endpoint explicitly; no "public by accident".
- Validate and schema-check input; reject unknown fields.
- Use stable, non-enumerable IDs (UUID/ULID) where exposure matters; do not rely
  on obscurity.
- Pagination with server caps; no unbounded `limit`.
- Idempotency keys for payment/state-changing POSTs.
- Version APIs; deprecate with notice; do not keep insecure legacy auth.
- GraphQL: depth/complexity limits, disable introspection if not needed,
  persisted queries for public surfaces, per-field authorization.

## 9. WebSockets and real-time

- Authenticate during the handshake and re-check authorization per message and
  per subscription.
- Validate `Origin`; reject cross-site connections by default.
- Authorize channel/room membership server-side; do not trust client-supplied
  room or tenant IDs.
- Limit message size and rate; heartbeat and idle timeout.
- Do not put long-lived credentials in query strings.

## 10. Third parties and embeds

- Load third-party scripts with SRI and a strict CSP; prefer self-hosting.
- Iframes: `sandbox`, `allow` minimal, `referrerpolicy`.
- Webhooks: verify HMAC signatures with timestamp and replay window; use
  constant-time comparison.
- Do not send PII to analytics, error trackers or LLM providers without a legal
  basis and redaction.
