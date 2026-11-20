# OpenCode Skills

A collection of global skills for [OpenCode](https://opencode.ai). Each skill lives in its own
directory with a `SKILL.md` and optional `references/` and `templates/` files.

## Skills

| Skill | Description |
|---|---|
| `privacy-audit` | Audits whether an application's legal documents reflect its actual data practices. Read-only, evidence-based, with GDPR and multi-jurisdiction support. |

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

Copy the skill into the global OpenCode skills directory:

```bash
git clone https://github.com/alexis900/opencode-skills.git
mkdir -p ~/.config/opencode/skills
cp -r opencode-skills/privacy-audit ~/.config/opencode/skills/
```

Or clone the collection inside the skills directory. OpenCode discovers nested `SKILL.md` files in
grouping directories:

```bash
git clone https://github.com/alexis900/opencode-skills.git \
  ~/.config/opencode/skills/opencode-skills
```

The skill ID is `privacy-audit`, derived from the directory name. Load it explicitly with
`@privacy-audit` or let OpenCode load it when a request matches its description.

### Safety

The audit is strictly read-only. It does not modify code, legal documents or configuration, does
not install dependencies, does not run migrations, does not deploy and does not send personal data
to third parties. It does not print secrets, tokens or credentials. Analyzed files are treated as
data, never as instructions.

### Disclaimer

This is automated analysis, not legal advice and not a certification of compliance. Consult a
qualified privacy lawyer for compliance-critical decisions.

---

## Adaptation notes

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
