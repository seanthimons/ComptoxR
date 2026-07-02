# Technology Stack

**Project:** ComptoxR v2.4 Source-Backed Lifestage Resolution
**Researched:** 2026-04-22
**Milestone context:** Replacing v2.3 regex-first lifestage harmonization with source-backed
ontology resolution via OLS4 (UBERON, PO) and NERC NVS (BODC S11).

---

## Executive Summary

The v2.4 implementation requires **zero new R package dependencies**. Every capability
needed — HTTP requests, JSON parsing, string manipulation, disk caching, CSV I/O — is
already present in the existing `Imports` and base R. The new work consists entirely of
new R source files that compose existing tools in a new way.

The core HTTP stack (`httr2` + `jsonlite`) handles both external ontology APIs with no
code changes. The cache layer uses `tools::R_user_dir()` (base R, R >= 4.0) and
`utils::read.csv()` / `utils::write.csv()` (base R), deliberately avoiding new
dependencies. `purrr::map_dfr()` handles the per-term live resolution loop.
`dplyr`, `tibble`, `stringr`, and `rlang` handle ranking, normalization, and schema
enforcement. All of these are already in `Imports`.

The one area to confirm before implementation: `httr2::req_retry()` behavior against
the EMBL-EBI OLS4 API when it returns 429 or 503 (no documented rate limit — treat
conservatively with short delays between per-term requests).

---

## Core Stack (Existing — No Changes to DESCRIPTION)

All packages listed below are already in `Imports` in DESCRIPTION.

### HTTP Client

| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| httr2 | 1.2.1 | OLS4 REST GET and NVS SPARQL POST | Already used for all EPA API calls; pipeable `request()` → `req_perform()` → `resp_body_json()` pattern maps directly to both OLS4 and NVS endpoints. No wrapper package needed. |
| jsonlite | >= 1.8.8 | Parse OLS4 and NVS SPARQL JSON responses | OLS4 returns `application/json`, NVS SPARQL returns `application/sparql-results+json`. `jsonlite::fromJSON(simplifyDataFrame=TRUE)` normalizes both to data frames. |

**OLS4 API (EMBL-EBI):**
- Base URL: `https://www.ebi.ac.uk/ols4/api/search`
- Key parameters: `q` (term text), `ontology` (e.g., `uberon`, `po`), `rows` (result count)
- Response fields per document: `iri`, `obo_id`, `label`, `short_form`, `description` (array), `exact_synonyms` (array), `ontology_name`
- Authentication: None required. Publicly open API, no API key.
- Rate limiting: Not publicly documented. Conservative practice: process terms
  sequentially (one request per term), not in parallel batches.
- Confidence: HIGH (verified via live API call; confirmed in OLS4 publication, PMC12094816)

**NVS SPARQL endpoint:**
- URL: `https://vocab.nerc.ac.uk/sparql/sparql`
- Method: POST with `query=` form body, `Accept: application/sparql-results+json`
- Query pattern: SPARQL SELECT over `http://vocab.nerc.ac.uk/collection/S11/current/`
  filtered by REGEX on term URIs
- Response: SPARQL bindings JSON with `results.bindings[]` containing `term.value`,
  `label.value`, `altLabel.value`, `definition.value`
- Authentication: None required. Publicly open.
- Confidence: HIGH (verified via live API call; NVS documentation confirms SPARQL endpoint)

**NVS index strategy:** The implementation fetches the entire S11 collection once via
SPARQL on first use, caches the resulting data frame in `.ComptoxREnv$eco_lifestage_nvs_index`
for the session, then filters locally per term. This avoids one HTTP request per term for
NVS while keeping OLS4 per-term (since OLS4 search is keyword-based and term-specific).

### Data Manipulation

| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| dplyr | >= 1.1.4 | Score ranking, candidate deduplication, schema enforcement, join for derivation map | Already in Imports; `arrange()`, `filter()`, `mutate()`, `left_join()`, `group_by()`, `slice()` all used in ranking pipeline. |
| tibble | (installed) | Schema enforcement tibbles, typed empty frames | `tibble::tibble()` for schema definitions; `tibble::as_tibble()` for coercion. |
| purrr | >= 1.0.2 | Per-term live resolution loop, candidate scoring map | `purrr::map_dfr()` over missing terms for live lookup; `purrr::pmap_dfr()` over candidates for scoring. |
| tidyr | >= 1.3.1 | Not required for v2.4 lifestage path | No unnesting needed; data stays flat. |

### String Normalization

| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| stringr | >= 1.5.1 | Term normalization (whitespace, punctuation, plural stripping), boundary regex matching | `str_replace_all()`, `str_detect()`, `regex()`, `fixed()` all used in `.eco_lifestage_normalize_term()` and scoring. |
| stringi | (installed) | Unicode handling (dependency of stringr) | Indirectly used; no direct calls needed. |

### Package Infrastructure

| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| rlang | (installed) | `arg_match()` for refresh mode validation | `.eco_lifestage_load_seed_cache()` and `.eco_patch_lifestage()` use `rlang::arg_match()` for safe enum validation. |
| cli | (installed) | User-facing messages, warnings, abort | `cli_alert_info()`, `cli_alert_warning()`, `cli_abort()` throughout patch and build paths. |

### Storage and I/O

| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| DBI | (installed) | Read-write DuckDB connection management | `.eco_patch_lifestage()` opens `read_only=FALSE` connection, writes tables, disconnects. `dbWriteTable()` with `overwrite=TRUE`. |
| duckdb | (installed) | Local ECOTOX database engine | Existing; lifestage tables are written directly into `ecotox.duckdb`. |
| base R utils | (always available) | CSV I/O for user cache and baseline | `utils::read.csv()` and `utils::write.csv()` handle the cache CSV. No `readr` needed — base R avoids a dependency. |
| base R tools | (always available) | User cache directory path | `tools::R_user_dir("ComptoxR", "cache")` returns the platform-appropriate cache directory (R >= 4.0). CRAN-safe — does not write to home directory. |

**Cache path strategy (HIGH confidence):**
`tools::R_user_dir()` is the correct choice over `rappdirs`:
- Available in base R since R 4.0 (no extra dependency)
- R-namespaced paths (avoids CRAN policy violations from writing to `~/.cache/`)
- Environment variable override via `R_USER_CACHE_DIR` for CI/testing

**Baseline CSV location:**
`inst/extdata/ecotox/lifestage_baseline.csv` — accessed via `system.file()` after
installation and directly via relative path during development. Uses the same 13-column
normalized cache schema so a single reader function handles both.

---

## Packages Evaluated and Rejected

### `rols` (Bioconductor)
**Decision: DO NOT USE**

`rols` is a Bioconductor package providing an R interface to OLS4. It uses `httr2`
internally and was updated to OLS4 in version 2.99+. However:
- Bioconductor-only (not on CRAN); adds `BiocManager` installation requirement
- Deprecated in Bioconductor 3.23, removed from 3.22 release (last stable: 3.21)
- Adding a deprecated Bioconductor dependency to a CRAN-targeted package is a
  maintenance liability
- The OLS4 API is simple enough (single GET endpoint, flat JSON response) that
  `httr2::request()` + `jsonlite::fromJSON()` achieves the same result in ~10 lines

Use direct `httr2` calls instead. This is what the existing `eco_lifestage_patch.R`
already does.

### `memoise` + `cachem` (CRAN)
**Decision: DO NOT USE**

`memoise` + `cachem::cache_disk()` is the standard pattern for function-level disk
memoization in R packages. However, v2.4 requires a release-scoped cache that must:
- Be keyed by ECOTOX release string (not function arguments alone)
- Be readable/writable as a CSV for human review and committed baseline comparison
- Survive R session restarts
- Support explicit invalidation (`refresh = "live"`)

A plain CSV file in `tools::R_user_dir("ComptoxR", "cache")` provides all of this with
zero new dependencies. `memoise`'s auto-pruning and key-based expiry are not needed
here; release scoping replaces them. Avoid the dependency.

### `rappdirs` (CRAN)
**Decision: DO NOT USE**

`rappdirs::user_cache_dir()` does the same job as `tools::R_user_dir()` but adds a
dependency and has triggered CRAN policy warnings for some packages (writing to
`~/.cache/` in user home space). `tools::R_user_dir()` is base R since R 4.0 and is
R-namespaced. Use it.

### `ontologyIndex` (CRAN)
**Decision: DO NOT USE for v2.4**

`ontologyIndex` reads entire ontology OBO files into R lists. Useful for working with
full ontology graphs offline. In v2.4, only search-by-term against OLS4 is needed —
the scoring logic operates on the API's top-N result set, not the full graph. Adding a
200MB+ OBO download at package build time would be inappropriate.

### `readr` (in Suggests)
**Decision: Use base R `utils::read.csv()` instead**

`readr` is already in `Suggests` for other purposes. However, `readr::read_csv()` is
not needed for the cache CSV: `utils::read.csv()` is sufficient (the cache schema is
fixed and flat, not requiring type inference). Using base R avoids making `readr` a
harder dependency for this path.

---

## API Details

### OLS4 (EMBL-EBI Ontology Lookup Service v4)

| Property | Value |
|----------|-------|
| Base URL | `https://www.ebi.ac.uk/ols4/api/search` |
| Method | GET |
| Authentication | None |
| Key query params | `q` (term), `ontology` (comma-separated, lowercase), `rows` (int, default 10, max ~1000) |
| Response format | `application/json` |
| Top-level keys | `response.docs[]`, `response.numFound`, `response.start`, `facet_counts` |
| Per-document fields | `iri`, `obo_id`, `short_form`, `label`, `description` (array), `exact_synonyms` (array), `narrow_synonyms` (array), `ontology_name`, `type` |
| Rate limit | Not publicly documented; no API key required |
| Reliability | HIGH: 50M requests/3 months from 200K hosts as of early 2024; production EMBL-EBI service |

UBERON example: `GET https://www.ebi.ac.uk/ols4/api/search?q=larva&ontology=uberon&rows=25`
PO example: `GET https://www.ebi.ac.uk/ols4/api/search?q=seedling&ontology=po&rows=25`

### NERC NVS SPARQL (BODC S11 Collection)

| Property | Value |
|----------|-------|
| SPARQL endpoint | `https://vocab.nerc.ac.uk/sparql/sparql` |
| Method | POST (form body with `query=` parameter) |
| Authentication | None |
| Accept header | `application/sparql-results+json` |
| Response format | SPARQL 1.1 JSON Results format: `{results: {bindings: [{term: {value:...}, label: {value:...}, ...}]}}` |
| Collection | S11 — "Development stage of a biological entity" (marine/aquatic focus) |
| Term ID pattern | `http://vocab.nerc.ac.uk/collection/S11/current/S{4digits}/` |
| Reliability | HIGH: BODC/UKRI-funded, CC BY 4.0 licensed |

The S11 collection covers aquatic organism life stages: `praniza`, `yolk-sac larva`,
`nectochaeta`, `sporocyst`, `tornaria`, `embryo`, `nauplius N1`, `zoea`, `megalopa`
and ~40+ more terms. Fetched once per session via full SPARQL SELECT.

---

## Integration Points with Existing Stack

### With `generic_request()` in `z_generic_request.R`
The lifestage resolution functions do **not** use `generic_request()`. They call
`httr2::request()` directly. This is correct — `generic_request()` is designed for
CompTox Dashboard API endpoints that require an `x-api-key` header and EPA-specific
batching logic. OLS4 and NVS are public, unauthenticated, and have different
response shapes.

### With DuckDB connection management
`.eco_patch_lifestage()` calls `.eco_close_con()` before and after patching to avoid
DuckDB's single-writer lock conflict with the existing read-only cached connection used
by `eco_results()`. This is the same connection management pattern already used in the
ECOTOX build scripts.

### With `.ComptoxREnv` session cache
The NVS S11 index (all ~60 terms) is fetched once and stored in
`.ComptoxREnv$eco_lifestage_nvs_index`. OLS4 results are not session-cached (they are
per-term and term-specific; session caching adds complexity without benefit since
live lookups only happen during build/patch, not query time).

### With `inst/extdata/ecotox/` baseline files
Two committed CSV files are included:
1. `lifestage_baseline.csv` — 13-column normalized cache schema, covers one ECOTOX
   release, enables cold-start without live lookup.
2. `lifestage_derivation.csv` — 5-column curated mapping from `source_ontology` +
   `source_term_id` to `harmonized_life_stage`, `reproductive_stage`, `derivation_source`.

Both are accessed via `system.file()` after installation and directly via relative
`inst/` path during development. No new file format or I/O package needed.

---

## What NOT to Add

| Package | Reason to Avoid |
|---------|-----------------|
| `rols` | Deprecated in Bioconductor 3.23; Bioconductor-only; simpler direct httr2 calls are already implemented |
| `memoise` | Not needed; release-scoped CSV cache handles all invalidation requirements without auto-pruning |
| `cachem` | Not needed; same reason as memoise |
| `rappdirs` | Not needed; `tools::R_user_dir()` (base R, R >= 4.0) is cleaner and CRAN-safe |
| `ontologyIndex` | Overkill; full OBO graph download unneeded when only top-N API search results are scored |
| `readr` | Not needed for cache CSV; `utils::read.csv()` sufficient for fixed-schema flat file |
| `BiocManager` | Would be required to install rols; avoid Bioconductor dependency entirely |
| Parallel execution | `purrr::map_dfr()` sequential is correct; parallel term resolution risks overwhelming OLS4 and is unnecessary for the ~100-200 distinct ECOTOX lifestage terms |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| OLS4 API (no auth, endpoint, response shape) | HIGH | Verified via live API call; confirmed in PMC12094816 and OLS4 paper |
| NVS SPARQL (S11 collection, JSON format) | HIGH | Verified via live API call; NVS documentation confirms endpoint |
| `tools::R_user_dir()` for cache | HIGH | Base R since 4.0; CRAN-safe; used in existing `eco_lifestage_patch.R` |
| `utils::read.csv()` / `write.csv()` for cache CSV | HIGH | Base R; used in existing `eco_lifestage_patch.R` |
| rols deprecation status | HIGH | Bioconductor removed-packages page confirms deprecated in 3.23 |
| OLS4 rate limiting | LOW | No published rate limit found; conservative sequential-only approach mitigates risk |
| NVS SPARQL rate limiting | LOW | No published rate limit found; full collection is fetched once per session (mitigated) |

---

## Sources

- OLS4 production API: [https://www.ebi.ac.uk/ols4/api/search](https://www.ebi.ac.uk/ols4/api/search)
- OLS4 paper: [OLS4: a new Ontology Lookup Service — PMC12094816](https://pmc.ncbi.nlm.nih.gov/articles/PMC12094816/)
- OLS4 GitHub: [https://github.com/EBISPOT/ols4](https://github.com/EBISPOT/ols4)
- UBERON on OLS4: [https://www.ebi.ac.uk/ols4/ontologies/uberon](https://www.ebi.ac.uk/ols4/ontologies/uberon)
- Plant Ontology on OLS4: [https://www.ebi.ac.uk/ols4/ontologies/po](https://www.ebi.ac.uk/ols4/ontologies/po)
- NVS SPARQL endpoint: [https://vocab.nerc.ac.uk/sparql/](https://vocab.nerc.ac.uk/sparql/)
- NVS S11 collection: [https://vocab.nerc.ac.uk/collection/S11/current/](https://vocab.nerc.ac.uk/collection/S11/current/)
- NVS S11 GitHub: [https://github.com/nvs-vocabs/S11](https://github.com/nvs-vocabs/S11)
- NVS Swagger API docs: [https://vocab.nerc.ac.uk/doc/api](https://vocab.nerc.ac.uk/doc/api)
- rols Bioconductor page: [https://www.bioconductor.org/packages/release/bioc/html/rols.html](https://www.bioconductor.org/packages/release/bioc/html/rols.html)
- R-hub caching blog: [https://blog.r-hub.io/2021/07/30/cache/](https://blog.r-hub.io/2021/07/30/cache/)
- rappdirs vs tools::R_user_dir: [https://blog.r-hub.io/2020/03/12/user-preferences/](https://blog.r-hub.io/2020/03/12/user-preferences/)
- memoise package: [https://memoise.r-lib.org/](https://memoise.r-lib.org/)

---

**Last Updated:** 2026-04-22
**Overall Confidence:** HIGH — No new dependencies needed. Both APIs are public and
verified. All implementation patterns already exist in `R/eco_lifestage_patch.R`.
