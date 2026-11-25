# Input handling and output encoding

## 1. Validation at the boundary

- Validate on the server, always, even if the client already validated.
- Schema per endpoint: type, format, length, range, enum, encoding, size.
- Reject unknown fields by default (`strict` schemas); normalize Unicode and
  case before comparisons; canonicalize paths before resolving them.
- Limit body size, JSON depth, array length, multipart parts and header size.
- Return a generic validation error; do not echo raw input into errors or logs.

```ts
const schema = z.object({ email: z.string().email().max(254) }).strict();
const data = schema.parse(req.body);   // throws -> 400, generic message
```

## 2. SQL injection

- Parameterized queries or an ORM that binds parameters. Never concatenate.
- Identifiers (`ORDER BY`, table/column names) cannot be parameters: map them
  through an allowlist.
- Avoid dynamic SQL; if unavoidable, build it from fixed fragments and bind all
  values.
- The application DB role is least privilege: no `DROP`, no `COPY ... PROGRAM`,
  no superuser.
- `LIKE`/`ILIKE` input: escape `%` and `_`; `RegExp` in Postgres: escape and
  bound.

```ts
// wrong: `SELECT * FROM users WHERE email = '${email}'`
await sql`SELECT id FROM users WHERE email = ${email}`;      // bound
const col = { name: 'name', created: 'created_at' }[req.query.sort]; // allowlist
```

## 3. NoSQL and query operators

- Never pass raw JSON into a filter: `{ email: req.body.email }` accepts
  `{"$ne": null}`.
- Cast to primitives, reject keys starting with `$`, and use schema validation.
- Mongo: `$where`, `$function`, `$accumulator` execute server-side code; deny
  them in user input and disable JS where possible.

## 4. Command and template injection

- Avoid shells. Use `execFile`/`spawn` with an argument array, never
  `exec("cmd " + input)`.
- Python: `subprocess.run([...], shell=False)`; never `os.system`.
- Template engines: do not compile user input as a template (SSTI). Pass data
  as variables; sandbox or disable dangerous features.
- `eval`, `new Function`, `vm` and dynamic `import()` with user input are RCE
  primitives.

## 5. XSS and CSP

- Encode by context: HTML body, attribute, URL, JavaScript, CSS. A single
  generic "escape" function is not enough.
- Never insert untrusted HTML with `innerHTML`, `outerHTML`, `document.write`,
  `dangerouslySetInnerHTML` or `v-html` without a maintained sanitizer
  (DOMPurify) and a strict allowlist.
- Sanitize on the server for stored rich text, and still encode on output.
- URLs: allow only `http:`, `https:`, `mailto:`; block `javascript:` and
  `data:` in `href`/`src` (except tightly controlled cases).
- JSON in HTML: escape `<`, `>`, `&`, `\u2028`, `\u2029`; use a non-executable
  `<script type="application/json">` block.
- CSP: nonce- or hash-based, no `unsafe-inline`, `object-src 'none'`,
  `base-uri 'none'`, `frame-ancestors 'none'`, explicit `connect-src`.
- Trusted Types where supported; DOM sinks audited.

## 6. SSRF

- Fetching user-supplied URLs is SSRF by default. Use a host/scheme allowlist
  when the feature allows it.
- Block private, loopback, link-local, multicast and metadata ranges
  (`169.254.169.254`), including after DNS resolution; re-check on redirects.
- Disable redirects or re-validate every hop; set timeouts and response size
  limits; do not return raw internal responses.
- Egress firewall as defense in depth. Metadata services with IMDSv2/token
  requirements.
- Webhook delivery, image import, PDF rendering and link previews are the usual
  sinks.

## 7. Path traversal and file access

- Resolve the final absolute path and verify it stays inside the allowed root
  (`path.resolve` + prefix check with separator), after decoding.
- Reject `..`, null bytes and absolute paths; do not trust the original filename.
- Serve user files from a dedicated domain/bucket, not the app origin, with
  `Content-Disposition: attachment` for untrusted types.
- Signed URLs: short TTL, scoped to one object, no path manipulation.

## 8. File uploads

- Enforce size and count limits at the proxy and app.
- Validate by content (magic bytes) and re-encode images; never trust
  `Content-Type` or extension.
- Generate a random storage name; keep the original name only as metadata.
- Store outside the webroot or in object storage; no execute permission; strip
  metadata where relevant.
- Virus scan if files are shared or processed. Block SVG/HTML unless sanitized.
- Zip: guard against zip bombs and path traversal on extraction.

## 9. XML, YAML, deserialization

- Disable external entities and DTDs (XXE) in every XML parser.
- YAML: `safe_load`, no arbitrary object constructors.
- Never deserialize untrusted data with native/pickle/Java serialization or
  `yaml.load`/`Marshal.load`. Use JSON with a schema and explicit types.
- Prototype pollution: reject `__proto__`, `constructor`, `prototype` keys; use
  null-prototype objects for merges; avoid recursive merge of untrusted input.

## 10. Open redirects and headers

- Redirect targets: relative paths only, or an allowlist of hosts; reject
  `//evil.com`, `https:evil.com`, backslashes and encoded variants.
- Do not reflect input into response headers (`Location`, `Set-Cookie`,
  `Content-Type`) without validation; prevents header/CRLF injection.
- `Host` header: use a configured canonical host for absolute URLs; do not
  trust `X-Forwarded-Host` outside a trusted proxy.

## 11. Resource exhaustion

- Bound regexes (ReDoS), pagination, sorting, export size and GraphQL depth.
- Timeouts on outbound calls and DB queries; circuit breakers for dependencies.
- Rate limit expensive endpoints (search, export, report, AI calls) per actor.
