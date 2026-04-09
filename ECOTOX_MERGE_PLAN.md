# ECOTOX Database Merge into ComptoxR — Planning Document

## Context

The `curation` project (`~/Documents/curation/ecotox/`) has a DuckDB-backed ECOTOX database with a Plumber REST API and a suite of query/conversion functions. These are mature and battle-tested against production ECOTOX ASCII data. The goal is to merge the database, its query layer, and the unit/duration conversion infrastructure into the `ComptoxR` R package — following the same pattern established by the DSSTox merge.

## Current State

### Database
- **Location**: `curation/ecotox/ecotox.duckdb`
- **Backend**: DuckDB (~424 MB)
- **Source data**: EPA ECOTOX ASCII dump from `https://gaftp.epa.gov/ecotox/`
- **Tables**: ~20+ tables (tests, results, species, chemicals, references, plus validation/lookup tables like `app_exposure_types`, `app_exposure_type_groups`, `app_effect_groups_and_measurements`, `effect_groups_dictionary`, `lifestage_codes`, `lifestage_dictionary`, `app_application_frequencies`, `unit_conversion`, `duration_conversion`)
- **Build pipeline**: `curation/ecotox/ecotox.R` — downloads EPA FTP zip, unpacks pipe-delimited ASCII, loads into DuckDB, builds lookup dictionaries
- **Freshness**: 180-day checkpoint with version tracking (`installed_version.txt`)

### Plumber API (`plumber.R`)
The query layer is structured as Plumber endpoints. The main function is `post_results()` (~330 lines), which is the primary candidate for extraction.

| Endpoint | Function | Purpose |
|---|---|---|
| `GET /health-check` | `health()` | DB status, version, size |
| `GET /inventory` | `inventory()` | Full chemicals table |
| `GET /all_tbls` | `all_tbls()` | List DB tables |
| `GET /fields/<table>` | `fields()` | Column names for a table |
| `GET /tables/<table>` | `get_tbl()` | Raw table contents |
| `GET /glimpse/<table>` | `tbl_glimpse()` | Head + glimpse of a table |
| `POST /results` | `post_results()` | **Main query engine** — filter by CASRN, species, endpoint, eco_group, species flags; joins tests→species→results→exposure types→effects→lifestages→frequencies; applies unit and duration conversion |

### Supporting Code

| File | Purpose | Migration target |
|---|---|---|
| `ecotox_queries.R` | `convert_units()`, `convert_duration()`, `Mode()`, `weighted_average()` | Internal helpers in ComptoxR |
| `process_unit.r` | Pepijn de Vries' `ECOTOXr`-derived unit sanitizer (`as_unit_ecotox`, `process_ecotox_units`, `mixed_to_single_unit`) — 490 lines of regex-based unit normalization | Deferred — not needed for initial merge |
| `eco_tbl.R` | Interactive analysis script using ComptoxR + DuckDB | Not migrated (consumer, not library code) |
| `validation.R` | DB validation checks | Fold into build pipeline |
| `test_queries.R` | 12 integration tests for `post_results()` | Convert to `testthat` tests |
| `Diagnostics.R` | Ad-hoc diagnostics | Not migrated |
| `bene_insects.R` | Beneficial insect analysis | Not migrated (domain script) |
| `eco_read_across.md` | Proposal: taxonomic distance-based surrogate species | Future feature, not part of merge |
| `MeasureUnit.CSV` | EPA WQX unit conversion reference (65 KB) | Not used by any script — ignored |

### Existing ComptoxR Scaffolding
- `eco_server()` already exists in `R/zzz.R:337` — routes to ECOTOX public site (1), internal (2), or local Plumber at `127.0.0.1:5555` (3)
- `eco_burl` environment variable is auto-set on package load
- No `eco_*` wrapper functions exist yet

## Key Decisions

### 1. Database Location Strategy

**Same as DSSTox**: `R_user_dir("ComptoxR", "data")` with `options()` override.

- Default: `tools::R_user_dir("ComptoxR", "data")/ecotox.duckdb`
- Override: `options(ComptoxR.ecotox_path = "/custom/path/ecotox.duckdb")`
- The 424 MB database is too large for CRAN or `inst/extdata`. External hosting is required.

### 2. Connection & Routing via `eco_server()`

Use the existing `*_server()` convention. `eco_server()` gains a new option for local DuckDB and support for custom paths. No separate `eco_connect()` function — connection management is an internal detail.

```r
eco_server(1)                           # EPA public site — BROWSE ONLY (opens browser)
eco_server(2)                           # Reserved / internal EPA
eco_server(3)                           # Local Plumber at 127.0.0.1:5555 (HTTP API)
eco_server(4)                           # Local DuckDB file (direct, default R_user_dir path)
eco_server("/path/to/ecotox.duckdb")    # Custom DuckDB file path (direct)
```

**Important: EPA ECOTOX has no public REST API.** Unlike CompTox Dashboard (`ctx_server(1)`) which has a real API, `eco_server(1)` currently points to `https://cfpub.epa.gov/ecotox/index.cfm` — that's a web UI, not a queryable endpoint. There are only two real access modes:

- **Direct DuckDB** (`eco_server(4)` or string path) — query the local database file. This is the primary mode for package users.
- **HTTP to Plumber** (`eco_server(3)`) — query a self-hosted Plumber instance. This is the deployment mode for Shiny apps or shared services.

Options 1 and 2 exist for convention consistency with other `*_server()` functions but do NOT support `eco_results()` queries. Calling `eco_results()` while pointed at option 1 or 2 should abort with a clear message: `"ECOTOX has no public API. Use eco_server(4) for local DuckDB or eco_server(3) for a Plumber instance."` Option 1 could optionally open the EPA ECOTOX search page in a browser via `utils::browseURL()`.

**How routing works**: `eco_server()` sets `eco_burl` to either a URL or a file path. The `eco_*()` query functions route internally based on what `eco_burl` contains:

```r
# Inside eco_results() and friends:
burl <- Sys.getenv("eco_burl")
if (file.exists(burl) && grepl("\\.duckdb$", burl)) {
  # Direct DuckDB — use managed connection in .ComptoxREnv$ecotox_db
  # Lazy-init: connect on first call, reuse thereafter
  # Read-only, cleaned up in .onUnload()
} else if (grepl("^https?://127\\.0\\.0\\.1|^https?://localhost", burl)) {
  # HTTP request to local Plumber instance
  # Uses httr2 pipeline, expects Plumber API contract
} else {
  cli::cli_abort(c(
    "ECOTOX has no public REST API.",
    "i" = "Use {.code eco_server(4)} for local DuckDB access.",
    "i" = "Use {.code eco_server(3)} for a self-hosted Plumber instance.",
    "i" = "Run {.code eco_install()} to build the local database."
  ))
}
```

**`eco_server(4)` path resolution order**:
1. `options(ComptoxR.ecotox_path)` if set
2. `tools::R_user_dir("ComptoxR", "data")/ecotox.duckdb` if file exists
3. Abort with message pointing to `eco_install()`

**String argument** (`eco_server("/custom/path.duckdb")`): If the argument is a character string instead of a number, treat it as a direct file path. Validates the file exists before setting `eco_burl`.

**Connection lifecycle**:
- Managed internally in `.ComptoxREnv$ecotox_db` — users never see it
- Lazy-init on first `eco_*()` call when in local DuckDB mode
- Read-only connection (safe to hold open for session lifetime)
- Cleaned up in `.onUnload()` hook
- Switching modes via `eco_server()` closes any existing connection

**Performance improvement over Plumber**: The current Plumber API opens and closes a DuckDB connection on every single request (`dbConnect` + `on.exit(dbDisconnect)`). The managed connection eliminates this overhead entirely.

### 3. Database Build Pipeline

**Option A: `data-raw/ecotox.R`** (canonical build script inside ComptoxR)
- Adapted from `curation/ecotox/ecotox.R`
- Downloads EPA FTP zip, processes ASCII → Parquet → DuckDB
- Builds all lookup/conversion tables
- Run via `eco_install()` or `eco_build()`

**Option B: Pre-built download** (user convenience)
- Host `.duckdb` file on GitHub Release asset (see issue #135)
- `eco_install()` downloads the latest build

**Recommendation**: Option A as the canonical build, Option B for `eco_install()` convenience. The curation project continues to own the ETL for its own purposes; ComptoxR gets a standalone build script.

**Adaptation notes for `data-raw/ecotox.R`**: The source script (`curation/ecotox/ecotox.R`, 500+ lines) is not copy-pasteable. It requires these specific changes:

1. **Remove interactive prompts**: The checkpoint block uses `usethis::ui_yeah()` for rebuild confirmation. The package version should be non-interactive — always build when called.
2. **Replace `here::here()` paths**: The curation script uses `here("ecotox", ...)` relative to the curation project root. The package script should use `tools::R_user_dir("ComptoxR", "data")` as the target directory.
3. **Replace `httr::GET()` with `httr2`**: The FTP scraping uses legacy `httr::GET()` + `rvest` to discover the latest zip filename from `https://gaftp.epa.gov/ecotox/`. Rewrite with `httr2::request()` pipeline for consistency with the rest of ComptoxR.
4. **Remove `setwd()` calls**: The source script `setwd()`s into subdirectories during processing. The package version should use explicit paths throughout.
5. **Remove global `deploy` flag**: The curation script has a `deploy <- FALSE` flag that gates deployment behavior. Not relevant to the package.
6. **Handle the Parquet intermediate step**: The source script reads pipe-delimited ASCII → writes Parquet → reads Parquet → writes to DuckDB. This two-step approach works around memory constraints for large tables. Keep this pattern in the package version (it's intentional, not accidental complexity).
7. **Validation tables**: Lines 219-310 of `ecotox.R` process a separate `validation/` subdirectory inside the zip. These become additional DuckDB tables. Don't skip them — `post_results()` joins against some of these.
8. **Lookup dictionary construction**: Lines 310+ build the `unit_conversion`, `duration_conversion`, `lifestage_dictionary`, `effect_groups_dictionary`, and other lookup tables by transforming raw ECOTOX validation tables. This is the most delicate part — the exact SQL/dplyr logic must be preserved or the conversion layer breaks.
9. **Version tracking**: The source script writes `installed_version.txt` with the EPA release date. The package version should store this metadata in the DuckDB itself (e.g., a `_metadata` table) rather than a sidecar file.

### 4. Function Architecture

The Plumber `post_results()` is a monolithic 330-line function that does too many things. For a package API, decompose it into focused, composable functions:

#### Core query functions (user-facing `eco_*`)

| Function | Purpose | Source |
|---|---|---|
| `eco_results(casrn, species, endpoint, eco_group, ...)` | Main query — replaces `post_results()` | `plumber.R:post_results` |
| `eco_inventory()` | Chemical inventory list | `plumber.R:inventory` |
| `eco_tables()` | List available tables | `plumber.R:all_tbls` |
| `eco_fields(table)` | Column names for a table | `plumber.R:fields` |
| `eco_species(query)` | Species lookup/search | New (extracted from species join logic) |
| `eco_health()` | DB status check | `plumber.R:health` |

#### Internal helpers (not exported)

| Function | Purpose | Source |
|---|---|---|
| `.eco_get_con()` | Get or lazy-init managed DuckDB connection from `.ComptoxREnv` | New |
| `.eco_close_con()` | Close managed connection (called by `eco_server()` on mode switch and `.onUnload()`) | New |
| `.eco_join_species(query, con)` | Species join + filter logic | Extracted from `post_results` |
| `.eco_join_results(query, con)` | Results join + filter logic | Extracted from `post_results` |
| `.eco_join_metadata(query, con)` | Exposure types, effects, lifestages, frequencies | Extracted from `post_results` |
| `.eco_convert_units(df)` | Unit conversion via lookup table | `plumber.R` inline + `ecotox_queries.R:convert_units` |
| `.eco_convert_duration(df)` | Duration normalization to hours | `plumber.R` inline + `ecotox_queries.R:convert_duration` |
| `.eco_clean_values(df)` | Strip `*`, `+`, `/`, `~` annotations; TRY_CAST numeric | `plumber.R` inline |

#### Performance gains from decomposition

1. **No per-call `dbConnect`/`dbDisconnect`**: Single managed connection per session
2. **Lazy `collect()`**: Internal helpers return dbplyr lazy queries; `eco_results()` only `collect()` at the end after all filters push down to DuckDB
3. **Composable joins**: Users who want only species data don't pay the cost of joining tests→results→exposure types→effects→lifestages→frequencies→unit_conversion→duration_conversion (8 joins)
4. **Column-level pushdown**: Only select needed columns in DuckDB instead of collecting wide tables

### 5. Unit Conversion Strategy

There are **three** unit conversion systems in the curation project:

1. **Simple lookup tables** (`unit_conversion`, `duration_conversion` in DuckDB) — used by `plumber.R:post_results()`
2. **`ecotox_queries.R:convert_units()`** — case_when R-side conversion for a small set of known units
3. **`process_unit.r`** (Pepijn de Vries' `ECOTOXr` code) — comprehensive regex-based sanitizer using the `units` package

**Recommendation**: Migrate **only #1** (DuckDB lookup tables) for the initial merge. This is what the Plumber API uses and it's the simplest, fastest path. The lookup tables are built as part of the database build pipeline and queried via DuckDB JOIN — no R-side regex needed.

The full unit sanitization can be a separate feature later if needed.

### 6. The `eco_tbl.R` / Risk Binning Consideration

`eco_tbl.R` contains an extensive domain logic layer: eco-group classification, acute/chronic test type assignment (by eco_group × endpoint × duration × unit × exposure route), and OPP-style risk binning (VH/H/M/L/XL). This is **not** generic query infrastructure — it's an opinionated risk assessment workflow.

**Recommendation**: Do NOT merge `eco_tbl.R` into ComptoxR. It belongs in:
- A downstream analysis package (e.g., a future `ecorisk` package)
- The `curation/ecotox/` project where it already lives
- A vignette/example if demand exists

The risk binning thresholds are regulatory-specific (EPA OPP) and shouldn't be baked into a general-purpose API wrapper package.

### 7. Plumber API: Thin Wrappers, Not Deprecated

The Plumber API remains valuable for deployment scenarios — serving ECOTOX data to Shiny apps, non-R consumers, or as a self-hosted microservice. The merge **improves** the Plumber layer rather than replacing it.

**Current state**: `plumber.R` owns all query logic (330+ lines in `post_results()` alone). The Plumber endpoints ARE the business logic.

**After merge**: Plumber endpoints become thin HTTP wrappers around ComptoxR package functions. One source of truth, two access patterns.

```r
# Before (plumber.R owns the logic)
#* @post /results
post_results <- function(casrn = NULL, ...) {
  con <- dbConnect(duckdb(), dbdir = "ecotox.duckdb", read_only = TRUE)
  on.exit(dbDisconnect(con))
  # ... 330 lines of joins, filters, conversions ...
}

# After (plumber.R delegates to ComptoxR)
#* @post /results
post_results <- function(casrn = NULL, common_name = NULL, latin_name = NULL,
                          endpoint = NULL, eco_group = NULL, ...) {
  ComptoxR::eco_results(
    casrn = casrn, common_name = common_name, latin_name = latin_name,
    endpoint = endpoint, eco_group = eco_group, ...
  )
}
```

**Benefits**:
- Plumber endpoints shrink to ~5 lines each
- Bug fixes and improvements to query logic propagate to both access patterns automatically
- No per-request `dbConnect`/`dbDisconnect` — ComptoxR's managed connection handles this
- The `curation/ecotox/plumber.R` can be maintained as a lightweight deployment artifact

**Migration**: After Phase 2, rewrite `curation/ecotox/plumber.R` to `library(ComptoxR)` + thin wrappers. Ship an example Plumber file in `inst/plumber/ecotox/plumber.R` so users can deploy their own instance.

### 8. Lifestage Dictionary

The lifestage harmonization in `eco_tbl.R` (100+ `str_detect()` → `case_when()` mappings) is valuable domain knowledge. Rather than embedding this in R code:

**Recommendation**: Build it as a lookup table in the DuckDB database during `eco_build()`. The existing `lifestage_codes` and `lifestage_dictionary` tables already do partial harmonization. Extend `lifestage_dictionary` with the comprehensive mappings from `eco_tbl.R` and join in DuckDB (free pushdown, no R overhead).

## File References

| File | Location | Purpose |
|---|---|---|
| Main ETL script | `curation/ecotox/ecotox.R` | Downloads and builds `ecotox.duckdb` |
| Plumber API | `curation/ecotox/plumber.R` | Query functions to migrate |
| Unit conversion (simple) | `curation/ecotox/ecotox_queries.R` | Helper functions |
| Unit conversion (advanced) | `curation/ecotox/process_unit.r` | ECOTOXr-derived unit sanitizer (deferred) |
| Integration tests | `curation/ecotox/ecotox_queries.R` (bottom) + `test_queries.R` | Convert to testthat |
| Risk analysis | `curation/ecotox/eco_tbl.R` | Do NOT migrate — domain-specific consumer |
| Eco server config | `ComptoxR/R/zzz.R:337` | Extend with local DuckDB mode |
| Database file | `curation/ecotox/ecotox.duckdb` | 424 MB DuckDB database |
| MeasureUnit.CSV | `curation/ecotox/MeasureUnit.CSV` | Unused reference file — ignored |

## Migration Order

### Phase 1: Server & Infrastructure
1. Extend `eco_server()` with option 4 (local DuckDB) and string path support
2. Implement `.eco_get_con()` / `.eco_close_con()` internal connection management in `.ComptoxREnv`
3. Add `eco_install()` — downloads or builds the DuckDB database
4. Wire path resolution: `options(ComptoxR.ecotox_path)` > `R_user_dir()` > abort
5. Add `.onUnload()` cleanup for managed connection

### Phase 2: Core Query Functions
6. Port `eco_results()` — decomposed from `post_results()` with lazy dbplyr pipeline. Two code paths: DuckDB direct (option 4 / string path) builds the join chain in dbplyr and `collect()` at the end; Plumber HTTP (option 3) sends POST to the Plumber `/results` endpoint via `httr2`. Options 1/2 abort with a message pointing to option 4 or `eco_install()`.
7. Port `eco_inventory()`, `eco_tables()`, `eco_fields()`, `eco_species()`
8. Port `eco_health()` — adapted for package context (no Plumber decorators)
9. Build internal join helpers — the exact decomposition of `post_results()` will be determined during implementation. The goal is composable dbplyr lazy queries (species, results, metadata enrichment) that push filters to DuckDB before `collect()`. Helper names and boundaries may shift from what's listed in Section 4.

### Phase 3: Conversion Layer
10. Port `.eco_convert_units()` and `.eco_convert_duration()` using DuckDB lookup tables
11. Port `.eco_clean_values()` — annotation stripping and numeric casting
12. Extend `lifestage_dictionary` table with `eco_tbl.R` harmonized mappings

### Phase 4: Build Pipeline
13. Create `data-raw/ecotox.R` — standalone build script adapted from `curation/ecotox/ecotox.R`. See Section 3 "Adaptation notes" for the 9 specific changes required (interactive prompts, `here()` paths, `httr` → `httr2`, `setwd()` removal, Parquet intermediate step, validation tables, lookup dictionary construction, version metadata).
14. Implement `eco_install()` — orchestrates the build: download EPA FTP zip → extract → build DuckDB → store in `R_user_dir()`. Include version checking (compare EPA release date against `_metadata` table in existing DB) and freshness management.

### Phase 5: Plumber Rewrite — COMPLETE
15. ~~Rewrite `curation/ecotox/plumber.R` — thin wrappers calling `ComptoxR::eco_*()` functions~~
16. ~~Ship example Plumber file in `inst/plumber/ecotox/plumber.R` for self-hosted deployment~~

### Phase 6: Testing & Cleanup — COMPLETE
17. ~~Convert `test_queries.R` and `ecotox_queries.R` examples to `testthat` tests with DuckDB test fixtures~~ — `test_queries.R` was an ad-hoc analysis script, not convertible tests. Real coverage is in `test-eco_connection.R` (24 tests) and `test-eco_functions.R` (28 tests).
18. ~~Update `DESCRIPTION` (add `duckdb`, `DBI` to Imports if not already)~~ — `duckdb`, `DBI`, `dbplyr` all in Imports.
19. ~~Update documentation, `NAMESPACE`, `README.md`~~ — All 8 `eco_*` functions exported, Rd files generated.
20. Clean up `curation/ecotox/` — deferred to separate task (curation project outside this repo).

## Resolved Decisions

- **`ECOTOXr` relationship**: Fully independent. No dependency, no Suggests. We're building a better package.
- **Plumber API**: Kept as a thin-wrapper deployment layer. Plumber delegates to ComptoxR package functions. An example Plumber file ships in `inst/plumber/ecotox/`.
- **`eco_server()` vs `eco_connect()`**: No separate `eco_connect()`. Extend the existing `eco_server()` convention with option 4 (local DuckDB) and string path support. Connection management is internal via `.eco_get_con()` in `.ComptoxREnv`. Consistent with `ctx_server()`, `chemi_server()`, etc.
- **`MeasureUnit.CSV`**: Not referenced by any script in the curation project. Ignored.
- **`eco_server()` numbering**: Deviated from plan. Final numbering: 1=DuckDB (most common), 2=Plumber, 3=EPA public (browse-only), 4=EPA dev (placeholder). Rationale: the most common use case (local DuckDB) gets the lowest number for better UX.

## Open Questions

None — all phases complete. Ready for merge to `main`.
