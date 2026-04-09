# ToxValDB Merge into ComptoxR — Implementation Plan

## Context

The `curation/epa/toxval/` project has an ETL pipeline that downloads ToxValDB per-source Excel files from the EPA Clowder API and stacks them into Parquet. ToxValDB aggregates guideline values, study results, and regulatory limits from 61+ sources (ATSDR, IRIS, WHO, Cal OEHHA, etc.). This plan merges ToxValDB into ComptoxR following the ECOTOX pattern — local DuckDB + Plumber modes, version slug in the startup header, and a curated query API.

**Key decisions:**
- **Latest version only** (v9.7.0, ~249K rows) — no multi-version storage
- **All 81 columns stored in DuckDB** — 7 fully empty columns kept for schema consistency
- **Curated default return set (~45 cols):** universal (35) + key moderate columns — `cols = "all"` returns everything
- **Public Clowder API** — no auth needed, but fragile; needs retry, validation, and fallback

## Implementation Status

### Phase 1: Server & Connection Infrastructure — COMPLETE

| Item | File | Status |
|---|---|---|
| `tox_path()` | `R/tox_connection.R` | Done |
| `.tox_get_con()` / `.tox_close_con()` | `R/tox_connection.R` | Done |
| `tox_install()` with 3-path resolution | `R/tox_connection.R` | Done |
| `tox_server()` (modes 1–4) | `R/zzz.R` | Done |
| `.onAttach()` default `tox_server(1)` | `R/zzz.R` | Done |
| `.onUnload()` cleanup | `R/zzz.R` | Done |
| `.header()` ToxValDB status in startup | `R/zzz.R` | Done |
| GitHub Release download fast-path | `R/z_db_download.R` | Done |

### Phase 2: Core Query Functions — COMPLETE

| Item | File | Status |
|---|---|---|
| `.tox_route()` | `R/tox_functions.R` | Done |
| `.tox_default_cols()` (45 curated cols) | `R/tox_functions.R` | Done |
| `tox_tables()`, `tox_fields()` | `R/tox_functions.R` | Done |
| `tox_health()` | `R/tox_functions.R` | Done |
| `tox_sources()` | `R/tox_functions.R` | Done |
| `tox_search()` (ILIKE pattern) | `R/tox_functions.R` | Done |
| `tox_results()` (main query engine) | `R/tox_functions.R` | Done |
| Guard clause (no full-table scans) | `R/tox_functions.R` | Done |
| QC filtering (3 modes) | `R/tox_functions.R` | Done |
| Plumber request handler | `R/tox_functions.R` | Done |

### Phase 3: Build Pipeline — NEEDS HARDENING

| Item | File | Status |
|---|---|---|
| `.build_toxval_db()` function | `inst/toxval/toxval_build.R` | Done but has gaps |
| Dependency check | `inst/toxval/toxval_build.R` | Done |
| Clowder API discovery + retry | `inst/toxval/toxval_build.R` | Done |
| Excel download + validation | `inst/toxval/toxval_build.R` | Done |
| Stack + type cast + DuckDB write | `inst/toxval/toxval_build.R` | Done |
| `_metadata` table tracking | `inst/toxval/toxval_build.R` | Done |
| `data-raw/toxval.R` thin wrapper | `data-raw/toxval.R` | Done |

**Gaps — must fix:**

1. **No staleness check.** ECOTOX and DSSTox both check `file.info(output_path)$mtime` against a 180-day threshold and skip rebuilding if the database is fresh. ToxVal only checks if the exact version string is already in `_metadata`. If the same version exists but the DB is corrupt or stale, it silently skips. Add a 180-day mtime check as first gate, before Clowder API calls.

2. **Non-atomic write.** ECOTOX builds in DuckDB `:memory:` then uses `COPY FROM DATABASE` to persist atomically. ToxVal writes directly to the output path via `DBI::dbConnect(duckdb(), dbdir = output_path)`. If the build crashes mid-write, the user gets a corrupt partial database. Switch to in-memory build → persist pattern.

3. **No row count sanity check.** DSSTox validates `row_count >= n_files * 10000` after loading. ToxVal has no post-write validation. Add a minimum threshold (e.g., 100K rows for v9.x) or at minimum check `nrow(stacked) > 0` before writing.

4. **Temp file cleanup not crash-safe.** Line 208 (`file.remove(downloaded_files)`) runs at the end of the function. If any earlier step errors, temp files are orphaned. Move to `on.exit()` registration immediately after creating the temp directory.

5. **Version regex is fragile.** The `str_extract("v\\d+_\\d+")` pattern assumes ToxVal filenames always contain `v97_0`-style version strings. The curation source shows this has been stable across v92_ through v97_0, but if EPA changes naming (e.g., `v10_0` → `v100_0`), the `gsub("v(\\d)(\\d)_(\\d)", ...)` label derivation breaks. Add a fallback and validate the extracted version.

6. **`human_eco` column not verified.** `tox_results()` filters on `human_eco` but this column is not in the column coverage analysis (Section "Column Coverage Analysis"). Verify whether this column actually exists in the v9.7.0 data. If it doesn't exist, the dbplyr filter will silently return 0 rows.

### Phase 4: Plumber Deployment Artifact — COMPLETE

| Item | File | Status |
|---|---|---|
| Plumber server on port 5556 | `inst/plumber/toxval/plumber.R` | Done |
| `/health-check`, `/tables`, `/fields` | `inst/plumber/toxval/plumber.R` | Done |
| `/sources`, `/search`, `/results` | `inst/plumber/toxval/plumber.R` | Done |

### Phase 5: Testing — COMPLETE (with additions needed)

| Item | File | Status |
|---|---|---|
| Connection tests (17 tests) | `tests/testthat/test-tox_connection.R` | Done |
| Query tests (15 tests) | `tests/testthat/test-tox_functions.R` | Done |
| Download helper mock tests | `tests/testthat/test-tox_connection.R` | Done |

**Test gaps to address after Phase 3 hardening:**
- Build script: mock Clowder API to test staleness bypass, version extraction failure, and row count validation
- `human_eco` filter: verify the column exists in live data (add to live test suite)

### Phase 6: Integration & Docs — COMPLETE

| Item | Status |
|---|---|
| DESCRIPTION updated | Done |
| `devtools::document()` clean | Done |
| NAMESPACE exports (9 functions) | Done |
| man/ pages generated | Done |

---

## Hardening Plan (Phase 3 fixes)

These are the specific code changes needed in `inst/toxval/toxval_build.R`:

### 3.1 Add staleness check (ECOTOX pattern)

Insert after output path resolution (line 27), before DuckDB connect:

```r
# Staleness check: skip if DB exists and is <180 days old
if (file.exists(output_path)) {
  age_days <- as.numeric(
    difftime(Sys.time(), file.info(output_path)$mtime, units = "days")
  )
  if (age_days <= 180) {
    cli::cli_alert_success(
      "ToxValDB is up-to-date ({round(age_days)} days old). Skipping rebuild."
    )
    return(invisible(output_path))
  }
  cli::cli_alert_warning(
    "ToxValDB is {round(age_days)} days old. Rebuilding."
  )
}
```

### 3.2 Switch to in-memory build → persist (ECOTOX pattern)

Replace direct disk write with:

```r
# Build in memory to prevent partial writes on crash
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

# ... all reads and writes go to in-memory con ...

# Persist atomically
safe_path <- gsub("\\\\", "/", output_path)  # Windows path fix
DBI::dbExecute(con, sprintf(
  "ATTACH '%s' AS persist; COPY FROM DATABASE memory TO persist;", safe_path
))
```

### 3.3 Add row count sanity check

After stacking, before DuckDB write:

```r
if (nrow(stacked) < 100000L) {
  cli::cli_abort(c(
    "Row count sanity check failed: {nrow(stacked)} rows (expected >100,000).",
    "i" = "The Clowder data may be incomplete or the API response has changed."
  ))
}
```

### 3.4 Crash-safe temp cleanup

Replace manual `file.remove()` at end with `on.exit()` at temp dir creation:

```r
tmp_dir <- file.path(tempdir(), "toxval_build")
dir.create(tmp_dir, showWarnings = FALSE, recursive = TRUE)
on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
```

### 3.5 Robust version extraction

```r
version_raw <- stringr::str_extract(first_name, "v\\d{2,3}_\\d+")
if (is.na(version_raw)) {
  cli::cli_warn("Could not extract version from filename: {.file {first_name}}")
  version_raw <- paste0("v_unknown_", format(Sys.Date(), "%Y%m%d"))
}

# More flexible label derivation
version_label <- tryCatch({
  parts <- regmatches(version_raw, regexec("v(\\d+)_(\\d+)", version_raw))[[1]]
  if (length(parts) == 3) {
    major <- as.integer(parts[2])
    minor <- as.integer(parts[3])
    sprintf("%d.%d.%d", major %/% 10, major %% 10, minor)
  } else {
    version_raw
  }
}, error = function(e) version_raw)
```

### 3.6 Verify `human_eco` column

Check in `.tox_default_cols()` or `tox_results()` that the column actually exists before filtering. If `human_eco` is not in the data, either:
- Add it to column analysis and confirm it's populated
- Remove the filter parameter (breaking change — deprecate first)
- Use `dplyr::any_of()` pattern to silently skip missing columns

---

## Curation Source Reference

The curation project (`~/Documents/curation/epa/toxval/`) contains two ETL scripts:

| File | Lines | Strategy | Retry | Output |
|---|---|---|---|---|
| `toxval.R` | 324 | Direct file API, incremental download | None | Parquet |
| `parsing_clowder.R` | 307 | HTML parsing + folder ZIP download | 3 attempts, 5s backoff | Parquet |

**Adaptation notes** (from curation → package):

1. **Removed**: `here::here()` paths → `tools::R_user_dir()` / `output_path` parameter
2. **Removed**: `setwd()` calls → explicit paths throughout
3. **Removed**: `nanoparquet` dependency → `DBI::dbWriteTable()` directly
4. **Removed**: `install_booster_pack()` helper → `rlang::check_installed()`
5. **Kept**: `readxl::read_excel(col_types = "text")` + `janitor::clean_names()` pattern
6. **Kept**: Per-file retry logic (from `parsing_clowder.R`)
7. **Changed**: Output format Parquet → DuckDB (in-memory build → persist)
8. **Changed**: Clowder dataset ID `6572f1d2e4b0bfe1afb58fec` (v9 per-source files)
9. **Added**: `_metadata` table with version tracking (replaces sidecar text files)
10. **Added**: Excel file validation (readability check before stacking)

---

## Column Coverage Analysis (v9.7.0)

Analysis of 249,346 rows across 62 sources reveals three tiers:

### Universal (35 cols, >50% coverage, 35+ sources) — always in default return

`source_hash`, `dtxsid`, `source`, `qc_status`, `experimental_record`, `toxval_type`, `toxval_type_original`, `toxval_numeric`, `toxval_numeric_original`, `toxval_units`, `toxval_units_original`, `study_type`, `study_duration_value`, `exposure_route`, `study_group`, `qc_category`, `casrn`, `name`, `toxval_type_supercategory`, `qualifier`, `species_common`, `latin_name`, `species_supercategory`, `exposure_route_original`, `source_url`, `species_original`, `study_type_original`, `strain`, `year`, `original_year`, `sub_source`, `exposure_method_original`, `sex_original`, `sex`, `exposure_method`

### Key Moderate (10 cols, 10–50% coverage) — included in default return

`study_duration_class`, `study_duration_value_original`, `study_duration_units_original`, `study_duration_units`, `toxicological_effect`, `toxicological_effect_category`, `risk_assessment_class`, `lifestage`, `toxval_subtype`, `toxval_subtype_original`

### Remaining Moderate (9 cols) — excluded from default, available via `cols = "all"`

`toxicological_effect_original`, `strain_original`, `subsource_url`, `exposure_form`, `generation`, `generation_original`, `lifestage_original`, `media_original`, `media`

### Sparse (27 cols, <10% coverage) — in DB, excluded from default

Includes 7 fully empty columns (`subsource`, `habitat`, `population`, `source_source_id`, `toxval_uuid`, `toxval_hash`, `key_finding`) and 20 others populated by 0–26 sources.

### Unverified

`human_eco` — referenced in `tox_results()` filter parameter. **Must verify whether this column exists in the v9.7.0 data.** Not listed in any tier above. If missing, the filter silently returns 0 rows.

---

## Dependency Graph

```
Phase 1 (Server + Connection)    ← COMPLETE
    |
    +-------> Phase 2 (Query Functions)   ← COMPLETE
    |              |
    |              +---> Phase 4 (Plumber)           ← COMPLETE
    |              +---> Phase 5 (Tests)             ← COMPLETE
    |
    +-------> Phase 3 (Build Pipeline)    ← NEEDS HARDENING
                   |
                   +---> Phase 5 (build tests)       ← TODO
                   +---> Phase 6 (Integration)       ← COMPLETE
```

**Remaining critical path:** Phase 3 hardening (5 code changes) → build test additions

---

## Critical Files

| File | Lines | Action |
|---|---|---|
| `R/tox_connection.R` | 167 | DONE |
| `R/tox_functions.R` | 437 | DONE — verify `human_eco` column |
| `R/zzz.R` | +80 | DONE |
| `R/z_db_download.R` | 98 | DONE (shared helper) |
| `inst/toxval/toxval_build.R` | 211 | **HARDEN** — staleness, atomic write, row check, cleanup |
| `inst/plumber/toxval/plumber.R` | 73 | DONE |
| `data-raw/toxval.R` | 10 | DONE (thin wrapper) |
| `tests/testthat/test-tox_connection.R` | 86 | DONE |
| `tests/testthat/test-tox_functions.R` | 99 | DONE — add `human_eco` live test |

## Resolved Decisions

- **Build script location**: `inst/toxval/toxval_build.R` (matches ECOTOX; `data-raw/toxval.R` is thin wrapper)
- **Connection management**: Hybrid pattern — `.tox_get_con(con = NULL)` with session cache in `.ComptoxREnv`
- **Clowder dataset ID**: `6572f1d2e4b0bfe1afb58fec` — distinct from DSSTox dataset (`61147fefe4b0856fdc65639b`)
- **No Parquet intermediate**: Unlike ECOTOX (which needs it for 1GB+ ASCII), ToxVal's 74 Excel files fit in R memory. `readxl` → `list_rbind()` → `dbWriteTable()` is simpler and sufficient.
- **GitHub Release download**: Shared `.db_download_release()` helper used by all three `*_install()` functions
- **Server numbering**: 1=DuckDB, 2=Plumber (port 5556), 3=Public site, 4=Dev — consistent with ECOTOX
