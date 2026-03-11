# Phase 5: Resolver Integration Fix - Research

**Researched:** 2026-01-28
**Domain:** R code generation / API stub generation
**Confidence:** HIGH

## Summary

This phase fixes bugs in the stub generation template (lines 275-350 in `dev/endpoint_eval/07_stub_generation.R`) that generates resolver-wrapped functions for cheminformatics endpoints. The template currently has four critical bugs:

1. **Line 281 & 297**: Uses snake_case `id_type` in generated function signature and documentation, but chemi_resolver_lookup() expects camelCase `idType`
2. **Line 328**: Calls `chemi_resolver_lookup(query = query, id_type = id_type)` using non-existent parameter name
3. **Line 337**: Checks `nrow(resolved) == 0` but chemi_resolver_lookup returns a list (with tidy=FALSE), not a tibble
4. **Lines 337-355**: Assumes resolver returns a tibble and tries to iterate with `seq_len(nrow(resolved))` and access columns like `row$dtxsid`

The correct approach is to call resolver with `idType` (camelCase) and check list emptiness with `length()`, not `nrow()`.

**Primary recommendation:** Replace all four instances of incorrect parameter/return handling in the template to match chemi_resolver_lookup's actual signature and behavior.

## Standard Stack

This is not a library/framework issue - this is an internal code generation bug. The relevant code is already in the codebase.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| glue | Current | String interpolation for code generation | R standard for template-based code generation |
| purrr | Current | Functional programming (map, pluck) | Tidyverse standard for list operations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| cli | Current | User-facing warnings/messages | All user communication in generated stubs |

## Architecture Patterns

### Pattern 1: Checking List Emptiness in R
**What:** R uses `length()` to check if a list is empty, not `nrow()`
**When to use:** When working with list return types (tidy=FALSE from generic_request)
**Example:**
```r
# Source: https://www.tutorialkart.com/r-tutorial/r-check-if-list-is-empty/
# CORRECT for lists
if (length(my_list) == 0) {
  cli::cli_warn("No results")
  return(NULL)
}

# WRONG - nrow() is for data.frames/tibbles
if (nrow(my_list) == 0) {  # ERROR: object is not a matrix
  return(NULL)
}
```

### Pattern 2: R Parameter Naming Conventions
**What:** R function parameters can use either snake_case or camelCase, but must match the actual function signature
**When to use:** When calling existing functions - always use their exact parameter names
**Example:**
```r
# Source: R/chemi_resolver_lookup.R line 17
chemi_resolver_lookup <- function(query, idType = "AnyId", fuzzy = "Not", mol = FALSE)

# CORRECT - matches signature
result <- chemi_resolver_lookup(query = ids, idType = "DTXSID")

# WRONG - parameter doesn't exist
result <- chemi_resolver_lookup(query = ids, id_type = "DTXSID")  # unused argument error
```

### Pattern 3: Understanding tidy=FALSE Return Types
**What:** When `tidy=FALSE`, generic_request/generic_chemi_request returns a list, not a tibble
**When to use:** Always check function documentation for return type
**Example:**
```r
# Source: R/chemi_resolver_lookup.R lines 23-36
result <- generic_request(
  query = query,
  endpoint = "resolver/lookup",
  tidy = FALSE,  # Returns list, not tibble
  options = options
)
# Result is a list, not a data.frame/tibble
# Use length() to check emptiness
# Use list indexing to access elements
```

### Anti-Patterns to Avoid
- **Using nrow() on lists**: R error "object is not a matrix". Lists use `length()`, data.frames use `nrow()`
- **Assuming return type without checking tidy parameter**: Always verify if function returns list or tibble
- **Mismatching parameter names**: Parameter names are case-sensitive; id_type != idType

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Checking if list is empty | Custom null/NA checks | `length(x) == 0` | Built-in R primitive, handles all edge cases |
| Iterating over list elements | Manual indexing loops | `purrr::map()` or `lapply()` | Already used elsewhere in codebase |

**Key insight:** R's type system is not as strict as other languages - a function that looks like it returns a tibble may actually return a list depending on parameters. Always verify return type from documentation or source code.

## Common Pitfalls

### Pitfall 1: Parameter Name Mismatch (Lines 281, 297, 328)
**What goes wrong:** Generated code uses `id_type` (snake_case) but chemi_resolver_lookup expects `idType` (camelCase)
**Why it happens:** Template author assumed snake_case convention without checking actual function signature
**How to avoid:** Always verify actual function signature before generating calls to it
**Warning signs:**
- "unused argument (id_type = ...)" errors at runtime
- Functions that accept the call but ignore the parameter
- Code that works with defaults but fails when parameter is specified

### Pitfall 2: Using nrow() on List Return (Line 337)
**What goes wrong:** Code calls `nrow(resolved)` but resolved is a list, not a data.frame
**Why it happens:** Assuming tidy=FALSE still returns a tibble
**How to avoid:** Check what `tidy=FALSE` actually returns - it's documented in generic_request
**Warning signs:**
- Runtime error: "object is not a matrix or data frame"
- Code that works with tidy=TRUE but fails with tidy=FALSE

### Pitfall 3: Treating List as Tibble (Lines 337-355)
**What goes wrong:** Code uses tibble operations (`seq_len(nrow())`, `row$column`) on a list
**Why it happens:** Not understanding difference between list and data.frame return types
**How to avoid:** When tidy=FALSE, expect a raw list structure - check actual return format
**Warning signs:**
- Accessing columns with $ on non-data.frame objects
- Using nrow() without first verifying object is matrix/data.frame

### Pitfall 4: Default Value Passthrough
**What goes wrong:** User function signature uses default `id_type = "AnyId"` but passes wrong parameter name to resolver
**Why it happens:** Default is correct but parameter name in call is wrong
**How to avoid:** Match both parameter name AND default value to target function
**Warning signs:**
- Defaults work but explicit values fail
- Function silently ignores user-provided values

## Code Examples

Verified patterns from actual source code:

### Correct chemi_resolver_lookup Call
```r
# Source: R/chemi_resolver_lookup.R line 17
# Function signature (camelCase idType)
chemi_resolver_lookup <- function(query, idType = "AnyId", fuzzy = "Not", mol = FALSE)

# CORRECT generated call (matches signature)
resolved <- chemi_resolver_lookup(query = query, idType = idType)

# WRONG (current bug in template line 328)
resolved <- chemi_resolver_lookup(query = query, id_type = id_type)
```

### Correct List Emptiness Check
```r
# Source: R/chemi_predict.R lines 33-40
# Example from existing resolver-using function
resolved_chemicals <- chemi_resolver_lookup(query)

# CORRECT - uses length() for lists
if (length(resolved_chemicals) == 0) {
  cli::cli_abort("No chemicals resolved for the given query.")
  return(NULL)
}

# WRONG (current bug in template line 337)
if (nrow(resolved) == 0) {
  cli::cli_warn("No chemicals could be resolved")
  return(NULL)
}
```

### Understanding chemi_resolver_lookup Return Type
```r
# Source: R/chemi_resolver_lookup.R lines 23-36
# When tidy=FALSE (the current setting), returns raw list
result <- generic_request(
  query = query,
  endpoint = "resolver/lookup",
  method = "GET",
  batch_limit = 0,
  server = "chemi_burl",
  auth = FALSE,
  tidy = FALSE,  # <-- Returns list, NOT tibble
  options = options
)
return(result)  # This is a list

# Therefore:
# - Use length(result) to check emptiness
# - Use list operations (purrr::map, lapply) to process
# - Do NOT use nrow(), row$column, or tibble operations
```

### Correct Function Signature for Generated Stubs
```r
# CORRECT (should be in template line 281)
fn_signature_resolver <- paste0('query, idType = "AnyId"', additional_sig)

# WRONG (current bug)
fn_signature_resolver <- paste0('query, id_type = "AnyId"', additional_sig)
```

### Correct Roxygen Documentation
```r
# CORRECT (should be in template line 297)
resolver_param_docs <- paste0(
  "#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)\n",
  "#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)\n"
)

# WRONG (current bug)
resolver_param_docs <- paste0(
  "#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)\n",
  "#' @param id_type Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)\n"
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom httr2 calls | generic_chemi_request template | Phase 6 (40b4b77) | Centralized request handling |
| Manual resolver wrapping | Stub generation template | Commit a0013c3 | Automated resolver wrapping introduced bugs |

**Deprecated/outdated:**
- None - this is a bug fix, not a deprecation

**Context:**
The resolver wrapping template was added in commit a0013c3 ("Add resolver wrapping for Chemical schema endpoints"). However, it was implemented with incorrect assumptions about parameter naming and return types. This phase fixes those assumptions to match actual function behavior.

## Open Questions

None - all issues are well-understood from examining source code.

## Sources

### Primary (HIGH confidence)
- `R/chemi_resolver_lookup.R` - Actual function signature (line 17: `idType` is camelCase)
- `R/chemi_resolver_lookup.R` - Return type verification (line 30: `tidy = FALSE` returns list)
- `R/chemi_predict.R` - Working example of resolver usage (lines 33-40: uses `length()`)
- `R/chemi_cluster.R` - Working example with idType parameter (line 21: `id_type = 'DTXSID'`)
- `dev/endpoint_eval/07_stub_generation.R` - Template with bugs (lines 281, 297, 328, 337)
- `R/z_generic_request.R` - Documentation of tidy parameter behavior (lines 16-17, 339-344)

### Secondary (MEDIUM confidence)
- [R: Check if List is Empty Tutorial](https://www.tutorialkart.com/r-tutorial/r-check-if-list-is-empty/) - Verified with source code
- [Tidyverse Style Guide - Syntax](https://style.tidyverse.org/syntax.html) - snake_case convention context
- [Best Coding Practices for R - Naming Conventions](https://bookdown.org/content/d1e53ac9-28ce-472f-bc2c-f499f18264a3/names.html) - R naming convention background

## Metadata

**Confidence breakdown:**
- Bug identification: HIGH - All four bugs verified by examining source code
- Correct solution: HIGH - Verified by checking working examples (chemi_predict.R, chemi_cluster.R)
- Return type behavior: HIGH - Verified by reading generic_request source and chemi_resolver_lookup implementation
- Parameter naming: HIGH - Verified by reading chemi_resolver_lookup function signature

**Research date:** 2026-01-28
**Valid until:** 90 days (stable codebase, internal bug fix)

## Affected Functions

**Currently generated stubs using resolver template:**
Based on git history (commit a0013c3 "Add resolver wrapping for Chemical schema endpoints"), the template is used to generate stubs for endpoints with `needs_resolver = TRUE` flag.

**Search results:**
```bash
$ grep -l "nrow(resolved)" R/chemi_*.R
No files with nrow(resolved) pattern found

$ grep -l "id_type = id_type" R/chemi_*.R
No files with id_type = id_type pattern found
```

**Finding:** No generated stubs currently exist with these bugs. This suggests:
1. The resolver template exists but hasn't been used to generate stubs yet, OR
2. Generated stubs were already manually fixed, OR
3. The generation process hasn't been run since the template was created

**Action required:** When regenerating stubs (VAL-01), need to identify which endpoints have `needs_resolver = TRUE` flag in the endpoint evaluation tibble.

## Additional Context

**Why chemi_resolver_lookup uses camelCase:**
The cheminformatics API uses camelCase in its JSON payloads (as seen in generic_chemi_request usage). The resolver function mirrors the API's parameter naming convention for consistency, even though this differs from the Tidyverse snake_case preference.

**Why tidy=FALSE:**
The resolver returns raw API response structure because it needs to be transformed into Chemical object format for downstream chemi endpoints. The raw list structure is more flexible than a flattened tibble.
