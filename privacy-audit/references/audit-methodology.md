# Audit Methodology

Detailed workflow for a privacy and legal-documentation audit. Use this file together with
`SKILL.md`, `gdpr-checklist.md` and `jurisdictions.md`.

---

## Two input modes

### Mode A — Documentary analysis

The user supplies an app description and the legal documents (Privacy Policy, ToS, Cookie Policy,
DPA). Build the app's reality from the description and from any documents that describe actual
practices (security pages, subprocessor lists, help-center articles).

### Mode B — Code analysis (preferred when code is available)

The user supplies source code, a local project or a repository URL. Extract the app's reality
directly from the code. Do not ask for a manual description that the code can answer.

Investigate at least:

- Dependencies and libraries.
- Environment variables and configuration.
- Data models and database schemas.
- Migrations.
- Endpoints and controllers.
- Authentication and sessions.
- Forms and personal-data fields.
- Cookies and local storage.
- Analytics and tracking.
- External integrations.
- Email and communication services.
- File storage.
- Logs and monitoring.
- Infrastructure and hosting providers.
- Data transfers to third parties.

Do not assume a service is active merely because it is listed as a dependency. Look for evidence of
real use: imports, initialization calls, request handlers, schema references, tracking calls,
configuration keys referenced by the code.

---

## Step 1 — Extract app reality

Produce a structured inventory with these fields:

### Personal data collected

- Identity data: name, email, phone, address, birth date, photos, avatars.
- Account and authentication data: credentials, OAuth tokens, sessions, MFA data.
- Behavioral data: page views, clicks, searches, events, feature usage.
- Device and technical data: IP address, user agent, device identifiers, approximate location.
- User-generated content: messages, files, images, documents, free-text inputs.
- Transactional data: payments, invoices, billing details, customer identifiers.
- Special-category data: health, biometrics, precise location, political opinions, religion,
  trade-union membership, sexual orientation, genetic data.
- Data about minors.

### Data subjects

- End users and customers.
- Employees or contractors, if the app processes their data.
- Prospects and newsletter subscribers.
- Third parties mentioned by users.
- Minors, when applicable.

### Processing purposes

- Core functionality and service delivery.
- Authentication and account management.
- Payments and billing.
- Communications and notifications.
- Analytics and product improvement.
- Marketing and advertising.
- Security, fraud prevention and abuse detection.
- AI/ML features or training.
- Legal compliance and record keeping.

### Storage and infrastructure

- Databases and regions.
- Object storage and CDN.
- Hosting and serverless platforms.
- Backups.
- Retention periods, where defined by code or configuration.

### Third parties and subprocessors

- Analytics and tracking providers.
- Authentication and identity providers.
- Payment processors.
- Email and messaging providers.
- Error tracking, logging and monitoring.
- AI providers.
- Storage providers.
- Feature-flag and A/B-testing providers.
- Infrastructure and hosting providers.

Use the actual service name found in the code (for example, "Stripe", not "a payment provider").

### User-rights mechanisms

- Account deletion and data erasure.
- Data export or portability.
- Consent and withdrawal flows.
- Opt-out mechanisms.
- Marketing preferences.
- Access and correction flows.

### Special categories

- Health data.
- Financial data.
- Precise location.
- Biometrics.
- Data of minors.
- Other Art. 9 GDPR categories.

---

## Step 2 — Extract legal-document claims

For each provided document, extract what it claims about the same categories:

- Which data is collected.
- For which purposes.
- On which legal basis.
- Which recipients and subprocessors are named.
- Which international transfers occur and which safeguards are invoked.
- Which retention periods are stated.
- Which rights are offered and how they are exercised.
- Which cookies and trackers are disclosed.
- Which contact details and controller identity are given.

Quote or reference the relevant section of the document, so that the comparison in Step 3 is
traceable.

---

## Step 3 — Gap analysis

Compare app reality against legal-document claims across these dimensions:

### Critical dimensions

- Undisclosed personal-data collection.
- Undisclosed third-party sharing or subprocessors.
- Missing legal basis for a processing purpose (GDPR Art. 6).
- Missing or unusable data-subject rights mechanisms.
- Incorrect or missing retention criteria.
- Undisclosed international transfers (GDPR Chapter V).

### Important dimensions

- Vague or non-specific language where specificity is required.
- Cookies or trackers not covered by the cookie documentation.
- Missing or weak DPA clauses where third-party personal data is processed.
- No information about breach handling where the document is expected to address it.
- Missing distinction between controller, processor and recipient.
- Consent flows that are bundled, pre-checked or not withdrawable.

### Minor dimensions

- Outdated contact details or DPO information.
- No plain-language summary.
- Missing version or last-updated date.
- Terms of Service that do not reflect the current feature set.
- Inconsistent terminology across documents.

### Honesty rules for gaps

- A gap exists when the documents **contradict** observed behavior, or when a disclosed practice is
  materially incomplete.
- Absence of an implementation in the code is **not** proof that the practice does not exist. Mark
  it as "not verifiable" when appropriate.
- A dependency without observed usage is an **indicator**, not confirmed evidence.
- Never state that the application "violates the GDPR" based only on missing code evidence.

---

## Step 4 — GDPR checklist

Run `references/gdpr-checklist.md` and mark every item:

- ✅ Covered adequately.
- ⚠️ Partially covered or vague.
- ❌ Missing or incorrect.
- N/A Not applicable to this application.

For each non-✅ item, record the evidence, the affected document and the legal reference.

---

## Step 5 — Recommendations

For every finding, provide:

- **What is missing** — the specific clause, disclosure or mechanism.
- **Why it matters** — the legal or regulatory exposure, without overstating it.
- **Suggested fix** — concrete draft language or an actionable change.
- **Priority** — consistent with the severity level.
- **Certainty** — confirmed, indicator, not available or external configuration.

Prioritize recommendations so the user can act on the highest-risk items first.

---

## Certainty levels

Use these labels consistently:

| Level | Meaning |
|---|---|
| Confirmed | Directly observed in code, configuration or documents |
| Indicator | Plausible from a dependency or partial signal, but usage is unconfirmed |
| Not available | The source was not provided or could not be read |
| External | Depends on dashboard settings, hosting configuration or a contract that cannot be inspected |

---

## Transparency checklist

Before closing the report, verify that it states:

- Files and directories actually analyzed.
- Files, modules or environments not accessible.
- Information that depends on external services or providers.
- Conclusions needing manual verification (browser storage, network requests, deployed behavior).
- Questions that require professional legal advice.

The report is not a certification of compliance and not a legal opinion.
