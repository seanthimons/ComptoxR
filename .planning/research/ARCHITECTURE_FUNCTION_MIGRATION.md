# Architecture: User-Facing Function Integration with Generic Request Templates

**Project:** ComptoxR v2.2 Package Stabilization
**Researched:** 2026-03-04
**Domain:** R package API wrapper architecture

## Executive Summary

ComptoxR uses a three-tier architecture: **generic request templates** (`generic_request()`) handle HTTP communication, **generated stubs** (`ct_*_search_bulk()`) provide schema-driven API wrappers, and **user-facing functions** (`ct_hazard()`, `ct_bioactivity()`) add domain-specific logic. The v2.2 migration stabilizes user-facing functions by delegating to generated stubs rather than calling `generic_request()` directly. This separation enables stub regeneration without breaking user-facing APIs, protects stable functions via lifecycle guards, and supports three complexity tiers: thin wrappers (1-line delegation), medium functions (conditional parameters), and complex dispatchers (multi-endpoint + post-processing).

## System Structure

### Three-Tier Architecture

```
User Code
    ↓
ct_hazard(query)                    ← User-facing function (stable API)
    ↓
ct_hazard_toxval_search_bulk(query) ← Generated stub (auto-updated from schema)
    ↓
generic_request(...)                ← Core template (batching, auth, error handling)
    ↓
EPA CompTox API
```

**Rationale:** Separation of concerns. User-facing functions provide stable, well-documented APIs. Generated stubs adapt to schema changes. Templates handle infrastructure.

### Component Boundaries

| Component | Responsibility | Location | Lifecycle |
|-----------|---------------|----------|-----------|
| **generic_request()** | HTTP communication: batching, auth, retry, error handling, tidy conversion | `R/z_generic_request.R` | Stable core infrastructure |
| **Generated stubs** | Schema-driven wrappers: endpoint paths, parameters, method/batch config | `R/ct_*_search.R`, `R/ct_*_search_bulk.R` | Auto-regenerated on schema changes |
| **User-facing functions** | Domain logic: parameter validation, multi-endpoint dispatch, post-processing | `R/ct_hazard.R`, `R/ct_bioactivity.R`, `R/ct_lists_all.R` | Manually authored, promoted to `@lifecycle stable` |
| **Lifecycle guards** | Prevent stub generator from overwriting stable functions | `dev/endpoint_eval/05_file_scaffold.R` | Build-time protection |
| **Stub generator** | Parses OpenAPI schemas, produces stubs via `build_function_stub()` | `dev/endpoint_eval/07_stub_generation.R`, `dev/generate_stubs.R` | CI/CD pipeline |

### Data Flow

#### Current State (Some Functions)
```
ct_hazard(query)
  → generic_request(query, endpoint = "hazard/toxval/search/by-dtxsid/", ...)
    → EPA API
```

**Problem:** If stub generator regenerates this function, it overwrites user-facing logic.

#### Target State (v2.2)
```
ct_hazard(query)                               ← User-facing, @lifecycle stable
  → ct_hazard_toxval_search_bulk(query)        ← Generated stub, @lifecycle experimental
    → generic_request(query, endpoint = "...", ...)
      → EPA API
```

**Benefit:** Stub regeneration updates `ct_hazard_toxval_search_bulk()` without affecting `ct_hazard()`. User API remains stable.

## Integration Patterns

### Pattern 1: Thin Wrapper (Simple Delegation)

**When:** User-facing function adds no logic beyond naming/documentation.

**Example:** `ct_hazard()`, `ct_cancer()`, `ct_genotox()`

```r
#' ToxVal hazard data
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param query Character vector of DTXSIDs
#' @return A tibble of ToxVal hazard results
#' @export
ct_hazard <- function(query) {
  ct_hazard_toxval_search_bulk(query = query)
}
```

**Integration points:**
- **Generated stub:** `ct_hazard_toxval_search_bulk()` (experimental, regenerable)
- **User function:** `ct_hazard()` (stable, never regenerated)
- **Post-processing:** None (stub returns tibble directly)

**Migration steps:**
1. Ensure generated stub exists: `ct_hazard_toxval_search_bulk()`
2. Replace `ct_hazard()` body with delegation call
3. Update lifecycle badge to `stable`
4. Verify stub not overwritten by generator (lifecycle guard)

---

### Pattern 2: Medium Wrapper (Conditional Parameters)

**When:** User-facing function adds parameter transformation, projection selection, or conditional branching.

**Example:** `ct_details()`, `ct_lists_all()`

```r
#' Chemical details by DTXSID
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param query Character vector of DTXSIDs
#' @param projection API projection string (default "compact")
#' @return A tibble of chemical detail results
#' @export
ct_details <- function(query, projection = "compact") {
  generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "POST",
    projection = projection
  )
}
```

**Current state:** Calls `generic_request()` directly.

**Target state (v2.2):**
```r
ct_details <- function(query, projection = "compact") {
  ct_chemical_detail_search_by_dtxsid_bulk(query = query, projection = projection)
}
```

**Integration points:**
- **Generated stub:** `ct_chemical_detail_search_by_dtxsid_bulk(query, projection = NULL)`
- **User function:** `ct_details(query, projection = "compact")` — sets default, passes through
- **Post-processing:** None (handled by stub)

**Migration steps:**
1. Verify generated stub accepts `projection` parameter
2. Update `ct_details()` to delegate with parameter passthrough
3. Promote to `@lifecycle stable`

---

### Pattern 3: Complex Dispatcher (Multi-Endpoint + Post-Processing)

**When:** User-facing function routes to different endpoints based on parameters, performs joins, or applies domain-specific transformations.

**Example:** `ct_bioactivity()`, `ct_lists_all()`

#### Subpattern 3A: Multi-Endpoint Dispatch

```r
#' Bioactivity assay data
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param query Character vector of identifiers
#' @param search_type One of "dtxsid", "aeid", "spid", or "m4id"
#' @param annotate Logical; if TRUE, join assay annotation details
#' @return A tibble of bioactivity results
#' @export
ct_bioactivity <- function(
  query,
  search_type = c("dtxsid", "aeid", "spid", "m4id"),
  annotate = FALSE
) {
  search_type <- match.arg(search_type)

  df <- switch(
    search_type,
    "dtxsid" = ct_bioactivity_data_search_bulk(query = query),
    "aeid"   = ct_bioactivity_data_search_by_aeid_bulk(query = query),
    "spid"   = ct_bioactivity_data_search_by_spid_bulk(query = query),
    "m4id"   = ct_bioactivity_data_search_by_m4id_bulk(query = query)
  )

  if (annotate) {
    bioassay_all <- ct_bioactivity_assay()
    df <- dplyr::left_join(df, bioassay_all, by = "aeid")
  }

  return(df)
}
```

**Integration points:**
- **Multiple generated stubs:**
  - `ct_bioactivity_data_search_bulk(query)` — by DTXSID
  - `ct_bioactivity_data_search_by_aeid_bulk(query)` — by assay ID
  - `ct_bioactivity_data_search_by_spid_bulk(query)` — by sample ID
  - `ct_bioactivity_data_search_by_m4id_bulk(query)` — by model ID
  - `ct_bioactivity_assay()` — annotation lookup
- **Dispatch logic:** `switch()` on `search_type`
- **Post-processing:** Optional `left_join()` for annotation

**Migration steps:**
1. Ensure all 4 generated stubs exist
2. Implement dispatch wrapper
3. Test annotation join against stub output schema
4. Promote to `@lifecycle stable`

#### Subpattern 3B: Projection + Coercion

```r
#' All public chemical lists
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param return_dtxsid Logical; return DTXSIDs per list (default FALSE)
#' @param coerce Logical; split comma-separated DTXSIDs into vectors (default FALSE)
#' @return A tibble or named list of lists
#' @export
ct_lists_all <- function(return_dtxsid = FALSE, coerce = FALSE) {
  projection <- if (!return_dtxsid) {
    "chemicallistall"
  } else {
    "chemicallistwithdtxsids"
  }

  df <- ct_chemical_list_all(projection = projection)

  cli::cli_alert_success("{nrow(df)} lists found!")

  if (return_dtxsid & coerce) {
    cli::cli_alert_warning("Coercing DTXSID strings per list to list-column!")
    df <- df %>%
      split(.$listName) %>%
      purrr::map(., as.list) %>%
      purrr::map(., ~ {
        .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ",") %>%
          purrr::pluck(1)
        .x
      })
  } else if (!return_dtxsid & coerce) {
    cli::cli_alert_warning("You need to request DTXSIDs to coerce!")
  }

  return(df)
}
```

**Integration points:**
- **Generated stub:** `ct_chemical_list_all(projection = NULL)`
- **Pre-processing:** Conditional projection selection
- **Post-processing:** Optional split + coerce (tibble → named list of lists)

**Migration steps:**
1. Verify stub accepts `projection` parameter
2. Keep pre-processing logic in wrapper
3. Keep post-processing logic in wrapper
4. Promote to `@lifecycle stable`

## Recommended Patterns by Function Complexity

| Complexity | Criteria | Pattern | Post-Processing in Wrapper |
|------------|----------|---------|----------------------------|
| **Thin** | No parameters beyond query, no transformations | 1-line delegation | No |
| **Medium** | Parameter passthrough, default values, simple conditionals | Delegation + parameter passing | No |
| **Complex** | Multi-endpoint dispatch, joins, type coercion, split logic | Dispatcher + custom logic | Yes |

**Rule:** If a function only changes parameter defaults or selects projections, it's **medium**. If it combines data from multiple endpoints or transforms output structure, it's **complex**.

## Lifecycle Protection Mechanism

### How It Works

**File:** `dev/endpoint_eval/05_file_scaffold.R`

**Function:** `has_protected_lifecycle(path)`

```r
protected_statuses <- c("stable", "maturing", "superseded", "deprecated", "defunct")

has_protected_lifecycle <- function(path) {
  lines <- readLines(path, warn = FALSE)
  badges <- str_extract_all(lines, 'lifecycle::badge\\("([^"]+)"\\)')
  statuses <- str_extract(unlist(badges), '(?<=badge\\(")[^"]+')
  any(tolower(statuses) %in% protected_statuses)
}
```

**Effect:** If `ct_hazard.R` contains `lifecycle::badge("stable")`, stub generator **will not overwrite** it.

**Integration point:** Called in `scaffold_files()` before writing:

```r
if (existed && (overwrite || append)) {
  protected <- has_protected_lifecycle(path)
  if (protected) {
    return(tibble(action = "skipped_lifecycle", written = FALSE))
  }
}
```

### Promotion Workflow

1. **Generated stub created:** `ct_hazard_toxval_search_bulk()` in `R/ct_hazard_toxval_search.R` → `@lifecycle experimental`
2. **User function authored:** `ct_hazard()` in `R/ct_hazard.R` → delegates to stub → `@lifecycle experimental`
3. **Tested and validated:** Function works correctly, tests pass
4. **Promoted:** Change badge to `@lifecycle stable`
5. **Protected:** Stub generator now skips `R/ct_hazard.R` on regeneration

## Build Order Recommendations

### Phase Structure

**Phase 1: Verify Generated Stubs Exist**
- Audit: Which user-facing functions delegate to non-existent stubs?
- Generate: Run `dev/generate_stubs.R` to create missing stubs
- Verify: Stubs callable, accept correct parameters, return expected types

**Phase 2: Migrate Thin Wrappers**
- Target: Functions that currently call `generic_request()` directly with no post-processing
- Pattern: Replace body with delegation call
- Count: ~10 functions (ct_hazard, ct_cancer, ct_genotox, ct_skin_eye, etc.)
- Risk: Low (1-line change, no logic)

**Phase 3: Migrate Medium Wrappers**
- Target: Functions with parameter passthrough or projection selection
- Pattern: Ensure stub accepts parameters, delegate with passthrough
- Count: ~5 functions (ct_details, ct_functional_use_probability, etc.)
- Risk: Low-medium (verify stub parameter compatibility)

**Phase 4: Vertical Slice Complex Functions**
- Target: One complex dispatcher (e.g., `ct_bioactivity()`)
- Pattern: Implement dispatch + annotation join
- Test: Validate against all 4 search types, test annotation join
- Risk: Medium (multi-stub dependency, join schema validation)
- Goal: Prove pattern works before scaling

**Phase 5: Migrate Remaining Complex Functions**
- Target: `ct_lists_all()`, other dispatchers
- Pattern: Apply validated complex pattern
- Risk: Medium (post-processing logic migration)

**Phase 6: Promote to Stable**
- Change lifecycle badges: `experimental` → `stable`
- Verify lifecycle guard prevents overwrite
- Update NAMESPACE via `devtools::document()`

**Phase 7: Clean Build + Tests**
- Run `devtools::check()` → 0 errors/warnings
- Run test suite → all tests pass
- Verify no stub regeneration overwrites stable functions

### Dependency Order

**Must happen first:**
1. Generated stubs exist (from OpenAPI schemas)
2. `generic_request()` stable (already true)

**Can proceed in parallel:**
- Thin wrapper migration (independent functions)
- Medium wrapper migration (independent functions)

**Must happen sequentially:**
1. Complex vertical slice (prove pattern)
2. Remaining complex migrations (apply pattern)
3. Lifecycle promotion (after testing)

### Deferred Work

**Not in v2.2 scope:**
- Post-processing recipe system (#120) — deferred until concrete need surfaces
- Advanced schema handling (ADV-01-04) — pipeline work on hold
- S7 class implementation (#29) — deferred past v2.2

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Architecture | HIGH | Existing code demonstrates three-tier separation, lifecycle guards already implemented |
| Thin migration | HIGH | Pattern proven in 10+ existing stable functions |
| Medium migration | HIGH | `ct_details()` example already uses direct generic_request() call |
| Complex migration | MEDIUM | `ct_bioactivity()` pattern exists but join logic needs validation against stub output schema |
| Lifecycle protection | HIGH | `has_protected_lifecycle()` already prevents overwrites in v2.1 |
| Build order | MEDIUM | Dependencies clear, but unknown blockers may surface during migration |

## Gaps and Risks

### Schema Drift Risk

**Gap:** Generated stub parameters may drift from user function expectations.

**Example:** If OpenAPI schema adds required parameter `new_param`, stub regenerates with new signature, but user function still calls with old signature.

**Mitigation:** Parameter drift detection already exists (`dev/endpoint_eval/08_drift_detection.R`), reports drift in CI.

**Resolution:** Manual review + update user functions when drift detected.

---

### Post-Processing Schema Assumptions

**Gap:** Complex functions assume specific output schema from stubs (e.g., `ct_bioactivity()` joins on `aeid` column).

**Risk:** If stub output schema changes, join breaks.

**Mitigation:**
1. Test complex functions against stub output
2. Add schema validation in wrapper (check column exists before join)
3. Document expected stub output schema in user function

**Example:**
```r
ct_bioactivity <- function(query, search_type = "dtxsid", annotate = FALSE) {
  df <- switch(search_type, "dtxsid" = ct_bioactivity_data_search_bulk(query))

  if (annotate) {
    if (!"aeid" %in% colnames(df)) {
      cli::cli_abort("Stub output missing 'aeid' column required for annotation join")
    }
    bioassay_all <- ct_bioactivity_assay()
    df <- dplyr::left_join(df, bioassay_all, by = "aeid")
  }

  return(df)
}
```

---

### Incomplete Stub Coverage

**Gap:** Some user-facing functions may reference endpoints not yet in OpenAPI schemas.

**Detection:** Run stub generator, check which endpoints produce 0 stubs.

**Resolution:** Either add missing endpoints to schema or temporarily keep user functions calling `generic_request()` directly (with comment explaining why).

## Sources

**Official Codebase:**
- `R/z_generic_request.R` — Core template implementation
- `dev/endpoint_eval/07_stub_generation.R` — Stub generation logic
- `dev/endpoint_eval/05_file_scaffold.R` — Lifecycle protection
- `R/ct_bioactivity.R` — Complex dispatcher pattern
- `R/ct_hazard.R` — Thin wrapper pattern
- `R/ct_details.R` — Medium wrapper with projection parameter
- `R/ct_lists_all.R` — Post-processing pattern

**Documentation:**
- `.claude/CLAUDE.md` — Package architecture overview
- `.planning/PROJECT.md` — v2.2 milestone context

**Confidence:** HIGH (all findings from authoritative codebase sources)
