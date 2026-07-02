---
phase: 36
slug: bootstrap-data-artifacts
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-23
---

# Phase 36 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| None | No trust boundaries crossed. Phase modifies committed CSV data files, creates test files, and creates dev-only scripts. No network endpoints, no user input handling, no auth changes, no runtime code modifications. | N/A |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-36-01 | Tampering | lifestage_derivation.csv | accept | Hand-authored rows follow existing pattern. File is committed to git with full version history. CI gate (test-eco_lifestage_data.R) detects schema violations on every push. | closed |
| T-36-02 | Information Disclosure | lifestage_baseline.csv | accept | Contains only public ECOTOX lifestage descriptions and ontology IDs. No PII, no secrets, no API keys. | closed |
| T-36-03 | Tampering | refresh_baseline.R | accept | Script is a dev tool, not shipped with the package. Writes only to package source files under git version control. Never auto-commits derivation rows (D-02). | closed |
| T-36-04 | Information Disclosure | validate_36.R DB access | accept | Opens DB read-only. No data leaves the local machine. DB path resolved via R_user_dir, not hardcoded. | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-36-01 | T-36-01 | CSV data is public ECOTOX ontology mappings under git version control with CI gate enforcement | gsd-secure-phase | 2026-04-23 |
| AR-36-02 | T-36-02 | Baseline contains only publicly available EPA ECOTOX data — no sensitive information | gsd-secure-phase | 2026-04-23 |
| AR-36-03 | T-36-03 | Dev-only script not included in package distribution; all writes are to git-tracked source files | gsd-secure-phase | 2026-04-23 |
| AR-36-04 | T-36-04 | Read-only DB access to local user-directory database; no network exfiltration path | gsd-secure-phase | 2026-04-23 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-23 | 4 | 4 | 0 | gsd-secure-phase |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-23
