# Phase 9: Integration and Validation - Research

**Researched:** 2026-01-29
**Domain:** OpenAPI stub generation integration, R package development, regression testing
**Confidence:** HIGH

## Summary

Phase 9 integrates all completed work from Phases 7-8 (version detection, Swagger 2.0 body extraction, reference resolution) and validates it works end-to-end by regenerating function stubs for three microservice APIs (AMOS, RDKit, Mordred). This is a validation and integration phase rather than new feature development.

The codebase uses a pipeline architecture for stub generation:
1. Schema parsing (`04_openapi_parser.R`) - ALREADY wired with version detection (Phase 7)
2. Parameter extraction (`06_param_parsing.R`) - utilities for parameter documentation
3. Stub generation (`07_stub_generation.R`) - template-based code generation with empty POST detection
4. File output (`05_file_scaffold.R`) - writes generated R files to package

Key insight: Phases 7-8 already integrated version detection and reference resolution into the parsing pipeline. Phase 9 is about VALIDATION - proving the integration works correctly by regenerating stubs and checking for regressions.

**Primary recommendation:** Focus on validation scripts, before/after comparison, and documentation. The code integration is complete; this phase verifies correctness.

## Standard Stack

### Core (Already in codebase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| jsonlite | Latest | Parse OpenAPI/Swagger schemas | Standard R JSON parser |
| purrr | Latest | Functional programming helpers | Tidyverse standard for iteration |
| dplyr/tibble | Latest | Data manipulation | Tidyverse standard for data frames |
| stringr | Latest | String manipulation | Tidyverse standard for strings |
| cli | Latest | Terminal UI and error messages | Modern R CLI framework used throughout |
| glue | Latest | String interpolation for code generation | Template-based code generation |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| testthat | Latest | Unit testing | If writing formal tests (currently manual) |
| diffobj | Latest | Object comparison | For before/after stub comparison |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual verification scripts | testthat formal tests | Current approach works well for one-time validation; formal tests needed for CI/CD |
| Visual comparison | Automated diff tools | Manual review catches semantic issues automated tools miss |

**Installation:**
All dependencies already in DESCRIPTION. No new packages needed.

## Architecture Patterns

### Recommended Project Structure (Already Implemented)

```
dev/endpoint_eval/
├── 00_config.R                    # Global constants and helpers
├── 01_schema_resolution.R         # Version detection, body extraction, ref resolution
├── 04_openapi_parser.R            # Main parser (openapi_to_spec)
├── 06_param_parsing.R             # Parameter extraction utilities
├── 07_stub_generation.R           # Template-based code generation
└── verify_*.R                     # Manual verification scripts

schema/
├── chemi-amos-prod.json           # Swagger 2.0
├── chemi-rdkit-staging.json       # Swagger 2.0
├── chemi-mordred-staging.json     # Swagger 2.0
└── ctx-chemical-prod.json         # OpenAPI 3.0 (reference for regression)

R/
├── chemi_amos*.R                  # Generated AMOS stubs (to regenerate)
├── chemi_rdkit*.R                 # Generated RDKit stubs (to regenerate)
└── chemi_mordred*.R               # Generated Mordred stubs (to regenerate)
```

### Pattern 1: Validation Script Pattern

**What:** Manual R scripts that source the pipeline, parse schemas, generate stubs, and verify output
**When to use:** Integration phases that validate complex pipelines
**Example:**
```r
# Source: verify_07-02_integration.R (lines 4-58)
source("dev/endpoint_eval/00_config.R")
source("dev/endpoint_eval/01_schema_resolution.R")
source("dev/endpoint_eval/04_openapi_parser.R")

# Test Swagger 2.0
cli::cli_h2("Testing Swagger 2.0 (AMOS)")
amos_spec <- openapi_to_spec("schema/chemi-amos-prod.json")
amos_post <- amos_spec[amos_spec$method == "POST", ]
stopifnot(nrow(amos_post) > 0)
stopifnot(any(amos_post$has_body))
stopifnot(any(nchar(amos_post$body_params) > 0))
cli::cli_alert_success("AMOS: {nrow(amos_post)} POST endpoints")

# Test OpenAPI 3.0 (regression check)
cli::cli_h2("Testing OpenAPI 3.0 (ctx-chemical-prod)")
ctx_spec <- openapi_to_spec("schema/ctx-chemical-prod.json")
ctx_post <- ctx_spec[ctx_spec$method == "POST", ]
stopifnot(any(nchar(ctx_post$body_params) > 0))
cli::cli_alert_success("No regression in OpenAPI 3.0")
```

### Pattern 2: Before/After Stub Comparison

**What:** Save baseline stubs, regenerate, compare for regressions
**When to use:** When validating code generation changes don't break existing stubs
**Example:**
```bash
# Backup existing stubs
mkdir -p .baseline
cp R/chemi_amos*.R .baseline/
cp R/chemi_rdkit*.R .baseline/
cp R/chemi_mordred*.R .baseline/

# Regenerate stubs
# (run generation script)

# Compare
diff -r .baseline/ R/
```

### Pattern 3: Empty POST Detection Integration

**What:** Empty POST detection is ALREADY integrated in `07_stub_generation.R` (lines 16-131)
**When to use:** During stub rendering to skip endpoints with no meaningful input
**Example:**
```r
# Source: 07_stub_generation.R (lines 1019-1050)
detection_results <- purrr::pmap(
  list(
    method = spec$method,
    query_params = spec$query_params,
    path_params = spec$path_params,
    body_schema_full = spec$body_schema_full,
    body_schema_type = spec$body_schema_type
  ),
  is_empty_post_endpoint
)

spec$skip_endpoint <- purrr::map_lgl(detection_results, "skip")
spec <- spec %>% dplyr::filter(!skip_endpoint)
```

### Anti-Patterns to Avoid

- **Modifying parser code during integration phase:** Version detection and reference resolution are DONE in Phases 7-8. Don't change them.
- **Regenerating stubs without baseline:** Always save existing stubs before regeneration for comparison
- **Skipping OpenAPI 3.0 regression tests:** Must verify existing functionality unchanged
- **Manual stub editing after generation:** Generated stubs are canonical; hand-edits get overwritten

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema parsing | Custom JSON walker | jsonlite + purrr | Edge cases in $ref resolution already handled |
| Code generation | String concatenation | glue templates | Safer variable interpolation, clearer templates |
| Stub comparison | Manual diff inspection | diffobj or git diff | Automated comparison finds subtle changes |
| Regression tracking | Spreadsheet checklist | Git history + verification scripts | Version controlled, repeatable |

**Key insight:** The stub generation pipeline is mature and well-tested. Integration work is about RUNNING the pipeline with new schema versions, not rewriting it.

## Common Pitfalls

### Pitfall 1: Assuming Integration Means New Code

**What goes wrong:** Trying to modify `openapi_to_spec()` or `render_endpoint_stubs()` when they already work correctly
**Why it happens:** Phase 9 sounds like "integration" = "wiring things together" but the wiring was done in Phases 7-8
**How to avoid:**
1. Review Phase 7-8 completion summaries first
2. Check git log to see version detection already wired (commits 7aa27fa, 1bc934e)
3. Run existing verification scripts (`verify_07-02_integration.R`) to confirm it works
**Warning signs:** Changing code in `04_openapi_parser.R` or `01_schema_resolution.R` during Phase 9

### Pitfall 2: Regenerating Without Baselines

**What goes wrong:** Regenerating all stubs, discovering issues, but can't tell what changed
**Why it happens:** Eager to see results without establishing comparison baseline
**How to avoid:**
1. Create `.baseline/` directory with current stubs FIRST
2. Git commit current state before regeneration
3. Use `git diff` or `diffobj` to compare after
**Warning signs:** "The stubs look different but I'm not sure what changed"

### Pitfall 3: Not Testing OpenAPI 3.0 Regression

**What goes wrong:** Focus on new Swagger 2.0 support, break existing OpenAPI 3.0 parsing
**Why it happens:** Tunnel vision on new functionality
**How to avoid:**
1. Every verification script must test BOTH schema versions
2. Use existing `ctx-chemical-prod.json` as OpenAPI 3.0 control
3. Compare OpenAPI 3.0 stubs before and after - should be IDENTICAL
**Warning signs:** Only testing AMOS/RDKit/Mordred schemas

### Pitfall 4: Skipping Empty POST Detection Verification

**What goes wrong:** Empty POST endpoints get generated, cluttering codebase with non-functional stubs
**Why it happens:** Not checking `is_empty_post_endpoint()` integration in generated output
**How to avoid:**
1. Check generation logs for skipped endpoint reports
2. Verify empty POSTs are NOT in generated files
3. Confirm suspicious endpoints flagged correctly
**Warning signs:** Generated stubs with no parameters and no meaningful body

## Code Examples

Verified patterns from official sources:

### Stub Generation Pipeline (Full End-to-End)

```r
# Source: Phases 2, 6, 7 implementation pattern
# Load all modules
source("dev/endpoint_eval/00_config.R")
source("dev/endpoint_eval/01_schema_resolution.R")
source("dev/endpoint_eval/02_path_utils.R")
source("dev/endpoint_eval/04_openapi_parser.R")
source("dev/endpoint_eval/05_file_scaffold.R")
source("dev/endpoint_eval/06_param_parsing.R")
source("dev/endpoint_eval/07_stub_generation.R")

# Reset tracking (if re-running)
reset_endpoint_tracking()

# Parse schema (version detection automatic)
spec <- openapi_to_spec("schema/chemi-amos-prod.json")

# Configure stub generation
config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Generate stubs (empty POST detection automatic)
rendered <- render_endpoint_stubs(spec, config)

# Report what was skipped
report_skipped_endpoints()

# Write to files
# (Implementation in 05_file_scaffold.R)
```

### Regression Test Pattern

```r
# Source: verify_07-02_integration.R adapted for Phase 9
library(cli)

cli::cli_h1("Phase 9 Integration Validation")

# Test 1: Swagger 2.0 schemas work
cli::cli_h2("Swagger 2.0 Body Extraction")
for (schema_file in c("chemi-amos-prod.json",
                       "chemi-rdkit-staging.json",
                       "chemi-mordred-staging.json")) {
  spec <- openapi_to_spec(file.path("schema", schema_file))
  post_endpoints <- spec[spec$method == "POST", ]

  # Verify POST endpoints extracted
  stopifnot(nrow(post_endpoints) >= 0)  # May be 0 if no POST endpoints

  # For endpoints with body, verify body_params populated
  if (any(post_endpoints$has_body)) {
    with_body <- post_endpoints[post_endpoints$has_body, ]
    # Body params should be extracted (unless empty POST)
    cli::cli_alert_success("{schema_file}: {sum(nchar(with_body$body_params) > 0)}/{nrow(with_body)} POST bodies extracted")
  } else {
    cli::cli_alert_info("{schema_file}: No POST endpoints with body")
  }
}

# Test 2: OpenAPI 3.0 unchanged (regression)
cli::cli_h2("OpenAPI 3.0 Regression Check")
ctx_spec <- openapi_to_spec("schema/ctx-chemical-prod.json")
ctx_post <- ctx_spec[ctx_spec$method == "POST" & ctx_spec$has_body, ]
stopifnot(nrow(ctx_post) > 0)
stopifnot(all(nchar(ctx_post$body_params) > 0))
cli::cli_alert_success("OpenAPI 3.0 parsing unchanged")

# Test 3: Empty POST detection works for both versions
cli::cli_h2("Empty POST Detection")
# (Verify no empty POSTs in rendered stubs)
# Would require full stub generation to test
cli::cli_alert_info("Run full generation pipeline to verify empty POST filtering")
```

### Before/After Comparison Script

```bash
# Source: Best practice for integration validation
#!/bin/bash
# save_baseline.sh

# Create baseline directory
mkdir -p .baseline/stubs

# Save current stubs
echo "Saving baseline stubs..."
cp R/chemi_amos*.R .baseline/stubs/
cp R/chemi_rdkit*.R .baseline/stubs/
cp R/chemi_mordred*.R .baseline/stubs/

# Git commit for safety
git add R/chemi_*.R
git commit -m "chore: baseline stubs before Phase 9 regeneration"

echo "Baseline saved to .baseline/stubs/"
echo "Git committed current state"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OpenAPI 3.0 only | Version detection (Swagger 2.0 + OpenAPI 3.0) | Phase 7 (2026-01-29) | Can now parse AMOS/RDKit/Mordred schemas |
| Hardcoded `#/components/schemas/` | Fallback chain (`#/definitions/` then `#/components/schemas/`) | Phase 8 (2026-01-29) | Robust reference resolution across versions |
| Fixed depth limit (5) | Reduced depth limit (3) with better error messages | Phase 8 (2026-01-29) | Faster failure, clearer circular reference detection |
| Silent reference failures | cli::cli_abort() with context | Phase 8 (2026-01-29) | Easier debugging |
| Manual stub generation | Pipeline with empty POST detection | Phase 6 (2026-01-28) | Skip non-functional endpoints automatically |

**Deprecated/outdated:**
- Manual schema inspection to find POST endpoints: Now automated via `openapi_to_spec()`
- Hardcoded `#/components/schemas/` in reference resolution: Now version-aware with fallback
- `max_depth = 5` in resolution: Now `max_depth = 3` (REF-03 decision)

## Open Questions

### 1. **Do AMOS, RDKit, and Mordred schemas have POST endpoints with body parameters?**
   - What we know: Schemas exist, verify scripts tested them in Phase 7
   - What's unclear: Actual count of POST endpoints per schema (may be 0 for some)
   - Recommendation: Run `openapi_to_spec()` on each schema and inspect `method == "POST"` rows before regeneration. If 0 POST endpoints, that microservice may not need regeneration.

### 2. **What is the current state of generated stubs?**
   - What we know: Files exist (R/chemi_amos*.R, etc.), verified via Glob results
   - What's unclear: Were they generated with old pipeline or manually written?
   - Recommendation: Check file headers for generation comments. Use git blame to see last modification date.

### 3. **Should regeneration preserve custom post-processing code?**
   - What we know: Generated stubs have `# Additional post-processing can be added here` comments
   - What's unclear: Whether existing stubs have custom code in that section
   - Recommendation: Before regeneration, grep for non-template code in existing stubs. May need manual merge after regeneration.

## Sources

### Primary (HIGH confidence)

- dev/endpoint_eval/04_openapi_parser.R:339-341 - Version detection already wired into openapi_to_spec()
- dev/endpoint_eval/01_schema_resolution.R:126-245 - resolve_schema_ref() with version-aware fallback (Phase 8)
- dev/endpoint_eval/07_stub_generation.R:16-131 - is_empty_post_endpoint() detection logic
- verify_07-02_integration.R - Integration test pattern for Swagger 2.0 + OpenAPI 3.0
- .planning/ROADMAP.md:82-110 - Phase 9 requirements and success criteria
- Git commits: 7aa27fa (version detection wired), 5cdb33c (OpenAPI 3.0 regression test)

### Secondary (MEDIUM confidence)

- Phase 7 and 8 completion (from ROADMAP.md:150-151) - Confirms integration already done
- Schema file listing (schema/ directory) - Confirms which microservices to regenerate

### Tertiary (LOW confidence)

- None required - all findings from codebase inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All dependencies already in codebase, no new libraries needed
- Architecture: HIGH - Patterns derived from existing verification scripts and git history
- Pitfalls: HIGH - Based on common integration phase mistakes and actual codebase structure

**Research date:** 2026-01-29
**Valid until:** 2026-02-28 (stable codebase, internal tooling)

**Key insight for planner:** This is a VALIDATION phase, not an implementation phase. The code changes are complete (Phases 7-8). Planning should focus on:
1. Verification scripts (before/after comparison)
2. Regeneration procedure (baseline → regenerate → compare → document)
3. Regression testing (OpenAPI 3.0 must be unchanged)
4. Documentation of what changed and why

Do NOT plan new parser features or code modifications unless regression tests reveal bugs.
