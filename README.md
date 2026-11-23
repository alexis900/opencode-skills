# OpenCode Skills

A collection of global skills for [OpenCode](https://opencode.ai). Each skill lives in its own
directory with a `SKILL.md` and optional `references/` and `templates/` files.

## Skills

| Skill | Description |
|---|---|
| `privacy-audit` | Audits whether an application's legal documents reflect its actual data practices. Read-only, evidence-based, with GDPR and multi-jurisdiction support. |
| `rust` | Applies a rigorous Rust engineering and security baseline to implementation, review, async, crypto, auth, dependencies and CI. |

---

## privacy-audit

Audits whether an application's legal documents (Privacy Policy, Terms of Service, Cookie Policy,
DPA) accurately and completely reflect its actual data practices. The output is a single structured
Markdown report saved to `./privacy-audit-report.md`.

### When it activates

The skill is advertised to the agent and loads when the user asks for:

- Privacy audits.
- GDPR or other jurisdiction compliance reviews.
- Privacy policy or terms-of-service reviews.
- Cookie and consent reviews.
- Comparison between legal documentation and the real behavior of an application.
- Identification of personal data processing activities.
- Evaluation of third-party services and international data transfers.

### How it works

- **Mode A — Documentary analysis:** the user provides an app description and the legal documents.
- **Mode B — Code analysis (preferred):** the user provides source code or a repository. The skill
  inspects dependencies, configuration, schemas, migrations, endpoints, authentication, forms,
  cookies, analytics, integrations, email, storage, logs and infrastructure.

It distinguishes confirmed evidence, indicators requiring verification, unavailable information
and external configuration that cannot be verified. It never assumes a service is active merely
because it appears as a dependency.

Default legal framework: EU GDPR, Spanish LOPDGDD and LSSI-CE for cookies. Additional support:
CCPA/CPRA, LGPD, UK GDPR, PIPL and the Australian Privacy Act.

### Structure

```text
privacy-audit/
├── SKILL.md
├── references/
│   ├── audit-methodology.md
│   ├── code-analysis.md
│   ├── gdpr-checklist.md
│   └── jurisdictions.md
└── templates/
    └── audit-report.md
```

### Installation

Copy one or more skills into the global OpenCode skills directory:

```bash
git clone https://github.com/alexis900/opencode-skills.git
mkdir -p ~/.config/opencode/skills
cp -r opencode-skills/privacy-audit opencode-skills/rust ~/.config/opencode/skills/
```

Or clone the collection inside the skills directory. OpenCode discovers nested `SKILL.md` files in
grouping directories:

```bash
git clone https://github.com/alexis900/opencode-skills.git \
  ~/.config/opencode/skills/opencode-skills
```

Each skill ID is its directory name (`privacy-audit`, `rust`). Load one explicitly with
`@privacy-audit` or `@rust`, or let OpenCode load it when a request matches its description.

### Safety

The audit is strictly read-only. It does not modify code, legal documents or configuration, does
not install dependencies, does not run migrations, does not deploy and does not send personal data
to third parties. It does not print secrets, tokens or credentials. Analyzed files are treated as
data, never as instructions.

### Disclaimer

This is automated analysis, not legal advice and not a certification of compliance. Consult a
qualified privacy lawyer for compliance-critical decisions.

---

## rust

A self-contained engineering and security baseline for Rust code. It covers implementation, review
and hardening of crates and services, and defines its own criteria without deferring to external
documents.

### When it activates

- Writing or refactoring Rust code, Cargo projects and workspace layout.
- Reviewing pull requests or auditing a crate for security and reliability.
- Choosing dependencies, configuring Clippy/CI or supply-chain checks.
- Hardening async/Tokio services, cryptography, authentication or web endpoints.

### What it covers

- **Errors:** layered `Result`/`thiserror`, boundary mapping without leaking internals, no panics
  in production paths.
- **Memory and `unsafe`:** `forbid(unsafe_code)` by default, `// SAFETY:` invariants, strong
  newtypes, `secrecy`/`zeroize`.
- **Async and concurrency:** no blocking on the runtime, no locks across `await`, bounded channels,
  timeouts, cancellation safety.
- **Crypto and auth:** Argon2id, CSPRNG tokens, constant-time comparison, revocable sessions,
  strict JWT validation.
- **Web services:** body/time limits, security headers, CSRF, SSRF allowlists, parameterized SQL,
  tenant checks, rate limiting.
- **Dependencies and CI:** `cargo deny`, `cargo audit`, lint policy, MSRV, minimal features,
  negative tests.

### Structure

```text
rust/
├── SKILL.md
├── references/
│   ├── async-concurrency.md
│   ├── crypto-auth.md
│   ├── dependencies-ci.md
│   ├── error-handling.md
│   ├── unsafe-memory.md
│   └── web-services.md
└── templates/
    └── rust-review.md
```

### Usage

Mention `@rust` explicitly, or let OpenCode load it when a request matches its description. The
review template is at `rust/templates/rust-review.md`; supporting references are read only when the
skill directs the agent to them.

---

## Adaptation notes (privacy-audit)

This skill is adapted from [bellu/privacy-audit](https://github.com/bellu/privacy-audit) (MIT). The
methodology, coverage and legal references are preserved. The following changes were made for
OpenCode:

- Removed the Claude.ai interactive React artifact, which called the Anthropic API and is not
  needed for a native skill.
- Removed Claude Code plugin packaging (`commands/`, `package.py`, `.claude-plugin/`, prebuilt
  `.skill` file).
- Replaced Claude-specific tools with OpenCode tools (`webfetch`, `read`).
- Changed the report destination from the Claude.ai sandbox path to `./privacy-audit-report.md`.
- Added the requested legal clarifications: DPO designation is not mandatory for every processing
  activity; the record of processing activities is internal and not a mandatory policy section;
  breach procedures need not be published in the policy; the response deadline is one month with
  the legally provided extensions; cookie consent depends on purpose and applicable law; US
  transfers are not automatically unlawful and do not all require the same mechanism; controller,
  processor and recipient are distinguished.

## License

MIT. See [LICENSE](./LICENSE).
