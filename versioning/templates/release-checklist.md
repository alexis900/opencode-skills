# Release X.Y.Z — checklist

Copy this list into the release PR or the milestone issue.

## Decision

- [ ] Release kind justified with the change table: patch / minor / major.
- [ ] Breaking changes identified and listed.
- [ ] Previous and new version: `X.Y.Z` → `X.Y.Z`.

## Code and data

- [ ] `main` green: fmt, lint, tests, contract, architecture.
- [ ] No secrets or PII in the diff.
- [ ] Migrations tested from an empty database.
- [ ] Migrations tested from the previous version.
- [ ] Expand/contract planned if the change is destructive.
- [ ] New configuration optional and documented.

## Contract and documentation

- [ ] OpenAPI/schema regenerated with no drift.
- [ ] CHANGELOG: `Unreleased` closed with a date and a new `Unreleased` opened.
- [ ] Migration guide written if there are breaking changes.
- [ ] Deployment documentation updated.

## Publication

- [ ] Release PR merged into `main`.
- [ ] Annotated tag `vX.Y.Z` on the published commit.
- [ ] Tag pushed to the remote.
- [ ] Release notes published.
- [ ] Images/packages labeled (`X.Y.Z`, `X.Y`, `X`; `latest` only for stable).
- [ ] Install or upgrade verified from the previous version.
