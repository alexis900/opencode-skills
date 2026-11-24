---
name: versioning
description: Define, apply and audit the versioning and release system of any project. Use when deciding a version bump, preparing a release or tag, writing a CHANGELOG, naming branches for a milestone, cutting pre-releases and release candidates, handling breaking changes or deprecations before 1.0, aligning versions in a monorepo or workspace, tagging container images, or reviewing whether a change needs a minor, patch or major release.
---

# Versioning and releases

A semantic-versioning and release system for any project. If the repository has its own ADR or policy, that policy wins; this document covers what is not already decided and works as a checklist.

## Principles

1. **Single source of version.** The number is declared once per publishable artifact: the workspace `Cargo.toml`, the root `package.json`, `pyproject.toml`, and so on. Every other manifest inherits or references it; never copy it by hand.
2. **The version describes compatibility, not effort.** It is not raised because of commit count or elapsed time.
3. **Tags are immutable.** A published tag is never moved, rewritten or reused. If a release is wrong, publish a new one.
4. **`main` is always deployable.** Everything that reaches `main` builds, passes tests and can be deployed. Releases are cut from `main`.
5. **The CHANGELOG is part of the change.** It is updated in the same PR that introduces the change, not in a follow-up commit.
6. **One tag, one release, release notes.** Every tag has notes explaining what changed and how to upgrade.

## Version scheme

`MAJOR.MINOR.PATCH` following SemVer 2.0.0.

| Change | Version | Example |
|---|---|---|
| Compatible fix, no new API | `PATCH` | `1.4.2` → `1.4.3` |
| Compatible functionality | `MINOR` | `1.4.3` → `1.5.0` |
| Breaking API, data or documented behavior | `MAJOR` | `1.5.0` → `2.0.0` |
| Internal work with no consumer impact | `PATCH` | `0.0.7` → `0.0.8` |

### Before 1.0

- `0.0.x`: scaffolding, tooling, internal debt. No stable contract.
- `0.x.0`: functional milestone. It may break the API, but it **must** say so in the CHANGELOG and release notes.
- `1.0.0`: first version with a compatibility promise.

Do not use `0.x.y` for features: a milestone raises `x`. Do not declare anything stable before 1.0.

### Pre-releases

`1.0.0-alpha.1`, `1.0.0-beta.2`, `1.0.0-rc.1`. Use them when feedback or validation is needed before committing to compatibility. An RC does not change the API except for fixes; if it does, bump the RC number.

Never publish a stable release with build metadata as a substitute for an RC.

## What each kind of change requires

### Breaking (MAJOR, or MINOR before 1.0)

- Removing or renaming an endpoint, field, parameter, permission, table or configuration variable.
- Changing the meaning of an existing value.
- Raising a dependency floor in a way that breaks consumers.
- Changing the format of a token, cookie, file or message.
- Requiring a data migration that is not backward compatible.

Every break includes: a CHANGELOG entry, a migration guide and, when data is involved, an expand/contract window.

### Compatible (MINOR)

- New, optional endpoint, field or parameter.
- New permission without removing existing ones.
- Accessibility or behavior improvements that do not break contracts.
- New dependency without changing the public API.

### Fix (PATCH)

- Bug fix without new API.
- Security-driven dependency update.
- Documentation, tests, CI or tooling with no consumer impact.

### Deprecations

Announce in a `MINOR`, keep for at least one full `MINOR` and remove in the next `MAJOR` (or the next `MINOR` before 1.0, with notice). The notice says what to use instead and the removal version or date.

## Tags

- Default format: `vX.Y.Z` (`v1.4.3`). If the repository already uses another format, keep it; do not mix formats.
- **Annotated** tags, not lightweight: `git tag -a v1.4.3 -m "v1.4.3"`.
- Sign them when the project has a configured key.
- The tag points at the `main` commit that was published, usually the release PR merge.
- Archive or historical tags use their own prefix (`archive/0.1.0`) and are never confused with releases.
- After publishing: `git push origin v1.4.3`. Never `--force` a tag.

## Branch and release flow

```text
main ──●──●────────●──────────●──●──►  (always deployable)
        \        /            \
         feat/x               release/1.4.0 (optional, only for several PRs)
```

1. Short-lived branch per task (`feat/`, `fix/`, `refactor/`, `docs/`, `ci/`, `security/`).
2. PR into `main`; green CI and acceptance criteria met.
3. If a milestone needs several PRs, use a phase branch `dev/mN`; it starts from `main`, receives verified PRs and closes with a PR back to `main`. It is ephemeral.
4. Release: a release PR that only contains the version and CHANGELOG (or the final milestone PR), merged into `main`.
5. Tag on `main`, release notes, publish artifacts.
6. Hotfix: a `fix/` branch from the affected tag if `main` is not deployable; publish a `PATCH` and merge it back.

Do not keep permanent release branches unless the project requires them; if they exist, state which versions receive patches and for how long.

## CHANGELOG

[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format:

```markdown
## [Unreleased]

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
```

- Write for consumers, not implementers: what changed and what they must do.
- Reference the issue or PR when it adds context.
- In the release PR, `Unreleased` becomes `[X.Y.Z] - YYYY-MM-DD` and a new empty `Unreleased` opens.
- Never rewrite the history of published versions.

## Monorepos and multiple artifacts

- Every publishable package has its own version; versions may be aligned or independent, but the policy is stated.
- In a Rust workspace, `[workspace.package] version` is the source and crates use `version.workspace = true`.
- Internal dependencies use the same version (`workspace = true` or an exact range), never floating ranges.
- One tag can cover several packages published together; if they are published separately, each package gets its own prefixed tag (`neoid-v0.3.0`, `neoui-v0.1.0`).
- Container images publish `X.Y.Z`, `X.Y`, `X` and `latest` according to policy; `latest` never points at a pre-release.

## Data and deployment compatibility

- Forward-only, numbered migrations that are immutable once published.
- Destructive changes use expand/contract across separate releases: expand, deploy, migrate, contract.
- A release that requires a migration says so in the notes and the deployment guide.
- New configuration is optional in the first release that introduces it; removal follows the deprecation cycle.

## Checklist before tagging

- [ ] `main` is green and deployable.
- [ ] Version chosen from the change table, not by intuition.
- [ ] Single source updated and derived manifests consistent.
- [ ] CHANGELOG complete, with breaks and migration guide when applicable.
- [ ] Migrations tested from an empty database and from the previous version.
- [ ] Public contract regenerated if one exists (OpenAPI, types, schema).
- [ ] Release notes drafted.
- [ ] Annotated tag created on the right commit and pushed.
- [ ] Artifacts and images published with the expected labels.

## After publishing

- Verify the downloadable artifact matches the tag.
- Check installation or upgrade from the previous version.
- Announce breaking changes and the upgrade order.
- If something fails, do not move the tag: publish a `PATCH` or withdraw the release with a notice.

## Anti-patterns

- Raising `MAJOR` for "internal changes" or commit count.
- Reusing or moving a published tag.
- A CHANGELOG written as a commit list.
- Publishing `latest` from an RC.
- Leaving `Unreleased` empty after a release.
- Changing the public API in a `PATCH`.
- Shipping a destructive migration in the same release as the code that uses it.

## Repository profiles

Read the local policy before acting when one exists:

- **NeoID:** ADR-0005. Cargo workspace as the single source, `vX.Y.Z` tags, `0.0.x` internal, `0.x.0` per milestone, `1.0.0` stable, `dev/mN` phase branch, expand/contract migrations.
- **NeoUI:** independent version; NeoID consumes a pinned tag through a submodule. The `@neoui/*` packages share one version inside the repo.

If the project has no policy, this document is the default policy.
