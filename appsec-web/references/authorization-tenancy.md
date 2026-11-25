# Authorization and multi-tenancy

## 1. One policy layer

- Centralize decisions in a policy module/middleware. Handlers ask
  `authorize(actor, action, resource)`; they do not reimplement rules.
- Default deny. A new route without an explicit policy must be rejected, not
  allowed.
- Separate authentication (who) from authorization (what). Never infer
  permission from the presence of a token.

```ts
// Deny by default: every handler declares its policy
router.get('/invoices/:id', requireAuth, policy('invoice:read'), handler);

// Policy resolves the object and checks tenant + role together
async function invoiceRead(actor, id) {
  const inv = await db.invoice.findFirst({
    where: { id, tenantId: actor.tenantId },   // tenant in the query, not after
  });
  if (!inv) throw notFound();                  // do not reveal existence
  if (!actor.can('invoice:read', inv)) throw forbidden();
  return inv;
}
```

## 2. Object-level authorization (IDOR/BOLA)

- Every client-supplied identifier is untrusted: path, query, body, headers,
  GraphQL arguments, WebSocket messages, signed URLs.
- Scope the database query by tenant/owner instead of fetching then checking.
  "Fetch then check" tends to leak via timing, errors and future refactors.
- Return `404` for resources outside the actor's scope; `403` only when the
  existence is already known.
- Cover nested resources: `/orgs/:orgId/projects/:projectId/...` must verify the
  whole chain, not just the leaf.
- Batch and export endpoints are high risk: they often skip per-item checks.
- Search, autocomplete and count endpoints leak existence and volume.

## 3. Multi-tenant isolation

- Tenant identity comes from the authenticated session, never from a header,
  query parameter or body.
- Enforce at the data layer where possible: RLS, schema per tenant, or a
  mandatory `tenant_id` predicate in the repository layer.
- Cache keys, rate-limit buckets, job payloads and file paths include the tenant.
- Cross-tenant admin tooling is a separate, audited role with explicit intent.
- Test with two tenants and prove reads, writes, deletes, exports and search are
  isolated.

## 4. Roles and permissions

- Prefer permissions (capabilities) over role checks; roles bundle permissions.
- Check the permission on the *resource*, not only globally: `document:read` on
  a document the actor can see.
- Admin surfaces: separate route namespace, stronger auth (MFA/step-up),
  network restriction where possible, full audit.
- Avoid "superuser" flags in application logic; use explicit break-glass roles
  with time limits and alerts.
- Revoke on role change, offboarding and tenant removal; invalidate sessions.

## 5. Mass assignment and field-level control

- Bind only allowlisted fields; never spread the request body into a model.
- Separate input DTOs from persistence models. Mark server-controlled fields
  (`role`, `tenantId`, `ownerId`, `price`, `status`) as non-writable.
- Use explicit serializers for output; do not return ORM entities with hidden
  columns.

```ts
const input = updateProfileSchema.parse(req.body); // strict schema, no extras
await users.update(id, { name: input.name, locale: input.locale });
```

## 6. GraphQL and RPC

- Authorize at the resolver *and* at the data loader; a loader must not return
  objects outside the actor's scope.
- Disable introspection in production if it adds no value; keep query depth and
  complexity limits.
- Avoid `node(id:)` global ID lookups without a tenant/policy check.
- Persisted queries or allowlists reduce attack surface for public APIs.
- For RPC, treat every method as an endpoint with its own policy declaration.

## 7. Background jobs and async flows

- A job runs with explicit actor context and tenant, not with "system" rights by
  default.
- Re-check authorization when the job acts on behalf of a user (permissions may
  have changed since enqueue).
- Idempotency keys prevent duplicate side effects.
- Webhooks: verify signatures, timestamps and replay protection; never trust
  the payload's tenant or user.

## 8. Tests

| Test | Expected |
| --- | --- |
| User A reads object of user B | 404/403, no data |
| Tenant A lists tenant B records | Empty |
| Role without `delete` calls delete | 403, no state change |
| Nested resource with mismatched parent | 404 |
| Admin route as normal user | 403 and audit entry |
| Job for revoked user | Denied or cancelled |
| GraphQL node lookup across tenants | Null/error |

Log every denied authorization with actor, action, resource and correlation ID
(no sensitive payloads).
