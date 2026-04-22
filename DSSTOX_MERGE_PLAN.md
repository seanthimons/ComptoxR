# DSSTox Database Merge into ComptoxR — Planning Document

## Context

The `curation` project (`~/Documents/curation`) has a DuckDB-backed DSSTox chemical registry (`final/dsstox.duckdb`) with a suite of query functions defined inline in `pt/pt.R`. These functions are mature, documented with roxygen, and ready for package extraction. The goal is to merge the database and its query layer into the `ComptoxR` R package.

## Current State

### Database
- **Location**: `curation/final/dsstox.duckdb`
- **Backend**: DuckDB via `duckdb` + `DBI` packages
- **Schema**: Single `dsstox` table with columns: `DTXSID`, `parent_col`, `values`, `sort_order`
  - `parent_col` values include: `PREFERRED_NAME`, `CASRN`, `IDENTIFIER`, `SMILES`, `MOLECULAR_FORMULA`, `INCHIKEY`, `IUPAC_NAME`
  - ~15M rows (all identifiers for all DSSTox substances in long format)
- **Build pipeline**: `curation/epa/dsstox/dsstox.R` builds the database from EPA CompTox data

### Query Functions (defined in `pt/pt.R` lines 38–385)

| Function | Purpose | Interface |
|---|---|---|
| `dss_query(query)` | Exact match against `values` column | Character vector → tibble |
| `dss_synonyms(query)` | All records for a DTXSID | Single DTXSID string → tibble |
| `dss_resolve(query)` | Bulk resolve any identifier → DTXSID + preferred name + CASRN | Character vector → tibble (uses temp table + SQL CTE) |
| `dss_cas(query)` | CAS↔DTXSID bidirectional lookup | Character vector → tibble (uses temp table + SQL CTE) |
| `dss_search(pattern, cols, limit)` | SQL ILIKE pattern search | Pattern string → tibble |
| `dss_fuzzy(query, method, threshold, cols, limit)` | String distance search (jaro_winkler, levenshtein, damerau_levenshtein, jaccard) | Query string → tibble with similarity/distance score |

All functions currently depend on a global `dsstox_db` connection object.

### Consumers
- `pt/pt.R` — periodic table + isotope builder (primary consumer)
- Other curation scripts likely use it ad-hoc via the same pattern (source pt.R's function block, or copy-paste)

## Key Decisions

### 1. Database Location Strategy

**Option A: User-installed data directory**
- Use `tools::R_user_dir("ComptoxR", "data")` (e.g., `~/.local/share/ComptoxR/` on Linux, `AppData/Local/ComptoxR/` on Windows)
- Provide `dss_install()` or `dss_build()` function that downloads/builds the database on first use
- Pro: No size limit, standard R pattern (used by `BiocFileCache`, `pins`, etc.)
- Con: Requires explicit install step; database freshness management needed

**Option B: Environment variable / option**
- `options(ComptoxR.dsstox_path = "path/to/dsstox.duckdb")` or `Sys.setenv(DSSTOX_DB_PATH = "...")`
- Pro: Flexible, works for shared/network databases
- Con: Manual configuration per session

**Option C: Package-bundled**
- Ship in `inst/extdata/` or via a companion data package
- Pro: Zero config
- Con: DuckDB file is likely too large for CRAN (5MB limit); even GitHub has practical limits. Would need a companion package or external hosting.

**Recommendation**: Option A with Option B as override. Default to `R_user_dir()`, allow `options()` override for custom paths. Provide a `dss_install()` that builds from CompTox API or imports from a pre-built file.

### 2. Connection Management

**Current**: Global `dsstox_db <- DBI::dbConnect(...)` in script preamble.

**Option A: Internal managed connection (package environment)**
- Store connection in a package-level environment (`.ComptoxREnv$dsstox_db`)
- Auto-connect on first `dss_*` call (lazy init)
- `dss_connect()` / `dss_disconnect()` for explicit control
- `.onUnload()` hook to clean up
- Pro: Zero-config for users, just call `dss_query()` and it works
- Con: Hidden global state

**Option B: Explicit connection argument**
- Every `dss_*` function takes `con` parameter: `dss_query(query, con = dss_connect())`
- Pro: Testable, no global state, supports multiple databases
- Con: Verbose for interactive use

**Option C: Hybrid**
- Default `con = NULL` falls back to internal managed connection
- Users can pass explicit connection for testing/alternate databases
- Pro: Clean interactive UX + testable

**Recommendation**: Option C. Example signature: `dss_query(query, con = NULL)` where `NULL` triggers lazy connection from package environment.

### 3. Database Build Pipeline

**Option A: Build inside ComptoxR**
- `data-raw/dsstox.R` in the package builds the database from CompTox API
- Pro: Self-contained, reproducible
- Con: Very slow (15M rows from API), requires API key, large download

**Option B: Build in curation, consume in ComptoxR**
- Curation project builds `dsstox.duckdb`, ComptoxR's `dss_install()` copies/symlinks it
- Pro: Separation of concerns, curation project owns the ETL
- Con: Cross-project dependency

**Option C: Pre-built download**
- Host pre-built `.duckdb` file (GitHub Release asset, S3, etc.)
- `dss_install()` downloads the latest release
- Pro: Fast install, no API key needed for end users
- Con: Hosting/versioning overhead

**Recommendation**: Option A for `data-raw/` (canonical build), Option C for `dss_install()` (user convenience). The curation project can call `dss_install()` or directly use the package's build script.

### 4. Function Migration

The `dss_*` functions can move almost as-is with these changes:

1. Replace global `dsstox_db` references with `con` parameter + lazy init
2. Add `@family dsstox` roxygen tag for grouping
3. Move SQL CTEs (in `dss_resolve` and `dss_cas`) to internal helpers or parameterized queries
4. Consider parameterized queries instead of string interpolation in `dss_search` and `dss_fuzzy` (SQL injection surface — currently mitigated by `gsub("'", "''", ...)` but parameterized is safer)

### 5. pt.R Migration

Once `dss_*` functions live in ComptoxR:

- `pt/pt.R` drops its inline function definitions (lines 38–385) and just uses `library(ComptoxR)`
- The periodic table dataset (`pt`) can move to `ComptoxR/data-raw/pt.R` → `data/pt.rda`
- Available as `ComptoxR::pt` or `data(pt)` — lazy-loaded, no file paths
- The PubChem backfill pipeline already uses ComptoxR functions (`pubchem_search`, `pubchem_synonyms`, etc.)

### 6. The `dss_fuzzy()` Consideration

This function uses DuckDB-native string distance functions (`jaro_winkler_similarity`, `levenshtein`, `damerau_levenshtein`, `jaccard`). These are powerful but:
- Tied to DuckDB (won't work with other backends)
- Performance depends on blocking/filtering strategy (length-based blocking is already implemented)
- Consider exposing as a "DuckDB extension" feature with clear documentation that it requires the local database

## File References

| File | Location | Purpose |
|---|---|---|
| Query functions | `curation/pt/pt.R` lines 38–385 | The `dss_*` function suite to migrate |
| Database builder | `curation/epa/dsstox/dsstox.R` | ETL script that builds `dsstox.duckdb` |
| Database file | `curation/final/dsstox.duckdb` | The built DuckDB database |
| PubChem functions | `ComptoxR/R/pubchem_search.R`, `pubchem_synonyms.R`, `pubchem_properties.R`, `util_pubchem_resolve_dtxsid.R` | Already in ComptoxR |
| Periodic table script | `curation/pt/pt.R` | Consumer that becomes `data-raw/pt.R` |

## Migration Order

1. **Connection management** — implement `dss_connect()` + lazy init in ComptoxR
2. **Port `dss_*` functions** — move to `ComptoxR/R/dss_*.R` with `con` parameter
3. **Build pipeline** — create `data-raw/dsstox.R` and/or `dss_install()`
4. **Port `pt.R`** — move to `data-raw/pt.R`, strip inline functions, use package exports
5. **Clean up curation** — remove duplicated code from `curation/pt/pt.R`
