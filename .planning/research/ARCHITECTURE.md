# Architecture Patterns: ECOTOX Source-Backed Lifestage Resolution

**Domain:** R package ECOTOX ETL and runtime enrichment
**Researched:** 2026-04-22
**Milestone:** v2.4 Source-Backed Lifestage Resolution

## Executive Summary

The v2.4 lifestage resolution system integrates three contexts that share a single helper
layer: the ETL build pipeline, the in-place patch path, and the query-time runtime join in
`eco_results()`. All three contexts already exist on disk in their target form — the shared
helper file `R/eco_lifestage_patch.R` is fully implemented, both build scripts have
identical section 16 replacements, and `eco_functions.R` already carries the new join
structure. The primary architectural challenge is therefore not "what to build" but "in what
order to validate and wire together what already exists."

The central connection management constraint is that DuckDB allows only one active
connection per file when write access is involved. The patch path must close the package's
cached read-only connection before opening a read-write connection, and must relinquish
the read-write connection before the cached handle can be reinstated. The existing
`.eco_close_con()` / `.eco_get_con()` pair in `eco_connection.R` already supports this
protocol; `.eco_patch_lifestage()` calls `.eco_close_con()` before opening its own
connection and again via `on.exit()` after disconnecting, so the next normal query gets
a fresh cached handle automatically.

The build pipeline (both `inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R`) never
holds a cached read-only connection — it manages its own `eco_con` handle — so it opens
a standard read-write connection throughout the ETL and writes `lifestage_dictionary` and
`lifestage_review` exactly like any other build-time table.

## Component Boundaries

### Existing Components — No Changes Required

| Component | File | Responsibility | Status |
|-----------|------|---------------|--------|
| Connection cache | `R/eco_connection.R` | Manages read-only cached `ecotox_db` in `.ComptoxREnv`, exposes `.eco_get_con()` / `.eco_close_con()` | Stable — v2.3 shipped |
| DB path resolver | `R/eco_connection.R` — `eco_path()` | Returns `tools::R_user_dir("ComptoxR","data")/ecotox.duckdb` or option override | Stable |
| Query pipeline | `R/eco_functions.R` — `.eco_base_query()` / `.eco_apply_conversions()` / `.eco_post_process()` | Build and execute the DuckDB query chain | Stable |
| Baseline CSV | `inst/extdata/ecotox/lifestage_baseline.csv` | Committed seed covering one ECOTOX release; 13-column cache schema | In place |
| Derivation map | `inst/extdata/ecotox/lifestage_derivation.csv` | Curated `source_ontology + source_term_id` → harmonized fields lookup | In place |

### Existing Components — Already Modified for v2.4

| Component | File | Change | Verification Needed |
|-----------|------|--------|---------------------|
| Runtime enrichment join | `R/eco_functions.R` — `.eco_enrich_metadata()` (lines 659-679) | Replaced v2.3 `ontology_id` join with two-step join: `lifestage_codes` then `lifestage_dictionary` on `org_lifestage`; relocates 8 new source columns | Confirm column order and that `ontology_id` is absent from output |
| roxygen docs | `R/eco_functions.R` — `eco_results()` (lines 247-265) | Documents 8 new `@return` fields; `ontology_id` removed | Confirm `man/eco_results.Rd` regenerates cleanly |
| Build section 16 — install | `inst/ecotox/ecotox_build.R` (lines 974-1023) | Replaces v2.3 tribble with shared helper call pattern | Confirm identical to `data-raw/ecotox.R` section 16 |
| Build section 16 — dev | `data-raw/ecotox.R` (lines 975-1024) | Mirror of above | Confirm identical to `inst/ecotox/ecotox_build.R` section 16 |

### New Component — Fully Implemented

| Component | File | Responsibility |
|-----------|------|---------------|
| Shared helper layer | `R/eco_lifestage_patch.R` | 14 internal functions covering cache I/O, baseline loading, OLS4/NVS provider queries, scoring, ranking, table materialization, and in-place DB patching |

## Data Flow

### Build Path (Full ETL)

```
ecotox_build.R / data-raw/ecotox.R
  |
  | 1. ETL creates eco_con (read-write, not cached)
  | 2. Section 16: check helper availability
  |      if .eco_lifestage_materialize_tables() not in scope:
  |        source("R/eco_lifestage_patch.R", local = env)  [dev checkout]
  |        OR copy from ComptoxR namespace                  [installed pkg]
  | 3. Query: SELECT DISTINCT description FROM lifestage_codes
  | 4. Compute ecotox_release via .eco_lifestage_release_id(latest_zip)
  | 5. Call .eco_lifestage_materialize_tables(
  |      org_lifestages, ecotox_release, refresh="auto", write_cache=TRUE)
  |       |
  |       | -> .eco_lifestage_load_seed_cache()   [cache / baseline / live]
  |       | -> live: .eco_lifestage_resolve_term() per missing term
  |       |     -> .eco_lifestage_query_ols4("UBERON")
  |       |     -> .eco_lifestage_query_ols4("PO")
  |       |     -> .eco_lifestage_query_nvs()  [uses .ComptoxREnv NVS index]
  |       |     -> .eco_lifestage_rank_candidates()
  |       | -> .eco_lifestage_cache_write()
  |       | -> .eco_lifestage_derive_fields()   [join derivation CSV]
  |       | -> returns list(cache, dictionary, review, refresh_mode)
  | 6. DBI::dbWriteTable eco_con "lifestage_dictionary" overwrite=TRUE
  | 7. DBI::dbWriteTable eco_con "lifestage_review"     overwrite=TRUE
  | 8. cli warning if review rows > 0
  v
  ecotox.duckdb written by normal ETL shutdown
```

### Patch Path (In-Place Update)

```
.eco_patch_lifestage(db_path, refresh, force)
  |
  | 1. Validate db_path exists
  | 2. .eco_close_con()  — evict cached read-only handle
  | 3. DBI::dbConnect(duckdb, dbdir=db_path, read_only=FALSE)  — read-write
  | 4. on.exit: disconnect + .eco_close_con()
  | 5. Safety checks:
  |      _metadata exists and has ecotox_release key
  |      lifestage_codes exists with description column
  | 6. Query: SELECT DISTINCT description FROM lifestage_codes
  | 7. .eco_lifestage_materialize_tables(...)  [same as build path]
  | 8. DBI::dbWriteTable "lifestage_dictionary" overwrite=TRUE
  | 9. DBI::dbWriteTable "lifestage_review"     overwrite=TRUE
  | 10. Upsert patch keys in _metadata:
  |       lifestage_patch_applied_at
  |       lifestage_patch_release
  |       lifestage_patch_method
  |       lifestage_patch_version
  | 11. Disconnect read-write con
  | 12. .eco_close_con()  — clear .ComptoxREnv$ecotox_db (already NULL)
  v
  Returns invisible list(db_path, ecotox_release, dictionary_rows,
                          review_rows, refresh_mode)
  Next .eco_get_con() call reopens as read-only and re-caches
```

### Runtime Path (Query Enrichment)

```
eco_results(casrn="50-29-3", ...)
  |
  | .eco_get_con()  — returns cached read-only connection
  | .eco_base_query()
  | .eco_enrich_metadata(query, con)
  |   |
  |   | LEFT JOIN lifestage_codes ON organism_lifestage = code
  |   |   -> exposes: org_lifestage (renamed from description)
  |   | LEFT JOIN lifestage_dictionary ON org_lifestage = org_lifestage
  |   |   -> exposes: source_ontology, source_term_id, source_term_label,
  |   |               source_match_status, harmonized_life_stage,
  |   |               reproductive_stage, derivation_source
  |   | dplyr::relocate places all 8 fields after organism_lifestage
  |   | lifestage_review is NEVER joined at runtime
  v
  Collected tibble with new columns, ontology_id absent
```

### Cache / Baseline Resolution Order

```
.eco_lifestage_load_seed_cache(ecotox_release, refresh)

refresh = "auto"
  1. User cache exists for release?  YES -> use it
  2. Committed baseline matches release?  YES -> seed user cache from it, use it
  3. Neither -> live lookup, write user cache

refresh = "cache"
  1. User cache exists?  YES -> use it
  2. NO + force=TRUE  -> fall back to "auto"
  3. NO + force=FALSE -> abort

refresh = "baseline"
  1. Committed baseline matches release?  YES -> seed user cache, use it
  2. NO + force=TRUE  -> fall back to "auto"
  3. NO + force=FALSE -> abort

refresh = "live"
  1. Skip all cache/baseline reads
  2. Resolve all terms from providers
  3. Overwrite user cache with fresh results
```

## Connection Management Pattern

DuckDB enforces a single-writer constraint per database file. The package maintains one
cached read-only connection in `.ComptoxREnv$ecotox_db`. The patch function needs
read-write access. These cannot coexist on the same file.

**Protocol used by `.eco_patch_lifestage()`:**

```r
# Step 1 — evict cached read-only handle before touching the file
.eco_close_con()

# Step 2 — open read-write
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)

# Step 3 — guarantee cleanup even on error
on.exit({
  if (DBI::dbIsValid(con)) DBI::dbDisconnect(con, shutdown = TRUE)
  .eco_close_con()  # clears .ComptoxREnv$ecotox_db (set to NULL by disconnect above)
}, add = TRUE)

# ... do work ...

# Explicit disconnect before on.exit fires is NOT needed — on.exit handles it
# After on.exit: .ComptoxREnv$ecotox_db is NULL
# Next .eco_get_con() call opens a fresh read-only handle and caches it
```

**Why `.eco_close_con()` is called twice:**

The first call (before opening read-write) ensures the file has zero active handles so
DuckDB grants write access. The second call (in `on.exit`) is defensive: if an error path
between steps leaves `.ComptoxREnv$ecotox_db` non-NULL somehow, the second call clears it
so the next query does not try to reuse a stale or invalid handle.

**Build-time context:** `ecotox_build.R` never calls `.eco_get_con()`. It manages its own
`eco_con` handle (`DBI::dbConnect` at the start, `DBI::dbDisconnect` at the end) and
writes tables directly through that handle. No conflict with the cached connection arises
because the cached connection is only created when user code calls into the package via
`eco_results()` et al., which does not happen during an ETL build.

## Shared Helper Layer Structure

`R/eco_lifestage_patch.R` defines 14 internal functions in dependency order:

```
Schema helpers (no dependencies)
  .eco_lifestage_cache_schema()
  .eco_lifestage_dictionary_schema()
  .eco_lifestage_review_schema()

Path and I/O helpers (depend on R_user_dir / system.file)
  .eco_lifestage_release_id(x)      -- accepts DBIConnection, file path, or zip name
  .eco_lifestage_cache_path(release)
  .eco_lifestage_baseline_path()
  .eco_lifestage_derivation_path()
  .eco_lifestage_read_csv(path)
  .eco_lifestage_json_col()         -- safe column extraction from JSON docs
  .eco_lifestage_json_binding_value()
  .eco_lifestage_json_list_col()

Validation helper
  .eco_lifestage_validate_cache(x, expected_release, source_name)

Cache read / write
  .eco_lifestage_cache_read(release, required)
  .eco_lifestage_cache_write(x, release)
  .eco_lifestage_derivation_map()

Seed resolution (selects cache source by refresh mode)
  .eco_lifestage_load_seed_cache(release, refresh, force)

Text normalization and scoring
  .eco_lifestage_normalize_term(x, mode)
  .eco_lifestage_regex_escape(x)
  .eco_lifestage_token_score(term, candidate)
  .eco_lifestage_score_text(term, candidate)

Provider queries (depend on httr2, jsonlite)
  .eco_lifestage_nvs_index(refresh)    -- caches in .ComptoxREnv
  .eco_lifestage_query_ols4(term, ontology)
  .eco_lifestage_query_nvs(term)

Ranking and resolution
  .eco_lifestage_rank_candidates(org_lifestage, candidates)
  .eco_lifestage_resolve_term(org_lifestage, ecotox_release)

Output construction
  .eco_lifestage_review_from_cache(cache_rows)
  .eco_lifestage_derive_fields(resolved_rows)

Table materialization (called by both build and patch)
  .eco_lifestage_materialize_tables(org_lifestages, ecotox_release,
                                    refresh, force, write_cache)

Patch entrypoint (depends on all above + eco_connection.R functions)
  .eco_patch_lifestage(db_path, refresh, force)
```

The file begins with a guard that creates `.ComptoxREnv` if sourced standalone (i.e. in
the build script context where the package is not loaded). This lets the NVS index cache
work identically whether called from `ecotox_build.R` or from inside a loaded package
session.

## Build and Validation Order

The dependency chain dictates this sequence for v2.4 implementation verification:

**Step 1 — Shared helpers exist and are self-consistent**
- `R/eco_lifestage_patch.R` exists (confirmed)
- All 14+ functions defined in dependency order
- Schema functions return correct zero-row tibbles
- `devtools::load_all()` loads without errors

**Step 2 — Baseline and derivation artifacts are present**
- `inst/extdata/ecotox/lifestage_baseline.csv` exists (confirmed)
- `inst/extdata/ecotox/lifestage_derivation.csv` exists (confirmed)
- Baseline uses the 13-column cache schema
- Derivation uses the 5-column key schema (`source_ontology`, `source_term_id`,
  `harmonized_life_stage`, `reproductive_stage`, `derivation_source`)
- Both cover at least one common ECOTOX release

**Step 3 — Runtime join in eco_functions.R is correct**
- `.eco_enrich_metadata()` lines 659-679: `lifestage_codes` join then
  `lifestage_dictionary` join on `org_lifestage`
- Eight columns relocated after `organism_lifestage`
- `ontology_id` absent from all `dplyr::select` / `dplyr::relocate` calls
- `devtools::document()` regenerates `man/eco_results.Rd` with new field docs

**Step 4 — Build script section 16 is identical in both files**
- `inst/ecotox/ecotox_build.R` lines 974-1023
- `data-raw/ecotox.R` lines 975-1024
- Both use the same helper availability check pattern:
  `exists(".eco_lifestage_materialize_tables")` -> source or namespace copy
- Both call `.eco_lifestage_materialize_tables(refresh="auto", write_cache=TRUE)`
- Both write with `overwrite=TRUE`
- Both emit `cli::cli_alert_warning` on quarantine rows

**Step 5 — Patch function safety checks pass**
- `.eco_patch_lifestage()` aborts on missing `_metadata`
- Aborts on missing `ecotox_release` key
- Aborts on missing `lifestage_codes` or `description` column
- Writes only `lifestage_dictionary`, `lifestage_review`, `_metadata`
- Returns invisible named list

**Step 6 — Integration: patch then query**
- After `.eco_patch_lifestage()`, `.eco_get_con()` returns a fresh handle
- `eco_results(casrn="50-29-3")` returns expected columns
- `ontology_id` absent from output
- `harmonized_life_stage` populated for resolved terms

**Step 7 — Build integration: fresh DB has matching tables**
- Full build via `eco_install(build=TRUE)` produces a DB whose
  `lifestage_dictionary` matches what `.eco_patch_lifestage()` would produce
  for the same ECOTOX release

## Integration Points with Existing Code

### eco_functions.R — `.eco_enrich_metadata()` (lines 659-679)

The join is already implemented. The two-step structure (codes then dictionary) is
deliberate: `lifestage_codes` translates the raw ECOTOX code to a human-readable
description (`org_lifestage`), which is the join key for `lifestage_dictionary`. Skipping
the `lifestage_codes` join would leave only a bare code that cannot match the dictionary.

The `relocate()` call places all 8 new columns immediately after `organism_lifestage`
in output column order. The `lifestage_review` table is never referenced at runtime; it
is a quarantine artifact for developer inspection only.

### eco_connection.R — Connection cache

`.eco_patch_lifestage()` depends on both `.eco_close_con()` and the fact that
`.ComptoxREnv$ecotox_db` is the single source of truth for the cached handle. Any future
refactoring of the connection cache must preserve this contract or update the patch
function's preamble.

`eco_path()` provides the default `db_path` argument to `.eco_patch_lifestage()`. If a
user has set `options(ComptoxR.ecotox_path = ...)`, the patch function will target that
path automatically. This is correct behavior.

### ecotox_build.R / data-raw/ecotox.R — Section 16 helper availability

The build script runs in a `local(new.env())` context (via `source(build_script, local =
new.env(parent = globalenv()))`). The `.ComptoxREnv` guard at the top of
`eco_lifestage_patch.R` ensures the NVS index cache works in that context. The
`exists(".eco_lifestage_materialize_tables", mode="function")` check allows the build to
work whether the helper was sourced directly (dev checkout) or copied from the installed
namespace.

### _metadata table

The build script writes `_metadata` at section 22 (after all ETL tables). The patch
function reads `_metadata` to extract `ecotox_release` before doing any work. If patch is
called on a DB that was built with v2.4 code, the metadata key `ecotox_release` is
guaranteed to exist. On a DB built by an older version, the key may be absent and the
patch aborts with an informative message.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Holding cached connection during patch

**What goes wrong:** Calling `.eco_patch_lifestage()` without first calling
`.eco_close_con()`. DuckDB will refuse the read-write open while a read-only handle to
the same file is active, producing an opaque connection error.

**Prevention:** `.eco_patch_lifestage()` calls `.eco_close_con()` as its first side
effect before attempting `dbConnect`. The `on.exit` handler ensures the cached handle is
cleared even if the read-write open fails.

### Anti-Pattern 2: Cross-release cache reuse

**What goes wrong:** A user cache from release `2024-06` is reused when the installed DB
is release `2024-09`. The dictionary would contain terms from the wrong release.

**Prevention:** `.eco_lifestage_validate_cache()` checks that all rows in the cache have
`ecotox_release` matching the expected release and aborts with an informative mismatch
error. Patch metadata in `_metadata` records the release that was actually applied.

### Anti-Pattern 3: Divergent build-script section 16 copies

**What goes wrong:** `inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R` section 16
drift apart. The development build (data-raw) produces different tables than the
installed build (inst/ecotox), breaking reproducibility.

**Prevention:** Both files must have byte-identical section 16 bodies. The acceptance
criterion in `LIFESTAGE_HARMONIZATION_PLAN2.md` explicitly requires this. A test
(`test-eco_lifestage_gate.R`) should assert the sections are identical using a diff-based
check on the file text.

### Anti-Pattern 4: Runtime join to lifestage_review

**What goes wrong:** Joining `lifestage_review` at query time leaks quarantine rows
(ambiguous, unresolved, needs-derivation) into user results, polluting the harmonized
output.

**Prevention:** `.eco_enrich_metadata()` joins only `lifestage_codes` and
`lifestage_dictionary`. The `lifestage_review` table is read-only from a developer
workflow perspective and is never referenced in the runtime query path.

### Anti-Pattern 5: Regex over raw ECOTOX terms in derived fields

**What goes wrong:** Applying regex patterns to `organism_lifestage` codes or
`org_lifestage` descriptions to infer `harmonized_life_stage` or `reproductive_stage`.
This was the v2.3 approach and it is explicitly torn out in v2.4.

**Prevention:** Derived fields come exclusively from the `lifestage_derivation.csv` lookup
keyed on `source_ontology + source_term_id`. Terms without a derivation entry are
quarantined in `lifestage_review` with `review_status = "needs_derivation"` rather than
receiving a regex-guessed category.

### Anti-Pattern 6: Live provider calls without session cache

**What goes wrong:** Each call to `.eco_lifestage_query_nvs()` makes a full SPARQL query
to the NVS endpoint, multiplying network round-trips by the number of ECOTOX terms (~120+
distinct lifestage descriptions).

**Prevention:** `.eco_lifestage_nvs_index()` fetches the entire S11 collection once per
session and caches the result in `.ComptoxREnv$eco_lifestage_nvs_index`. Subsequent calls
to `.eco_lifestage_query_nvs()` filter the in-memory index. The `refresh=TRUE` argument
forces a re-fetch if the session cache is suspected stale.

## Scalability Considerations

| Concern | Current (~120 ECOTOX lifestage terms) | Future |
|---------|---------------------------------------|--------|
| Live resolution time | 120 terms x 3 providers = 360 HTTP calls; ~5-10 min | Cache/baseline eliminates this for normal use |
| User cache size | One CSV per release, ~120 rows x 13 cols; negligible | Stable — ECOTOX lifestage vocabulary grows slowly |
| DB write during patch | Overwrites 2 tables + _metadata; sub-second for ~120 rows | Stable at this scale |
| NVS index memory | Full S11 collection; ~300 concepts, trivial memory | Stable |
| Connection re-open cost | `dbConnect` read-only after patch; ~10-50ms | Acceptable |

## Sources

- `R/eco_connection.R` — Connection cache implementation (.eco_get_con, .eco_close_con)
- `R/eco_functions.R` — `.eco_enrich_metadata()` lifestage join (lines 659-679)
- `R/eco_lifestage_patch.R` — Complete shared helper layer (926 lines)
- `inst/ecotox/ecotox_build.R` — Build pipeline section 16 (lines 974-1023)
- `data-raw/ecotox.R` — Dev build pipeline section 16 (lines 975-1024)
- `inst/extdata/ecotox/lifestage_baseline.csv` — Committed seed artifact
- `inst/extdata/ecotox/lifestage_derivation.csv` — Curated derivation map
- `LIFESTAGE_HARMONIZATION_PLAN2.md` — Authoritative implementation plan
- DuckDB single-writer constraint: https://duckdb.org/docs/connect/concurrency
