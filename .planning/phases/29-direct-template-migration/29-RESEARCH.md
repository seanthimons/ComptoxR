# Phase 29: Direct Template Migration - Research

**Researched:** 2026-03-11
**Domain:** R package refactoring — migrating hand-written httr2 wrappers to generic_request() template
**Confidence:** HIGH

## Summary

Phase 29 completes the thin wrapper migration by handling the final three medium-complexity functions: `ct_properties()` (dual-mode dispatcher with coercion logic), `.prop_ids()` (helper function), and `ct_related()` (endpoint with server-switching and inclusive filtering). Unlike Phase 28's thin wrappers which were pure pass-throughs, these functions contain business logic that must be preserved through hook integration or direct migration.

The research confirms that all necessary infrastructure already exists from Phase 28: hook system, stub generator with hook support, test generator with hook awareness, and the proven path_params pattern for range queries. The migration strategy follows Phase 28's clean break pattern (delete wrappers, document in NEWS.md, no deprecation shims) with one exception: `ct_related()` undergoes migration (not deletion) due to its lifecycle::questioning badge.

**Primary recommendation:** Delete `ct_properties()` and `.prop_ids()` entirely — users call existing generated stubs directly. For `ct_related()`, create experimental version alongside original for head-to-head validation before swap.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **ct_properties deletion:** Users call generated stubs directly
  - Compound search: `ct_chemical_property_experimental_search_bulk()` and `ct_chemical_property_predicted_search_bulk()`
  - Range search: `ct_chemical_property_experimental_search_by_range()` and `ct_chemical_property_predicted_search_by_range()`
  - Verify range stubs work with path_params before deletion
  - Add coerce hook parameter following Phase 28 annotate hook pattern
- **.prop_ids() deletion:** Users call `ct_chemical_property_predicted_name()` and `ct_chemical_property_experimental_name()` stubs
- **ct_related migration:** Use `generic_request(batch_limit=1)` for per-ID loop, inline server switching with on.exit cleanup, preserve inclusive filtering in post-processing
- **Breaking change strategy:** Same clean break as Phase 28 (no deprecation shims) for ct_properties and .prop_ids; ct_related keeps its name (migration, not deletion)

### Claude's Discretion
- Exact coerce hook implementation for property search (split by propertyId)
- How generic_request handles the related-substances endpoint path structure
- Error handling approach in ct_related_EXP (generic_request's built-in vs custom)
- Whether to preserve cli messaging from original ct_related

### Deferred Ideas (OUT OF SCOPE)
- Auditing all 400+ generated stubs for hook opportunities — Phase 30 or future work
- ct_related endpoint stability assessment — depends on EPA API roadmap, not our code
</user_constraints>

## Standard Stack

### Core Migration Infrastructure (from Phase 28)
| Component | Location | Purpose | Status |
|-----------|----------|---------|--------|
| generic_request() | R/z_generic_request.R | Centralized API request template | ✅ Production |
| Hook system | R/hook_registry.R | Declarative customization | ✅ Operational |
| Hook config | inst/hook_config.yml | YAML-based hook declarations | ✅ Loaded at .onLoad() |
| Stub generator | dev/generate_stubs.R | Generates functions with hook support | ✅ Extended in 28-04 |
| Test generator | dev/generate_tests.R | Generates tests with hook variant coverage | ✅ Extended in 28-05 |

### Testing Infrastructure
| Component | Version | Configuration |
|-----------|---------|---------------|
| testthat | 3.0.0+ | Config/testthat/edition: 3, parallel: true |
| vcr | Latest | Cassette recording/replay |
| Cassette location | tests/testthat/fixtures/ | YAML files |

**No installation needed:** All infrastructure operational from Phase 28.

## Architecture Patterns

### Recommended Approach

#### Pattern 1: Delete Wrapper, Users Call Generated Stubs Directly
**What:** Remove hand-written wrapper function entirely, document migration path in NEWS.md
**When to use:** Function is pure pass-through or logic can be declaratively expressed via hooks
**ct_properties compound search path:**
```r
# OLD (to be deleted)
ct_properties(search_param = "compound", query = dtxsids, coerce = TRUE)

# NEW (existing stubs)
ct_chemical_property_experimental_search_bulk(query = dtxsids)  # Returns tibble
ct_chemical_property_predicted_search_bulk(query = dtxsids)     # Returns tibble

# With coerce hook (to be added)
ct_chemical_property_experimental_search_bulk(query = dtxsids, coerce = TRUE)
# Returns: list(propertyId1 = df1, propertyId2 = df2, ...)
```

**ct_properties range search path:**
```r
# OLD (to be deleted)
ct_properties(search_param = "property", query = "MolWeight", range = c(100, 500))

# NEW (existing stubs with path_params)
ct_chemical_property_experimental_search_by_range(propertyName = "MolWeight", start = 100, end = 500)
ct_chemical_property_predicted_search_by_range(propertyId = "MolWeight", start = 100, end = 500)
```

**.prop_ids() deletion:**
```r
# OLD (to be deleted)
.prop_ids()  # Internal helper

# NEW (existing stubs)
ct_chemical_property_experimental_name()  # Returns tibble of experimental property names
ct_chemical_property_predicted_name()     # Returns tibble of predicted property names

# Users combine if needed
bind_rows(
  ct_chemical_property_experimental_name(),
  ct_chemical_property_predicted_name()
) %>% distinct(name, propertyId)
```

#### Pattern 2: Experimental Function for Head-to-Head Validation
**What:** Create `{function}_EXP()` in same file, validate against original, then swap
**When to use:** Function contains complex logic or lifecycle badge requires stability proof
**ct_related migration:**
```r
# R/ct_related.R structure during migration
ct_related <- function(query, inclusive = FALSE) {
  # ORIGINAL IMPLEMENTATION (unchanged)
  # ... existing httr2 code ...
}

ct_related_EXP <- function(query, inclusive = FALSE) {
  # NEW IMPLEMENTATION using generic_request

  # Inline server switch with cleanup
  old_server <- Sys.getenv("ctx_burl")
  ctx_server(9)
  on.exit(Sys.setenv(ctx_burl = old_server), add = TRUE)

  # generic_request handles per-ID loop via batch_limit=1
  results <- generic_request(
    query = query,
    endpoint = "related-substances/search/by-dtxsid",
    method = "GET",
    batch_limit = 1,
    auth = FALSE,  # Verify auth requirement
    tidy = FALSE   # Need list structure for post-processing
  )

  # Post-process: extract data, filter parent, apply inclusive logic
  data <- results %>%
    map(~ pluck(., "data")) %>%
    map(~ map(., ~ keep(.x, names(.x) %in% c("dtxsid", "relationship")) %>% as_tibble()) %>% list_rbind()) %>%
    list_rbind(names_to = "query") %>%
    rename(child = dtxsid) %>%
    filter(child != query)  # Remove parent

  if (inclusive && length(query) > 1) {
    data <- filter(data, query %in% query & child %in% query)
  }

  return(data)
}
```

**After validation:** Delete `ct_related`, rename `ct_related_EXP` to `ct_related`.

### Pattern 3: Coerce Hook for Property Search
**Follows Phase 28 annotate hook pattern:**

**inst/hook_config.yml addition:**
```yaml
ct_chemical_property_experimental_search_bulk:
  extra_params:
    coerce:
      default: "FALSE"
      type: "logical"
      description: "Split results by propertyId into named list of data frames"
  post_response:
    - coerce_by_property_id

ct_chemical_property_predicted_search_bulk:
  extra_params:
    coerce:
      default: "FALSE"
      type: "logical"
      description: "Split results by propertyId into named list of data frames"
  post_response:
    - coerce_by_property_id
```

**R/hooks/property_hooks.R (new file):**
```r
#' Coerce property results by propertyId
#'
#' Post-response hook that splits property search results by propertyId
#' when coerce=TRUE, returning a named list of data frames.
#'
#' @param data Hook data structure with list(result = ..., params = list(coerce = ...))
#' @return Original tibble or named list split by propertyId
#' @noRd
coerce_by_property_id <- function(data) {
  if (!isTRUE(data$params$coerce)) {
    return(data$result)
  }

  # Split by propertyId column
  result <- data$result %>%
    split(.$propertyId)

  cli::cli_alert_success("Coerced {length(result)} property groups!")

  return(result)
}
```

### Pattern 4: Path Parameter Validation (Already Working)
**Existing generated stubs:**
```r
# R/ct_chemical_property_experimental_by-range.R (line 16)
ct_chemical_property_experimental_search_by_range <- function(propertyName, start = NULL, end = NULL) {
  result <- generic_request(
    query = propertyName,
    endpoint = "chemical/property/experimental/search/by-range/",
    method = "GET",
    batch_limit = 1,
    path_params = c(start = start, end = end)  # ✅ Already supports path_params
  )

  return(result)
}
```

**generic_request validation (R/z_generic_request.R:203-210):**
```r
# Path parameters cannot be used with batching
if (!is.null(path_params) && length(path_params) > 0) {
  if (batch_limit > 1 || (length(query) > 1 && batch_limit != 0)) {
    cli::cli_abort(
      "Cannot use path_params with batching. Path parameter endpoints do not support batch queries."
    )
  }
}
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-ID API loops | Manual map with httr2 | `generic_request(batch_limit=1)` | Built-in error handling, progress tracking, batching logic |
| Server URL switching | Manual req_url modification | `ctx_server()` + `on.exit()` | Environment-based, cleanup guaranteed |
| Property result coercion | Inline split logic | Hook system | Declarative, testable, generator-integrated |
| Range query path building | Manual req_url_path_append | `path_params` parameter | Validated, standardized pattern |
| VCR cassette management | Manual cassette naming | Test generator conventions | Automatic variant coverage |

**Key insight:** Phase 28 infrastructure eliminates need for custom httr2 code. All three functions can migrate to generic_request() with either hooks (property coercion) or direct calls (related substances).

## Common Pitfalls

### Pitfall 1: Forgetting Server Cleanup in ct_related
**What goes wrong:** `ctx_server(9)` changes global state, subsequent API calls fail if not reset
**Why it happens:** Server 9 is dashboard scraping endpoint, not main API
**How to avoid:** Use `on.exit()` immediately after `ctx_server(9)` call
**Warning signs:**
```r
# ❌ WRONG - Leaves server in scraping mode
ctx_server(9)
result <- generic_request(...)
ctx_server(1)  # Could be skipped if generic_request errors

# ✅ CORRECT - Guaranteed cleanup
old_server <- Sys.getenv("ctx_burl")
ctx_server(9)
on.exit(Sys.setenv(ctx_burl = old_server), add = TRUE)
result <- generic_request(...)
```

### Pitfall 2: Mismatching Hook Config with Stub Signature
**What goes wrong:** CI drift check fails if hook config declares parameter not in generated stub
**Why it happens:** Stub regeneration after hook config changes
**How to avoid:** Update `inst/hook_config.yml` → run `dev/generate_stubs.R` → verify with `dev/check_hook_config.R`
**Warning signs:** Build fails with "extra_param 'coerce' not found in function signature"

### Pitfall 3: Assuming path_params Works with Batching
**What goes wrong:** `generic_request()` aborts with validation error
**Why it happens:** Path parameter endpoints are inherently single-query (URL structure: `/by-range/{property}/{start}/{end}`)
**How to avoid:** Always use `batch_limit = 1` with `path_params`
**Warning signs:** Error message "Cannot use path_params with batching"

### Pitfall 4: Breaking Test Cassettes After Function Rename
**What goes wrong:** Tests reference old function name, cassettes become orphaned
**Why it happens:** `test-ct_prop.R` calls `ct_prop()` which no longer exists after deletion
**How to avoid:** Update test files to call new generated stub names before deleting wrapper
**Warning signs:** Test failures with "could not find function ct_properties"

### Pitfall 5: Forgetting to Document Migration in NEWS.md
**What goes wrong:** Users upgrade package, code breaks with no migration guide
**Why it happens:** Phase 28 established clean break pattern (no deprecation warnings)
**How to avoid:** Add migration examples to NEWS.md BEFORE deletion commit
**Warning signs:** User confusion, GitHub issues asking "where did ct_properties go?"

## Code Examples

Verified patterns from existing infrastructure:

### Example 1: Property Coerce Hook (Following Phase 28 Pattern)
```r
# Source: R/hooks/bioactivity_hooks.R:12-24 (annotate_assay_if_requested pattern)
# Adapted for property search coercion

#' Coerce property results by propertyId
#'
#' Post-response hook that splits property search results by propertyId
#' when coerce=TRUE.
#'
#' @param data Hook data structure with list(result = ..., params = list(coerce = ...))
#' @return Original tibble or named list split by propertyId
#' @noRd
coerce_by_property_id <- function(data) {
  if (!isTRUE(data$params$coerce)) {
    return(data$result)
  }

  # Split tibble by propertyId column
  result <- data$result %>%
    split(.$propertyId)

  cli::cli_alert_success("Coerced {length(result)} property groups!")

  return(result)
}
```

### Example 2: Server Switch with Cleanup (ct_related Pattern)
```r
# Source: R/ct_related.R:44 and 107 (current implementation)
# Migrated to generic_request pattern

ct_related_EXP <- function(query, inclusive = FALSE) {
  # Validation
  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector of DTXSIDs.")
  }

  if (inclusive && length(query) == 1) {
    cli::cli_abort("Inclusive option only valid for multiple compounds")
  }

  # Display info (preserve user experience)
  cli::cli_rule(left = "Related substances payload options")
  cli::cli_dl(c(
    "Number of compounds" = "{length(query)}",
    "Inclusive" = "{inclusive}"
  ))
  cli::cli_rule()
  cli::cli_end()

  # Server switch with guaranteed cleanup
  old_server <- Sys.getenv("ctx_burl")
  ctx_server(9)
  on.exit(Sys.setenv(ctx_burl = old_server), add = TRUE)

  # generic_request handles per-ID loop with batch_limit=1
  # Endpoint uses query parameter 'id' (not path-based)
  results <- generic_request(
    query = query,
    endpoint = "related-substances/search/by-dtxsid",
    method = "GET",
    batch_limit = 1,
    auth = FALSE,
    tidy = FALSE,
    id = NULL  # Will be populated per query item
  )

  # Post-process: extract nested data, filter parent compound
  data <- results %>%
    purrr::map(~ purrr::pluck(., "data")) %>%
    purrr::map(~ purrr::map(., ~ purrr::keep(.x, names(.x) %in% c("dtxsid", "relationship")) %>%
                              tibble::as_tibble()) %>%
                 purrr::list_rbind()) %>%
    purrr::list_rbind(names_to = "query") %>%
    dplyr::rename(child = dtxsid) %>%
    dplyr::filter(child != query)

  # Apply inclusive filtering if requested
  if (inclusive) {
    data <- dplyr::filter(data, query %in% query & child %in% query)
  }

  return(data)
}
```

### Example 3: Path Params Range Query (Already Working)
```r
# Source: R/ct_chemical_property_experimental_by-range.R:16-28
# VERIFY THIS WORKS before deleting ct_properties

ct_chemical_property_experimental_search_by_range <- function(propertyName, start = NULL, end = NULL) {
  result <- generic_request(
    query = propertyName,
    endpoint = "chemical/property/experimental/search/by-range/",
    method = "GET",
    batch_limit = 1,
    path_params = c(start = start, end = end)
  )

  return(result)
}

# Generates URL: /chemical/property/experimental/search/by-range/{propertyName}/{start}/{end}
```

### Example 4: Hook Config Entry (Following Phase 28 Convention)
```yaml
# Source: inst/hook_config.yml:42-49 (ct_bioactivity_data_search_bulk pattern)
# Adapted for property search

ct_chemical_property_experimental_search_bulk:
  extra_params:
    coerce:
      default: "FALSE"
      type: "logical"
      description: "Split results by propertyId into named list of data frames"
  post_response:
    - coerce_by_property_id

ct_chemical_property_predicted_search_bulk:
  extra_params:
    coerce:
      default: "FALSE"
      type: "logical"
      description: "Split results by propertyId into named list of data frames"
  post_response:
    - coerce_by_property_id
```

### Example 5: NEWS.md Migration Documentation (Phase 28 Pattern)
```markdown
# Source: NEWS.md:14-36 (Phase 28 breaking changes section)

#### Breaking changes

**Phase 29 Direct Template Migration Complete:**

**ct_properties removed:**
- Compound search path:
  * `ct_properties(search_param = "compound", query = dtxsids)` →
    `ct_chemical_property_experimental_search_bulk(query = dtxsids)` or
    `ct_chemical_property_predicted_search_bulk(query = dtxsids)`
  * Add `coerce = TRUE` to split results by propertyId into named list
- Range search path:
  * `ct_properties(search_param = "property", query = "MolWeight", range = c(100, 500))` →
    `ct_chemical_property_experimental_search_by_range(propertyName = "MolWeight", start = 100, end = 500)` or
    `ct_chemical_property_predicted_search_by_range(propertyId = "MolWeight", start = 100, end = 500)`

**.prop_ids() removed:**
- `ct_chemical_property_experimental_name()` and `ct_chemical_property_predicted_name()`
  provide same functionality as direct API stubs

**ct_related migrated to generic_request:**
- Function name unchanged, behavior identical
- Improved error handling and progress tracking from generic_request infrastructure
```

## State of the Art

| Pattern | Phase 28 Approach | Phase 29 Status | Notes |
|---------|-------------------|-----------------|-------|
| Thin wrapper deletion | Delete, document in NEWS.md | ✅ Apply to ct_properties, .prop_ids | Proven pattern |
| Hook-based customization | YAML config + primitives | ✅ Apply coerce hook | Follows annotate pattern |
| Experimental migration | Not needed (thin wrappers) | ✅ Apply to ct_related | First complex migration |
| Path params | Generated stubs support | ✅ Verify range queries work | Already functional |
| Server switching | Manual in wrappers | ⚠️ Inline with on.exit | First use of server switch in generic_request |
| CI drift detection | dev/check_hook_config.R | ✅ Validates new hooks | Operational from 28-04 |

**Deprecated/outdated:**
- Manual httr2 code: Replaced by generic_request() template
- Dual-mode dispatcher functions: Replaced by specific generated stubs + hooks
- Internal helper functions: Replaced by direct stub calls

**Current best practice (as of Phase 28):**
- Hook system for customization (not hand-written wrappers)
- Generated stubs as primary API (not wrapper functions)
- YAML-based configuration (not inline logic)
- Clean breaks for deprecation (not shim functions)

## Validation Architecture

> **Nyquist validation ENABLED** (workflow.nyquist_validation: true in .planning/config.json)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.0.0+ |
| Config file | tests/testthat.R (edition 3, parallel: true) |
| Quick run command | `devtools::test_file("tests/testthat/test-ct_prop.R")` |
| Full suite command | `devtools::test()` |

### Phase Requirements → Test Map

**No formal requirements defined for Phase 29.** Validation focuses on behavioral equivalence and migration safety.

| Migration | Behavior | Test Type | Automated Command | File Exists? |
|-----------|----------|-----------|-------------------|-------------|
| ct_properties deletion | Verify range stubs work with path_params | integration | `devtools::test_file("tests/testthat/test-ct_chemical_property_experimental_by-range.R")` | ❌ Wave 0 |
| ct_properties deletion | Verify bulk stubs return tibbles | unit | `devtools::test_file("tests/testthat/test-ct_chemical_property_experimental_search.R")` | ✅ Generated |
| Coerce hook | Split by propertyId returns named list | unit | `devtools::test_file("tests/testthat/test-property_hooks.R")` | ❌ Wave 0 |
| ct_related migration | ct_related_EXP matches ct_related output | integration | `devtools::test_file("tests/testthat/test-ct_related.R")` | ✅ Existing, needs update |
| ct_related migration | Server cleanup executes on error | unit | `devtools::test_file("tests/testthat/test-ct_related.R")` | ✅ Existing, needs new tests |

### Sampling Rate
- **Per task commit:** Quick validation of affected function
- **Per wave merge:** Full suite (`devtools::test()`)
- **Phase gate:** Full suite green + manual smoke test of migration paths before documenting in NEWS.md

### Wave 0 Gaps
- [ ] `tests/testthat/test-ct_chemical_property_experimental_by-range.R` — validates path_params pattern (REQ: range stub verification)
- [ ] `tests/testthat/test-property_hooks.R` — covers coerce hook primitive (REQ: coerce hook validation)
- [ ] Update `tests/testthat/test-ct_related.R` — add ct_related_EXP head-to-head tests and server cleanup tests (REQ: migration validation)
- [ ] Update `tests/testthat/test-ct_prop.R` — update to call new generated stubs after ct_properties deletion (REQ: migration regression catch)

## Open Questions

1. **ct_related endpoint authentication**
   - What we know: Original uses `auth = FALSE` implicitly (no x-api-key header in request construction)
   - What's unclear: Whether server 9 endpoint requires authentication
   - Recommendation: Test with `auth = FALSE`, verify cassette recording succeeds

2. **ct_related query parameter structure**
   - What we know: Original builds URL with `req_url_query('id' = id)` (not path-based)
   - What's unclear: How generic_request handles single query param with `batch_limit = 1`
   - Recommendation: Check if generic_request(batch_limit=1) uses path append or query params; may need endpoint pattern clarification

3. **Property coerce hook interaction with tidy flag**
   - What we know: Coerce splits tibble by propertyId column into named list
   - What's unclear: Whether this breaks downstream code expecting tibbles
   - Recommendation: Default `coerce = FALSE` maintains backward compatibility; users opt-in for list coercion

4. **Test cassette regeneration scope**
   - What we know: ct_prop.R has single basic test, ct_related.R has single/example/error tests
   - What's unclear: Whether range query stubs already have cassettes
   - Recommendation: Audit existing cassettes before deletion, record missing ones if needed

## Sources

### Primary (HIGH confidence)
- Phase 28 implementation files (R/hook_registry.R, R/hooks/, inst/hook_config.yml) — Hook system architecture
- generic_request() source (R/z_generic_request.R) — Template capabilities and path_params validation
- Existing generated stubs (R/ct_chemical_property*.R) — Confirmed path_params pattern works
- Phase 28 NEWS.md entries (lines 9-49) — Established breaking change documentation pattern
- Test infrastructure (tests/testthat/, DESCRIPTION) — testthat 3.0.0+ with VCR cassettes

### Secondary (MEDIUM confidence)
- CONTEXT.md user decisions (gathered 2026-03-11) — Locked migration strategy
- STATE.md Phase 28 completion notes (lines 176-242) — Hook system operational state
- CLAUDE.md project conventions (lines 71-99, 173-212) — Testing patterns, refactoring status

### Tertiary (LOW confidence)
- None — All findings verified against actual source code

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All infrastructure operational from Phase 28, no new dependencies
- Architecture patterns: HIGH - Direct code inspection confirms path_params and hook patterns work
- Pitfalls: HIGH - Derived from Phase 28 experience and generic_request validation logic
- Migration strategy: HIGH - User decisions locked, existing stubs verified to exist

**Research date:** 2026-03-11
**Valid until:** 90 days (stable infrastructure, unlikely to change)

**Known limitations:**
- ct_related endpoint stability unknown (server 9 is dashboard scraping endpoint, not official API)
- Query parameter vs path-based GET for ct_related needs clarification during implementation
- No formal requirements defined for Phase 29 — validation is migration safety focused
