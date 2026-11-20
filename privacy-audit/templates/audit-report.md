# Privacy & Legal Audit Report

**Application:** [name]
**Date:** [YYYY-MM-DD]
**Documents audited:** [Privacy Policy, ToS, Cookie Policy, DPA — or "provided by user"]
**Jurisdictions assessed:** [EU GDPR; Spain LOPDGDD/LSSI-CE; other]
**Audit mode:** [A — documentary / B — code analysis]
**Report file:** `./privacy-audit-report.md`

> This report is an automated analysis. It is not a certification of compliance and not a legal
> opinion. Consult a qualified privacy lawyer for compliance-critical decisions.

---

## 1. Executive summary

[Two or three sentences describing the overall compliance posture, the most serious gaps and the
main recommendation.]

---

## 2. Scope and limitations

### 2.1 Sources analyzed

- [Files, directories, documents and URLs actually reviewed.]

### 2.2 Not reviewed

- [Parts of the project, environments or third-party dashboards that were not accessible.]

### 2.3 External dependencies

- [Information that depends on external services, plans or contractual terms.]

### 2.4 Needs manual verification

- [Browser storage, network requests, deployed behavior, consent banner behavior, etc.]

### 2.5 Needs professional legal advice

- [Questions that exceed automated analysis.]

---

## 3. Personal data inventory

| Category | Examples | Source (code/document) | Evidence | Certainty |
|---|---|---|---|---|
| Identity data | [name, email, phone] | [file or document] | [import, schema field, form] | Confirmed / Indicator / Not available / External |
| Account data | [sessions, OAuth tokens] | | | |
| Behavioral data | [events, page views] | | | |
| Device/technical data | [IP, user agent] | | | |
| User-generated content | [messages, files] | | | |
| Transactional data | [payments, invoices] | | | |
| Special-category data | [health, biometrics] | | | |
| Data about minors | | | | |

---

## 4. Processing purposes

| Purpose | Data involved | Legal basis (if stated) | Evidence | Certainty |
|---|---|---|---|---|
| Core functionality | | | | |
| Authentication | | | | |
| Payments | | | | |
| Communications | | | | |
| Analytics | | | | |
| Marketing | | | | |
| Security and fraud prevention | | | | |
| AI/ML | | | | |
| Legal compliance | | | | |

---

## 5. Data-subject categories

- [End users, customers, prospects, employees, third parties, minors, etc.]

---

## 6. Services and third parties

| Service | Role (controller/processor/recipient) | Data involved | Evidence of use | Location/transfer | Certainty |
|---|---|---|---|---|---|
| [Stripe] | [processor] | [payment data] | [import + API route] | [US — mechanism] | Confirmed / Indicator |
| | | | | | |

---

## 7. Infrastructure and storage

| Component | Provider | Region | Data stored | Evidence | Certainty |
|---|---|---|---|---|---|
| Database | | | | | |
| Object storage | | | | | |
| Hosting | | | | | |
| Backups | | | | | |

---

## 8. Cookies and tracking analysis

| Cookie/tracker | Provider | Purpose | Category | Consent required | Lifetime | Disclosed | Evidence |
|---|---|---|---|---|---|---|---|
| | | | Strictly necessary / Analytics / Marketing | Yes/No/Assess by purpose | | Yes/No | |

**Notes:**

- [Consent mechanism observed, default state, withdrawal path, banner behavior.]
- [Cookies or storage not covered by the cookie documentation.]

---

## 9. Legal documentation analysis

### 9.1 Documents reviewed

- [Document, version/date, source.]

### 9.2 Key claims

- [What each document states about data, purposes, legal bases, recipients, transfers, retention and
  rights.]

### 9.3 Internal consistency

- [Contradictions or omissions between Privacy Policy, ToS, Cookie Policy and DPA.]

---

## 10. Code-vs-documentation comparison matrix

| Data practice detected in code | Privacy Policy | Cookie Policy | ToS / DPA | Status | Evidence |
|---|---|---|---|---|---|
| [Analytics events sent to PostHog] | [Not disclosed] | [Not disclosed] | [—] | [Gap] | [file:line] |
| [Stripe customer data] | [Disclosed as payment processor] | [—] | [—] | [Aligned] | [file:line] |
| [Data stored in Supabase eu-west-1] | [Region not stated] | [—] | [—] | [Partial] | [file:line] |

Status values: Aligned / Partial / Gap / Not verifiable.

---

## 11. Critical findings

### F-001 — [Short title]

- **Severity:** CRITICAL
- **Description:** [What the issue is.]
- **Evidence:** [Concrete observation, quoted code or document excerpt.]
- **File and location:** [path:line, where applicable.]
- **Affected document:** [Privacy Policy / ToS / Cookie Policy / DPA / multiple.]
- **Legal reference:** [GDPR article, LSSI-CE article, other applicable rule.]
- **Potential impact:** [Legal or regulatory exposure, stated proportionately.]
- **Recommendation:** [Specific fix or draft clause.]
- **Certainty:** [Confirmed / Indicator / Not available / External.]

*(Repeat for each critical finding.)*

---

## 12. Important findings

### F-0XX — [Short title]

- **Severity:** IMPORTANT
- **Description:**
- **Evidence:**
- **File and location:**
- **Affected document:**
- **Legal reference:**
- **Potential impact:**
- **Recommendation:**
- **Certainty:**

*(Repeat for each important finding.)*

---

## 13. Minor findings

### F-0XX — [Short title]

- **Severity:** MINOR
- **Description:**
- **Evidence:**
- **File and location:**
- **Affected document:**
- **Legal reference:** [Best practice or documentary-quality reference, where applicable.]
- **Potential impact:**
- **Recommendation:**
- **Certainty:**

*(Repeat for each minor finding.)*

---

## 14. GDPR checklist

| # | Requirement | Status | Notes |
|---|---|---|---|
| 1 | Identity and contact details of the controller | ✅ / ⚠️ / ❌ / N/A | |
| 2 | DPO contact details, only where a DPO has been designated | | |
| 3 | Purposes of processing | | |
| 4 | Legal basis per purpose | | |
| 5 | Legitimate interests specified where applicable | | |
| 6 | Recipients, distinguishing controller, processor and recipient | | |
| 7 | Third-country transfers and safeguards | | |
| 8 | Retention periods or criteria | | |
| 9 | Source of data where not collected directly | | |
| 10 | Right of access | | |
| 11 | Right to rectification | | |
| 12 | Right to erasure | | |
| 13 | Right to restriction | | |
| 14 | Right to portability | | |
| 15 | Right to object | | |
| 16 | Automated decision-making and profiling | | |
| 17 | How to exercise rights | | |
| 18 | Response deadline: one month, with legally provided extensions | | |
| 19 | Right to lodge a complaint | | |
| 20 | Consent validly obtained | | |
| 21 | Withdrawal as easy as giving consent | | |
| 22 | Separate consent per purpose | | |
| 23 | Age verification / parental consent where minors are involved | | |
| 24 | Special-category data identified | | |
| 25 | Art. 9(2) condition stated or verifiable | | |
| 26 | Data protection by design and by default | | |
| 27 | Record of processing activities (internal, where applicable) | | |
| 28 | Breach notification duties and procedure | | |
| 29 | DPA with processors | | |
| 30 | Security measures | | |
| 31 | Cookie categories listed | | |
| 32 | Consent for non-essential cookies assessed by purpose | | |
| 33 | Consent withdrawal | | |
| 34 | Third-party cookies and trackers disclosed | | |
| 35 | Cookie lifetime disclosed | | |
| 36 | Countries of transfer identified | | |
| 37 | Transfer mechanism stated | | |
| 38 | Additional safeguards assessed where required | | |

---

## 15. Prioritized recommendations

1. **[Critical]** [Action.]
2. **[Critical]** [Action.]
3. **[Important]** [Action.]
4. **[Important]** [Action.]
5. **[Minor]** [Action.]

---

## 16. Sources and legal references

| Source | URL | Date consulted |
|---|---|---|
| GDPR (Regulation (EU) 2016/679) | | |
| LOPDGDD (Organic Law 3/2018) | | |
| LSSI-CE (Law 34/2002) | | |
| [Other relevant guidance] | | |

---

*End of report. This document is an automated analysis and does not constitute legal advice or a
certification of compliance.*
