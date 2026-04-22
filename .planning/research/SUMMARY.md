# Project Research Summary

**Project:** ComptoxR v2.4 Source-Backed Lifestage Resolution
**Domain:** R package ETL + runtime enrichment with external ontology APIs
**Researched:** 2026-04-22
**Confidence:** HIGH

## Executive Summary

ComptoxR v2.4 replaces the v2.3 regex-first lifestage harmonization system with a
source-backed resolution pipeline that assigns real ontology identifiers (UBERON, PO, NERC
NVS S11) to each distinct ECOTOX lifestage term. The work is primarily a replacement of
existing behavior, not greenfield development: the shared helper layer
(`R/eco_lifestage_patch.R`) is already implemented and fully covers the resolution pipeline,
both build scripts already contain identical section 16 replacements, and the runtime join in
`eco_functions.R` already carries the new column structure. The primary challenge is
validation and wiring, not writing new code.

The recommended approach is sequenced around dependency order: confirm the shared helper
layer loads cleanly, verify that both committed data artifacts (`lifestage_baseline.csv` and
`lifestage_derivation.csv`) are complete and cross-checked against each other, then verify
the build script and runtime join correctness, and finally validate the in-place patch path
end-to-end. Zero new R package dependencies are required — the entire feature composes
existing `httr2`, `jsonlite`, `dplyr`, `stringr`, `DBI`, and `duckdb` infrastructure.

The dominant risks are Windows-specific (DuckDB file lock race on write connection open),
OLS4 API behavior quirks (cross-ontology term leakage, exact-match ranking not guaranteed),
and silent data gaps (derivation map misses sending resolved terms to quarantine). All three
risks have concrete mitigation strategies already identified: retry loop in the patch
function, post-filter by `obo_id` prefix on OLS4 results, and mandatory cross-check of
`lifestage_baseline.csv` rows against `lifestage_derivation.csv` before committing either
file.

---

## Key Findings

### Recommended Stack

The v2.4 feature requires **no changes to `DESCRIPTION`**. Every package needed is already
in `Imports`. The HTTP stack (`httr2` + `jsonlite`) handles OLS4 REST GET and NVS SPARQL
POST without any additional wrapper package. Cache I/O uses base R (`tools::R_user_dir()`,
`utils::read.csv()`, `utils::write.csv()`), which is correct for a CRAN-targeted package.
DuckDB write operations use the existing `DBI::dbWriteTable(..., overwrite = TRUE)` pattern
already established in the build scripts.

Packages explicitly evaluated and rejected: `rols` (deprecated Bioconductor, adds complexity
with no benefit over direct `httr2` calls), `memoise`/`cachem` (release-scoped CSV
invalidation covers all requirements without auto-pruning), `rappdirs` (superseded by
`tools::R_user_dir()` in base R since R 4.0), `ontologyIndex` (full OBO graph download is
overkill when only top-N API search is needed), `readr` (base R `utils::read.csv()` is
sufficient for a fixed flat schema).

**Core technologies:**
- `httr2` (1.2.1): OLS4 REST GET + NVS SPARQL POST — already used for all EPA API calls; no new patterns needed
- `jsonlite` (>=1.8.8): Parses both OLS4 `application/json` and NVS `application/sparql-results+json` responses
- `dplyr` (>=1.1.4): Score ranking, candidate deduplication, derivation join — already in `Imports`
- `purrr` (>=1.0.2): Sequential per-term live resolution loop via `map_dfr()` — must stay sequential; parallel risks OLS4 rate limits
- `stringr` (>=1.5.1): Term normalization, boundary regex matching in scoring layer
- `DBI` + `duckdb`: Read-write patch writes; single-writer constraint is the critical operating constraint
- `tools::R_user_dir()` (base R): CRAN-compliant cache directory; release-encoded filename provides automatic invalidation
- `utils::read.csv()` / `write.csv()` (base R): Flat fixed-schema CSV I/O for cache and baseline artifacts

**API details confirmed via live calls:**
- OLS4: `https://www.ebi.ac.uk/ols4/api/search` — no auth, GET, Solr-style JSON, `response.docs[]` per document
- NVS SPARQL: `https://vocab.nerc.ac.uk/sparql/sparql` — no auth, POST form body, SPARQL 1.1 JSON bindings; S11 collection covers ~130 marine/aquatic lifestage terms

### Expected Features

The v2.4 deliverable is a correctness replacement: v2.3's `ontology_id` column was fabricated
from manual regex classification with no real ontology backing. v2.4 replaces it with eight
traceable columns: `source_term_id`, `source_term_label`, `source_ontology`,
`source_match_status`, `source_match_method`, `harmonized_life_stage`, `reproductive_stage`,
and `derivation_source` — all backed by provider-issued identifiers and a curated derivation
map.

**Must have (table stakes for v2.4.0):**
- Tear out v2.3 regex classifier and `ontology_id` from all code paths — removes false provenance
- `lifestage_baseline.csv` committed to `inst/extdata/ecotox/` — cold-start capability; CI runs without live API
- `lifestage_derivation.csv` committed to `inst/extdata/ecotox/` — sole source of `harmonized_life_stage` values
- Build script section 16 replacement in both `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` — identical call sites
- `eco_results()` updated for 8-column output; `ontology_id` removed — API contract change
- All existing tests updated for new column schema
- `devtools::check()` passing at 0 errors, 0 new warnings

**Should have (quality gates for v2.4.x):**
- Mocked provider adapter tests using `testthat::with_mocked_bindings()` — CI-safe, no VCR cassettes for external ontology APIs
- `NEWS.md` breaking change documentation for `ontology_id` removal
- `dev/lifestage/` validation scripts updated for new column layout

**Defer to v2.5+:**
- NVS `owl:sameAs` to UBERON cross-reference extraction (triangulation confidence boost)
- Public `.eco_patch_lifestage()` API (currently internal-only by design)
- SPARQL-based OLS4 queries for structured ancestor traversal

### Architecture Approach

The architecture connects three already-implemented contexts through a single shared helper
layer: (1) the ETL build pipeline (`ecotox_build.R` / `data-raw/ecotox.R` section 16),
which creates the DB tables from scratch during a full ECOTOX build; (2) the in-place patch
path (`.eco_patch_lifestage()`), which updates an existing DB without a full rebuild; and
(3) the query-time runtime join in `.eco_enrich_metadata()`, which enriches `eco_results()`
output via a DuckDB join against the already-built `lifestage_dictionary` table. All three
share the 14-function helper layer in `R/eco_lifestage_patch.R`. The only architectural
constraint requiring care is DuckDB's single-writer model: the patch path must evict the
cached read-only connection before opening a write connection, and restore it afterward.

**Major components:**
1. `R/eco_lifestage_patch.R` — 14 internal functions: schema helpers, path/I/O, validation, cache read/write, seed resolution, text normalization and scoring, provider queries (OLS4 + NVS), ranking, output construction, table materialization, and patch entrypoint
2. `inst/extdata/ecotox/lifestage_baseline.csv` + `lifestage_derivation.csv` — committed data artifacts; baseline seeds user cache on cold start, derivation map drives all derived field population
3. Build script section 16 (both scripts, must be identical) — calls `.eco_lifestage_materialize_tables()` with `refresh="auto"`, writes `lifestage_dictionary` and `lifestage_review` via `DBI::dbWriteTable`
4. `.eco_enrich_metadata()` in `eco_functions.R` (lines 659-679) — runtime two-step join: `lifestage_codes` to `org_lifestage` description, then `lifestage_dictionary` on `org_lifestage` to expose 8 new columns
5. `R/eco_connection.R` — `.eco_close_con()` / `.eco_get_con()` pair manages the session cache; patch function depends on this contract remaining stable

### Critical Pitfalls

1. **DuckDB Windows write-connection race condition** — After `.eco_close_con()`, the Windows OS file lock may linger one OS tick after `shutdown = TRUE`. The subsequent `dbConnect(..., read_only = FALSE)` throws `IO Error: Cannot open file ... used by another process`. Mitigation: wrap the write-connection open in a retry loop (3 attempts, 200 ms back-off); always use `DBI::dbDisconnect(con, shutdown = TRUE)`.

2. **OLS4 returns cross-ontology terms (`local=true` ignored, issue #623)** — Queries against `uberon` receive CL, GO, and BFO terms in the result set. Mitigation: post-filter `docs` by `obo_id` prefix (`"UBERON:"` for UBERON queries, `"PO:"` for PO queries) before passing candidates to scoring. This must be verified in the provider query function.

3. **OLS4 relevance ranking does not guarantee exact match at position 1 (issue #860)** — Exact parent concept may rank below more-specific subclasses. Mitigation: the current design already scores all `rows=25` results; do not short-circuit on position 1. Verify this behavior is not inadvertently bypassed.

4. **Derivation map miss silently quarantines resolved terms** — A term that resolves cleanly to an ontology ID but has no row in `lifestage_derivation.csv` is routed to `lifestage_review` rather than `lifestage_dictionary`. Mitigation: cross-check every resolved entry in `lifestage_baseline.csv` against `lifestage_derivation.csv` before committing either file. The two artifacts must be built and verified together.

5. **Build script section 16 drift** — Modifying one build script without updating the other produces different lifestage tables from build vs. patch paths. Mitigation: add a CI diff check (or test assertion) that fails if section 16 of `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` diverge.

---

## Implications for Roadmap

The research reveals this milestone is primarily a validation and wiring task, not a build
task. The code is already written. The risk is in verification order and data artifact
completeness. Phase structure follows the dependency chain: helpers must work before build
scripts can call them, data artifacts must be complete before patch can produce correct
output, and the runtime join must be verified against a correctly-patched DB.

### Phase 1: Shared Helper Layer Validation

**Rationale:** All other phases depend on `R/eco_lifestage_patch.R` loading without errors
and its 14 functions behaving as documented. This must be confirmed before anything else.
**Delivers:** Confirmed `devtools::load_all()` loads cleanly; schema functions return correct
zero-row tibbles; OLS4 and NVS query functions return correct response shapes; scoring layer
evaluates all candidates with correct tier thresholds; `obo_id` prefix filter present in OLS4
query function.
**Addresses:** Shared helper layer correctness (table stakes foundation for all features)
**Avoids:** OLS4 cross-ontology hits (Pitfall 2), OLS4 ranking trust (Pitfall 3), NVS endpoint failure graceful degradation
**Research flag:** Standard patterns — no additional research phase needed; implementation already exists on disk

### Phase 2: Bootstrap Data Artifacts

**Rationale:** `lifestage_baseline.csv` and `lifestage_derivation.csv` are the two committed
data files that all resolution paths depend on. They must be complete, mutually consistent,
and verified to be included in the installed package.
**Delivers:** Committed baseline CSV covering current ECOTOX release (13-column cache schema,
all distinct `lifestage_codes.description` values); committed derivation map (5-column schema,
covering all resolved entries in the baseline); both verified present via `devtools::check()`
installed file listing.
**Addresses:** Cold-start capability (table stakes), derivation map completeness (differentiator)
**Avoids:** Derivation map miss (Pitfall 4), `system.file()` silent empty string (Pitfall 9 in PITFALLS.md)
**Research flag:** Human curation required — the cross-check between baseline and derivation map is a data-curation task; plan explicit acceptance criteria (every `resolved` baseline row has a matching derivation row)

### Phase 3: Build Script Integration

**Rationale:** Verify section 16 in both build scripts calls the shared helper correctly and
identically. This is the integration point where ETL build output and patch output converge.
**Delivers:** Both section 16 call sites confirmed identical; a diff check (test or CI
assertion) added; a full build produces a `lifestage_dictionary` that matches what
`.eco_patch_lifestage()` would produce for the same release.
**Addresses:** Section 16 sync requirement (table stakes)
**Avoids:** Build script drift (Pitfall 5 above / Pitfall 7 in PITFALLS.md)
**Research flag:** Standard patterns — diff check is mechanical; no research needed

### Phase 4: In-Place Patch Function Validation

**Rationale:** `.eco_patch_lifestage()` is the most complex execution path because it
coordinates the DuckDB connection lifecycle, writes two tables and `_metadata`, and must
return a correct completeness count. Windows-specific retry logic must be validated here.
**Delivers:** Confirmed patch function behavior: closes and reopens connections correctly;
retry loop present for Windows write-connection race; post-patch completeness check passes
(dictionary + review row count equals distinct `lifestage_codes` description count); patch
metadata written correctly; four refresh modes cascade as documented.
**Addresses:** In-place patch capability (differentiator), four refresh modes (differentiator)
**Avoids:** Windows write-connection race (Pitfall 1), stale cached connection (Pitfall 2 in PITFALLS.md), cross-release cache contamination (Pitfall 6 in PITFALLS.md)
**Research flag:** Platform-specific validation required — the DuckDB file lock race is Windows-specific; must be tested on Windows, not just macOS/Linux

### Phase 5: Runtime Join and API Contract Finalization

**Rationale:** The runtime join in `eco_results()` is the user-facing surface of all prior
work. After Phase 4 confirms a correctly-patched DB, this phase verifies that `eco_results()`
returns the new 8-column output, that `ontology_id` is absent, and that all existing tests
are updated for the new schema.
**Delivers:** `eco_results()` output contains all 8 new lifestage columns after
`organism_lifestage`; `ontology_id` absent from all output; all existing test assertions
updated; `devtools::check()` at 0 errors, 0 new warnings.
**Addresses:** API contract change (table stakes), `eco_results()` column update (P1 from FEATURES.md), test schema updates
**Avoids:** Runtime join to `lifestage_review` (anti-pattern 4 in ARCHITECTURE.md)
**Research flag:** Standard patterns — join structure is already implemented; validation is mechanical

### Phase 6: Quality Gates and Documentation

**Rationale:** After integration passes, add mocked provider tests for CI safety, document
the breaking `ontology_id` removal, and update `dev/lifestage/` scripts.
**Delivers:** `testthat::with_mocked_bindings()` unit tests for OLS4 and NVS adapters;
`NEWS.md` entry for `ontology_id` removal as a breaking change; `dev/lifestage/confirm_gate.R`
and `validate_lifestage.R` updated for new column layout.
**Addresses:** Mocked provider tests (P2), NEWS.md breaking change (P2), dev scripts (P2)
**Avoids:** VCR cassette brittleness for external ontology APIs (anti-feature from FEATURES.md)
**Research flag:** Standard patterns — `with_mocked_bindings()` is well-documented in testthat; no research needed

### Phase Ordering Rationale

- Phase 1 before Phase 2: Cannot validate data artifacts without confirming schema functions return correct shapes
- Phase 2 before Phase 3: Build script section 16 needs complete baseline/derivation artifacts to produce a verifiable `lifestage_dictionary`
- Phase 3 before Phase 4: In-place patch and full build must produce equivalent tables; this equivalence can only be asserted after Phase 3 is verified
- Phase 4 before Phase 5: Runtime join validation requires a correctly-patched DB to query against
- Phase 6 last: Quality gates and docs are polish; no other phase depends on them

### Research Flags

Phases needing extra care during planning (human-intensive verification, not additional research):
- **Phase 2 (Bootstrap Data Artifacts):** The baseline CSV / derivation map cross-check is manual data curation. Plan explicit acceptance criteria: every `resolved` row in the baseline must have a matching `(source_ontology, source_term_id)` row in the derivation map before either file is committed.
- **Phase 4 (Patch Function Validation):** The Windows DuckDB write-connection retry loop must be tested on Windows. The failure mode (`IO Error: Cannot open file ... used by another process`) only reproduces on Windows; do not rely on macOS/Linux test runs for this acceptance criterion.

Phases with standard patterns (verification is mechanical):
- **Phase 1:** `devtools::load_all()` + function existence + output shape assertions
- **Phase 3:** `diff` of section 16 in both build scripts returns 0 differences
- **Phase 5:** Column presence/absence assertions in existing test suite
- **Phase 6:** Standard `testthat::with_mocked_bindings()` test setup

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Both external APIs verified via live calls; all packages already in `Imports`; rejected packages evaluated with specific rationale tied to CRAN policy and deprecation records |
| Features | HIGH | API response schemas confirmed field-by-field via live calls; UBERON `obo_id` values verified; S11 SKOS fields verified against real term (S1130 nauplius) |
| Architecture | HIGH | Implementation already exists on disk; component boundaries derived from reading actual source files (`eco_lifestage_patch.R` 926 lines, `eco_functions.R` lines 659-679); not speculative |
| Pitfalls | HIGH | All 10 pitfalls backed by specific GitHub issues (OLS4 #623, #860; DuckDB-R #56, #17418), DuckDB concurrency docs, and project-specific CLAUDE.md platform guidance |

**Overall confidence:** HIGH

### Gaps to Address

- **OLS4 rate limiting:** No published rate limit found for EMBL-EBI OLS4. The conservative sequential request strategy (one per term, no parallelism) is correct and sufficient. If live resolution time becomes a user complaint, empirical rate limit discovery would be needed.
- **NVS SPARQL endpoint SLA:** BODC does not publish an uptime SLA. The existence of the ARGO monitoring probe confirms known availability concerns. Graceful fallback to empty index with `cli_warn()` (rather than abort) is specified and must be verified in Phase 1.
- **Windows retry timing:** The 200 ms back-off for the DuckDB write-connection retry is a community-derived heuristic, not a vendor-specified value. If Phase 4 testing reveals it is insufficient, increase incrementally (try 500 ms / 5 attempts before escalating).
- **ECOTOX release string uniqueness:** The release ID is derived from ZIP filename, not a content hash. If ECOTOX posts a corrected build with the same date code, the cache would be reused without detection. The post-patch completeness check (row count parity between dictionary + review and distinct `lifestage_codes`) partially mitigates this but does not catch value-level differences within existing terms.

---

## Sources

### Primary (HIGH confidence — verified via live API calls or official documentation)
- OLS4 production API: `https://www.ebi.ac.uk/ols4/api/search` — response envelope, per-doc fields, pagination params
- OLS4 paper: [PMC12094816](https://pmc.ncbi.nlm.nih.gov/articles/PMC12094816/) — architecture, deployment scale
- OLS4 GitHub: [EBISPOT/ols4](https://github.com/EBISPOT/ols4) — issues #623 (`local=true` ignored) and #860 (relevance ranking)
- NVS SPARQL endpoint: `https://vocab.nerc.ac.uk/sparql/sparql` — SPARQL 1.1 JSON bindings format confirmed
- NVS S11 collection: `https://vocab.nerc.ac.uk/collection/S11/current/` — term S1130 (nauplius) JSON-LD field structure verified
- DuckDB concurrency docs: `https://duckdb.org/docs/current/connect/concurrency` — single-writer model
- DuckDB issue #17418: Windows `BufferedFileWriter` exclusive lock behavior
- R-hub caching blog: `https://blog.r-hub.io/2021/07/30/cache/` — `tools::R_user_dir()` as CRAN-compliant cache location
- R Packages (2e): `https://r-pkgs.org/data.html` — `inst/extdata` + `system.file()` patterns
- ComptoxR source (as of 2026-04-22): `R/eco_lifestage_patch.R` (926 lines), `R/eco_connection.R`, `R/eco_functions.R` (lines 659-679), `inst/ecotox/ecotox_build.R` (lines 974-1023), `data-raw/ecotox.R` (lines 975-1024)

### Secondary (MEDIUM confidence)
- ARGO NVS SPARQL probe: [ARGOeu/sdc-nerc-spqrql](https://github.com/ARGOeu/sdc-nerc-spqrql) — confirms NVS availability monitoring exists; infers availability concerns are real
- DuckDB R issue #56: Windows "used by another process" error pattern and retry workaround community reports
- Bioconductor removed packages page: `rols` deprecated status in 3.23 confirmed

### Tertiary (LOW confidence — heuristics only)
- OLS4 rate limiting: no published limit found; 200 ms sequential delay is a conservative heuristic derived from general API etiquette
- NVS SPARQL rate limiting: no published limit; single full-collection fetch per session mitigates exposure
- Windows DuckDB retry timing: 200 ms / 3 attempts derived from DuckDB community issue reports, not a vendor specification

---

*Research completed: 2026-04-22*
*Ready for roadmap: yes*
