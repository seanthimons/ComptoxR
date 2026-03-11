# Phase 16: CI Fix - Context

**Gathered:** 2026-02-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the broken schema-check GitHub Action workflow by resolving the unicode_map dependency issue. `R/unicode_map.R` currently calls `usethis::use_data()` at source time, which fails during `pkgload::load_all()` in CI because `usethis` is not installed. The fix involves moving the data-generation script to `data-raw/`, shipping pre-built `sysdata.rda`, and ensuring the CI workflow can load the package cleanly.

</domain>

<decisions>
## Implementation Decisions

### Data packaging strategy
- unicode_map stays internal-only via `sysdata.rda` — not exported as a user-accessible dataset
- `data-raw/unicode_map.R` script uses `usethis::use_data(internal = TRUE)` to generate `sysdata.rda`
- CI generates sysdata.rda fresh by running the data-raw/ script (not committed to repo)
- `usethis` added to CI workflow's extra-packages list (`any::usethis`) to support fresh generation
- `R/unicode_map.R` is deleted cleanly — no migration comments, git history is sufficient

### Migration safety
- Existing tests for `clean_unicode()` and other consumers are sufficient to verify the migration — no new smoke test needed
- Verification done via local `pkgload::load_all()` test (not full workflow E2E run)
- sysdata.rda should normally already exist from developer running data-raw/ script
- If sysdata.rda is missing in CI, fall back to `source("data-raw/unicode_map.R")` to regenerate it before `load_all()`

### Claude's Discretion
- Exact workflow step ordering and fallback logic for missing sysdata.rda
- How data-raw/unicode_map.R script is structured internally (as long as it uses usethis::use_data)
- Any cleanup of existing workflow dependency list beyond adding usethis

</decisions>

<specifics>
## Specific Ideas

- User wants sysdata.rda to "already exist" in normal flow, with `source("data-raw/unicode_map.R")` as a safety net if it doesn't
- Clean delete of R/unicode_map.R — no backward compatibility shims

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 16-ci-fix*
*Context gathered: 2026-02-12*
