# GenRA Read-Across Implementation Plan for ComptoxR

**Status**: Ready for implementation
**Date**: 2026-04-14
**Estimated effort**: 2-3 days

---

## Context

### Problem Statement
ComptoxR users need to predict toxicity for untested chemicals using read-across methodology. Currently, the package provides the building blocks (similarity search via `ct_similar()`, toxicity data via `ct_hazard_*` functions) but no integrated read-across workflow.

### What is GenRA?
GenRA (Generalized Read-Across) is an EPA-developed computational toxicology approach that:
1. Finds structurally similar chemicals (analogues) for a target compound
2. Retrieves known toxicity data for those analogues
3. Predicts the target's toxicity using similarity-weighted activity (SWA)
4. Quantifies prediction uncertainty via permutation-based statistics

### Why This Implementation?
- **Lightweight**: Uses existing ComptoxR API functions (no new heavy dependencies like rcdk)
- **API-first**: Follows ComptoxR philosophy - similarity computed server-side
- **Practical**: Covers the core GenRA algorithm without over-engineering
- **One new dependency**: Only `pROC` for AUC calculation (in Suggests, not Imports)

---

## Implementation Overview

### New Files to Create

```
R/
  genra_swa.R              # Core SWA algorithm (~40 lines)
  genra_uncertainty.R      # AUC + p-value calculation (~80 lines)
  genra_get_tox_data.R     # Toxicity data wrapper (~100 lines)
  genra_predict.R          # Main prediction function (~150 lines)

tests/testthat/
  test-genra_swa.R         # Unit tests for SWA
  test-genra_uncertainty.R # Unit tests with mocked pROC
  test-genra_predict.R     # Integration tests with VCR cassettes
  fixtures/
    genra_predict_*.yml    # VCR cassettes for API responses
```

### Existing Files to Leverage (DO NOT MODIFY)

| File | Purpose | How We Use It |
|------|---------|---------------|
| `R/ct_similar.R` | Find similar chemicals | Call directly for analogue discovery |
| `R/ct_hazard_toxref_search.R` | ToxRefDB data | Call for toxicity labels |
| `R/ct_hazard_toxval_search.R` | ToxValDB data | Alternative toxicity source |
| `R/ct_hazard_cancer_search.R` | Cancer summary | Cancer endpoint predictions |
| `R/ct_hazard_genetox_search.R` | Genotoxicity | Genetox endpoint predictions |
| `R/z_generic_request.R` | Request infrastructure | Understand patterns (not called directly) |

### File to Modify

| File | Change |
|------|--------|
| `DESCRIPTION` | Add `pROC` to Suggests |

---

## Detailed Function Specifications

### 1. `genra_swa()` - Core Algorithm

**File**: `R/genra_swa.R`

**Purpose**: Calculate Similarity-Weighted Activity prediction

**Formula**:
```
SWA = sum(activity_j * similarity_j) / sum(similarity_j)
```

**Signature**:
```r
#' Calculate Similarity-Weighted Activity (SWA)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Core GenRA prediction algorithm. Computes weighted average of analogue
#' activities where weights are Tanimoto similarities.
#'
#' @param activities Numeric vector. Binary activity values (0=inactive, 1=active).
#' @param similarities Numeric vector. Tanimoto similarity scores (0-1).
#'   Must be same length as activities.
#'
#' @return Numeric scalar (0-1). Returns NA if no valid pairs provided.
#'
#' @export
#' @examples
#' # 3 analogues: 2 active (high sim), 1 inactive (lower sim)
#' genra_swa(c(1, 1, 0), c(0.9, 0.7, 0.6))
#' # Returns ~0.73 (weighted toward active)
genra_swa <- function(activities, similarities) {
```

**Implementation Details**:
```r
genra_swa <- function(activities, similarities) {

  # Input validation

if (length(activities) != length(similarities)) {
    cli::cli_abort("activities and similarities must have same length")
  }

  # Remove NA pairs
  valid <- !is.na(activities) & !is.na(similarities)
  act <- activities[valid]
  sim <- similarities[valid]

  # Edge case: no valid data
  if (length(act) == 0) {
    return(NA_real_)
  }

  # Edge case: all similarities are zero
  sum_sim <- sum(sim)
  if (sum_sim == 0) {
    return(NA_real_)
  }

  # Core calculation
  sum(act * sim) / sum_sim
}
```

**Tests** (`test-genra_swa.R`):
- Equal weights → 0.5
- Weighted toward active (high-sim active, low-sim inactive) → >0.5
- All active → 1.0
- All inactive → 0.0
- NA handling (removes NA pairs)
- Empty input → NA
- Length mismatch → error
- Zero similarities → NA

---

### 2. `genra_uncertainty()` - Uncertainty Quantification

**File**: `R/genra_uncertainty.R`

**Purpose**: Calculate prediction reliability metrics using leave-one-out SWA and permutation testing

**Signature**:
```r
#' Calculate GenRA Prediction Uncertainty
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Quantifies reliability of read-across prediction using ROC AUC and
#' permutation-based p-value.
#'
#' @param activities Numeric vector. Known binary activities (0/1) from analogues.
#' @param similarities Numeric vector. Tanimoto similarities for analogues.
#' @param n_permutations Integer. Permutations for null distribution. Default 100.
#'
#' @return List with:
#'   - auc: ROC AUC (0-1, higher = better discrimination)
#'   - p_value: Proportion of null AUCs exceeding observed (lower = more significant)
#'   - threshold: Optimal classification threshold (balanced accuracy)
#'
#' @details
#' Requires `pROC` package. Returns NA values with warning if not installed.
#'
#' The method:
#' 1. For each analogue, calculate its SWA using OTHER analogues (leave-one-out)
#' 2. Compare leave-one-out SWA scores to actual activities via ROC AUC
#' 3. Generate null distribution by permuting activity labels
#' 4. p-value = proportion of null AUCs >= observed AUC
#'
#' @export
genra_uncertainty <- function(activities, similarities, n_permutations = 100) {
```

**Implementation Details**:
```r
genra_uncertainty <- function(activities, similarities, n_permutations = 100) {
  # Check pROC availability
  if (!requireNamespace("pROC", quietly = TRUE)) {
    cli::cli_warn(c(
      "Package {.pkg pROC} required for uncertainty quantification",
      "i" = "Install with {.run install.packages('pROC')}"
    ))
    return(list(auc = NA_real_, p_value = NA_real_, threshold = 0.5))
  }

  # Need at least 2 of each class for meaningful AUC
  if (sum(activities == 1) < 2 || sum(activities == 0) < 2) {
    cli::cli_warn("Need at least 2 active and 2 inactive analogues for uncertainty")
    return(list(auc = NA_real_, p_value = NA_real_, threshold = 0.5))
  }

  # Calculate leave-one-out SWA for each analogue
  n <- length(activities)
  loo_swa <- numeric(n)
  for (i in seq_len(n)) {
    loo_swa[i] <- genra_swa(activities[-i], similarities[-i])
  }

  # Calculate observed AUC
  roc_obj <- pROC::roc(activities, loo_swa, quiet = TRUE)
  observed_auc <- as.numeric(pROC::auc(roc_obj))

  # Optimal threshold (Youden's J / balanced accuracy)
  coords <- pROC::coords(roc_obj, "best", best.method = "youden")
  threshold <- coords$threshold[1]

  # Permutation test for p-value
  null_aucs <- replicate(n_permutations, {
    perm_act <- sample(activities)
    perm_roc <- pROC::roc(perm_act, loo_swa, quiet = TRUE)
    as.numeric(pROC::auc(perm_roc))
  })

  p_value <- mean(null_aucs >= observed_auc)

  list(
    auc = observed_auc,
    p_value = p_value,
    threshold = threshold
  )
}
```

**Tests** (`test-genra_uncertainty.R`):
- Returns correct structure (list with auc, p_value, threshold)
- AUC between 0 and 1
- p_value between 0 and 1
- Missing pROC returns NA values (mock `requireNamespace`)
- Too few positives/negatives returns NA with warning

---

### 3. `genra_get_tox_data()` - Toxicity Data Retrieval

**File**: `R/genra_get_tox_data.R`

**Purpose**: Unified interface to retrieve and normalize toxicity data from different endpoints

**Signature**:
```r
#' Get Toxicity Data for GenRA Prediction
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Retrieves toxicity data from EPA endpoints and normalizes to binary activity.
#'
#' @param dtxsids Character vector. DTXSIDs to query.
#' @param endpoint Character. One of "toxref", "toxval", "cancer", "genetox".
#' @param endpoint_filter Optional. Filter by specific study type or effect.
#'
#' @return Tibble with columns:
#'   - dtxsid: Chemical identifier
#'   - activity: Binary (1=active/positive, 0=inactive/negative)
#'   - effect_type: Specific effect or study type
#'   - source: Data source
#'
#' @export
genra_get_tox_data <- function(dtxsids, endpoint = c("toxref", "toxval", "cancer", "genetox"),
                                endpoint_filter = NULL) {
```

**Implementation Details**:
```r
genra_get_tox_data <- function(dtxsids, endpoint = c("toxref", "toxval", "cancer", "genetox"),
                                endpoint_filter = NULL) {
  endpoint <- rlang::arg_match(endpoint)

  # Dispatch to appropriate ct_hazard_* function
  raw_data <- switch(endpoint,
    toxref = .get_toxref_data(dtxsids, endpoint_filter),
    toxval = .get_toxval_data(dtxsids, endpoint_filter),
    cancer = .get_cancer_data(dtxsids, endpoint_filter),
    genetox = .get_genetox_data(dtxsids, endpoint_filter)
  )

  if (is.null(raw_data) || nrow(raw_data) == 0) {
    return(tibble::tibble(
      dtxsid = character(),
      activity = integer(),
      effect_type = character(),
      source = character()
    ))
  }

  raw_data
}

# Internal helpers for each endpoint
.get_toxref_data <- function(dtxsids, filter) {
  # Call ct_hazard_toxref_search for each DTXSID
  # ToxRef returns study summaries - presence of effect = active
  results <- purrr::map(dtxsids, function(id) {
    tryCatch({
      data <- ct_hazard_toxref_search(id)
      if (!is.null(data) && nrow(data) > 0) {
        data |>
          dplyr::mutate(
            dtxsid = id,
            activity = 1L,  # Has toxref data = some effect observed
            source = "ToxRefDB"
          ) |>
          dplyr::select(dtxsid, activity, effect_type = dplyr::any_of(c("study_type", "effect")), source)
      } else {
        tibble::tibble(dtxsid = id, activity = 0L, effect_type = NA_character_, source = "ToxRefDB")
      }
    }, error = function(e) {
      tibble::tibble(dtxsid = id, activity = NA_integer_, effect_type = NA_character_, source = "ToxRefDB")
    })
  })

  purrr::list_rbind(results) |>
    dplyr::distinct(dtxsid, .keep_all = TRUE)  # One row per chemical
}

# Similar patterns for .get_toxval_data, .get_cancer_data, .get_genetox_data
```

**Endpoint-Specific Activity Logic**:

| Endpoint | Activity = 1 (Active) | Activity = 0 (Inactive) |
|----------|----------------------|-------------------------|
| toxref | Has effect data | No effect data found |
| cancer | Carcinogenic classification | Non-carcinogenic |
| genetox | Positive result | Negative result |
| toxval | Has POD value below threshold | No data or above threshold |

---

### 4. `genra_predict()` - Main Prediction Function

**File**: `R/genra_predict.R`

**Purpose**: Complete read-across prediction workflow

**Signature**:
```r
#' GenRA Read-Across Prediction
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Predicts toxicity for a target chemical using similarity-weighted activity
#' from structurally similar analogues.
#'
#' @param target Character. Single DTXSID for target chemical.
#' @param endpoint Character. Toxicity endpoint: "toxref", "toxval", "cancer", "genetox".
#' @param endpoint_filter Optional. Filter toxicity data by study type.
#' @param k Integer. Maximum analogues to use. Default 10.
#' @param min_similarity Numeric 0-1. Minimum Tanimoto similarity. Default 0.5.
#' @param n_permutations Integer. Permutations for p-value. Default 100. Set 0 to skip.
#' @param include_analogues Logical. Include analogue details in output. Default TRUE.
#'
#' @return Object of class "genra_prediction" (list) containing:
#'   - target: Target DTXSID
#'   - endpoint: Endpoint used
#'   - prediction: SWA score (0-1)
#'   - predicted_class: "active" or "inactive"
#'   - threshold: Classification threshold
#'   - n_analogues: Analogues with toxicity data
#'   - n_analogues_found: Total analogues found
#'   - auc: ROC AUC (if uncertainty calculated)
#'   - p_value: Permutation p-value (if uncertainty calculated)
#'   - analogues: Tibble of analogue details (if include_analogues = TRUE)
#'
#' @export
#' @examples
#' \dontrun
#' # Predict using ToxRefDB
#' pred <- genra_predict("DTXSID7020182", endpoint = "toxref")
#' print(pred)
#'
#' # Fast prediction (no uncertainty)
#' pred <- genra_predict("DTXSID7020182", n_permutations = 0)
#' }
genra_predict <- function(
    target,
    endpoint = c("toxref", "toxval", "cancer", "genetox"),
    endpoint_filter = NULL,
    k = 10,
    min_similarity = 0.5,
    n_permutations = 100,
    include_analogues = TRUE
) {
```

**Implementation Details**:
```r
genra_predict <- function(
    target,
    endpoint = c("toxref", "toxval", "cancer", "genetox"),
    endpoint_filter = NULL,
    k = 10,
    min_similarity = 0.5,
    n_permutations = 100,
    include_analogues = TRUE
) {
  # Validate inputs
  endpoint <- rlang::arg_match(endpoint)

  if (!grepl("^DTXSID\\d+$", target)) {
    cli::cli_abort(c(
      "Invalid target format",
      "x" = "{.val {target}} is not a valid DTXSID",
      "i" = "Expected format: DTXSID followed by digits (e.g., DTXSID7020182)"
    ))
  }

  if (min_similarity < 0 || min_similarity > 1) {
    cli::cli_abort("min_similarity must be between 0 and 1")
  }

  # Step 1: Find analogues
  cli::cli_progress_step("Finding analogues for {.val {target}}")
  analogues <- tryCatch(
    ct_similar(target, similarity = min_similarity),
    error = function(e) {
      cli::cli_warn("Failed to retrieve analogues: {e$message}")
      NULL
    }
  )

  if (is.null(analogues) || nrow(analogues) == 0) {
    cli::cli_warn("No analogues found at similarity >= {min_similarity}")
    return(.empty_prediction(target, endpoint, error = "no_analogues"))
  }

  # Limit to k analogues (already sorted by similarity from API)
  if (nrow(analogues) > k) {
    analogues <- analogues[1:k, ]
  }
  n_found <- nrow(analogues)

  # Step 2: Get toxicity data for analogues
  cli::cli_progress_step("Retrieving {endpoint} data for {n_found} analogues")
  tox_data <- genra_get_tox_data(analogues$dtxsid, endpoint, endpoint_filter)

  # Step 3: Merge analogues with toxicity
  analogue_tox <- dplyr::left_join(analogues, tox_data, by = "dtxsid") |>
    dplyr::filter(!is.na(activity))

  n_with_tox <- nrow(analogue_tox)

  if (n_with_tox == 0) {
    cli::cli_warn("No analogues have {endpoint} data")
    return(.empty_prediction(target, endpoint, n_found = n_found, error = "no_toxicity_data"))
  }

  # Step 4: Calculate SWA prediction
  cli::cli_progress_step("Calculating prediction from {n_with_tox} analogues")
  prediction <- genra_swa(analogue_tox$activity, analogue_tox$similarity)

  # Step 5: Uncertainty quantification (optional)
  if (n_permutations > 0 && n_with_tox >= 4) {
    cli::cli_progress_step("Calculating uncertainty ({n_permutations} permutations)")
    uncertainty <- genra_uncertainty(
      analogue_tox$activity,
      analogue_tox$similarity,
      n_permutations
    )
  } else {
    uncertainty <- list(auc = NA_real_, p_value = NA_real_, threshold = 0.5)
  }

  # Determine predicted class
  threshold <- if (!is.na(uncertainty$threshold)) uncertainty$threshold else 0.5
  predicted_class <- if (prediction >= threshold) "active" else "inactive"

  # Build result
  result <- list(
    target = target,
    endpoint = endpoint,
    prediction = prediction,
    predicted_class = predicted_class,
    threshold = threshold,
    n_analogues = n_with_tox,
    n_analogues_found = n_found,
    auc = uncertainty$auc,
    p_value = uncertainty$p_value,
    error = NULL
  )

  if (include_analogues) {
    result$analogues <- analogue_tox
  }

  cli::cli_progress_done()
  structure(result, class = "genra_prediction")
}

# Helper for empty/error results
.empty_prediction <- function(target, endpoint, n_found = 0L, error = NULL) {
  structure(list(
    target = target,
    endpoint = endpoint,
    prediction = NA_real_,
    predicted_class = NA_character_,
    threshold = NA_real_,
    n_analogues = 0L,
    n_analogues_found = n_found,
    auc = NA_real_,
    p_value = NA_real_,
    error = error,
    analogues = NULL
  ), class = "genra_prediction")
}

# Print method for nice output
#' @export
print.genra_prediction <- function(x, ...) {
  cli::cli_h1("GenRA Read-Across Prediction")
  cli::cli_text("Target: {.val {x$target}}")
  cli::cli_text("Endpoint: {.val {x$endpoint}}")
  cli::cli_text("")

  if (!is.na(x$prediction)) {
    cli::cli_text("Prediction: {.strong {round(x$prediction, 3)}} ({x$predicted_class})")
    cli::cli_text("Threshold: {round(x$threshold, 3)}")
    cli::cli_text("")

    if (!is.na(x$auc)) {
      sig <- if (!is.na(x$p_value) && x$p_value < 0.05) "*" else ""
      cli::cli_text("Uncertainty:")
      cli::cli_text("  AUC: {round(x$auc, 3)}")
      cli::cli_text("  p-value: {round(x$p_value, 3)}{sig}")
    }

    cli::cli_text("")
    cli::cli_text("Analogues: {x$n_analogues} with data (of {x$n_analogues_found} found)")
  } else {
    cli::cli_alert_warning("Prediction failed: {x$error}")
  }

  invisible(x)
}
```

---

## Data Flow Diagram

```
User calls: genra_predict("DTXSID7020182", endpoint = "toxref")
                              |
                              v
                    +-------------------+
                    | Input Validation  |
                    | - DTXSID format   |
                    | - similarity 0-1  |
                    +--------+----------+
                             |
                             v
                    +-------------------+
                    |  ct_similar()     |  <-- Existing function
                    | Find k analogues  |
                    | sim >= threshold  |
                    +--------+----------+
                             |
                 Returns tibble:
                 | dtxsid | similarity |
                 |--------|------------|
                 | DTXSID | 0.85       |
                 | DTXSID | 0.78       |
                             |
                             v
                    +-------------------+
                    | genra_get_tox_data|
                    | Get tox for each  |
                    | analogue DTXSID   |
                    +--------+----------+
                             |
                  Calls ct_hazard_toxref_search()
                  or ct_hazard_cancer_search() etc.
                             |
                 Returns tibble:
                 | dtxsid | activity | effect_type |
                 |--------|----------|-------------|
                 | DTXSID | 1        | acute_oral  |
                 | DTXSID | 0        | NA          |
                             |
                             v
                    +-------------------+
                    | LEFT JOIN         |
                    | analogues + tox   |
                    | Filter NA activity|
                    +--------+----------+
                             |
                 | dtxsid | similarity | activity |
                 |--------|------------|----------|
                 | DTXSID | 0.85       | 1        |
                 | DTXSID | 0.78       | 0        |
                             |
              +--------------+--------------+
              |                             |
              v                             v
    +-------------------+         +-------------------+
    |   genra_swa()     |         | genra_uncertainty |
    | sum(a*s)/sum(s)   |         | (if n_perm > 0)   |
    +--------+----------+         +--------+----------+
             |                             |
    prediction = 0.52              auc = 0.78
                                   p_value = 0.03
                                   threshold = 0.48
              |                             |
              +-------------+---------------+
                            |
                            v
                    +-------------------+
                    | Build result list |
                    | class = genra_    |
                    |     prediction    |
                    +-------------------+
                            |
                            v
                    Return to user
```

---

## Testing Strategy

### Unit Tests (No API Calls)

**`test-genra_swa.R`**
```r
test_that("genra_swa calculates correct weighted average", {
  expect_equal(genra_swa(c(1, 0), c(0.5, 0.5)), 0.5)
  expect_equal(genra_swa(c(1, 0), c(0.9, 0.1)), 0.9)
  expect_equal(genra_swa(c(1, 1, 1), c(0.8, 0.7, 0.6)), 1.0)
  expect_equal(genra_swa(c(0, 0, 0), c(0.8, 0.7, 0.6)), 0.0)
})

test_that("genra_swa handles edge cases", {
  expect_true(is.na(genra_swa(numeric(0), numeric(0))))
  expect_true(is.na(genra_swa(c(1, NA), c(NA, 0.5))))
  expect_error(genra_swa(c(1, 0), c(0.5)))  # length mismatch
})
```

### Integration Tests (VCR Cassettes)

**`test-genra_predict.R`**
```r
test_that("genra_predict works with toxref endpoint", {
  vcr::use_cassette("genra_predict_toxref", {
    result <- genra_predict(
      target = "DTXSID7020182",
      endpoint = "toxref",
      k = 5,
      n_permutations = 0
    )

    expect_s3_class(result, "genra_prediction")
    expect_equal(result$target, "DTXSID7020182")
  })
})

test_that("genra_predict handles no analogues", {
  vcr::use_cassette("genra_predict_no_analogues", {
    result <- genra_predict(
      target = "DTXSID7020182",
      min_similarity = 0.99,
      n_permutations = 0
    )

    expect_equal(result$error, "no_analogues")
    expect_true(is.na(result$prediction))
  })
})
```

### Test Chemicals
- **DTXSID7020182** (Bisphenol A) - Well-characterized, abundant data
- **DTXSID0020232** (Caffeine) - Moderate data coverage
- **DTXSID5020607** (Ethanol) - Extensive coverage

---

## Dependency Change

**Add to DESCRIPTION Suggests:**
```
Suggests:
    arrow,
    autonewsmd,
    ...
    pROC,        # <-- ADD THIS
    testthat (>= 3.0.0),
    ...
```

---

## Implementation Phases

### Phase 1: Core SWA Algorithm (30 minutes)
**Create**: `R/genra_swa.R`, `tests/testthat/test-genra_swa.R`

1. Implement `genra_swa()` with validation
2. Write comprehensive unit tests
3. Add roxygen2 documentation
4. Run `devtools::document()`

**Verification**: All unit tests pass

### Phase 2: Uncertainty Quantification (45 minutes)
**Create**: `R/genra_uncertainty.R`, `tests/testthat/test-genra_uncertainty.R`
**Modify**: `DESCRIPTION` (add pROC to Suggests)

1. Implement `genra_uncertainty()` with pROC integration
2. Add graceful fallback when pROC missing
3. Write unit tests (mock pROC where needed)
4. Document with roxygen2

**Verification**: Tests pass with and without pROC installed

### Phase 3: Toxicity Data Wrapper (1 hour)
**Create**: `R/genra_get_tox_data.R`, `tests/testthat/test-genra_get_tox_data.R`

1. Implement dispatcher function
2. Add internal helpers for each endpoint:
   - `.get_toxref_data()`
   - `.get_cancer_data()`
   - `.get_genetox_data()`
   - `.get_toxval_data()`
3. Write integration tests with VCR cassettes
4. Handle API errors gracefully

**Verification**:
- `genra_get_tox_data("DTXSID7020182", "toxref")` returns tibble
- VCR cassettes recorded and pass on replay

### Phase 4: Main Prediction Function (1 hour)
**Create**: `R/genra_predict.R`, `tests/testthat/test-genra_predict.R`

1. Implement `genra_predict()` orchestration
2. Add `.empty_prediction()` helper
3. Add `print.genra_prediction()` S3 method
4. Write comprehensive integration tests
5. Record VCR cassettes for all scenarios

**Verification**:
```r
pred <- genra_predict("DTXSID7020182", endpoint = "toxref")
print(pred)
# Should show prediction, uncertainty, analogue count
```

### Phase 5: Documentation & Polish (30 minutes)
**Modify**: All new R files (roxygen updates)

1. Complete all `@seealso` cross-references
2. Add `@references` to GenRA publications
3. Run `devtools::document()`
4. Run `devtools::check()` - resolve warnings
5. Update `NEWS.md` with new feature

**Verification**: `R CMD check` passes with 0 errors, 0 warnings related to new code

---

## Verification Checklist

After implementation, verify:

- [ ] `devtools::document()` runs without errors
- [ ] `devtools::check()` passes (ignoring pre-existing warnings)
- [ ] `devtools::test()` passes for all new tests
- [ ] Manual test with real API key:
  ```r
  library(ComptoxR)
  ctx_server(1)  # Production
  pred <- genra_predict("DTXSID7020182", endpoint = "toxref")
  print(pred)
  ```
- [ ] Uncertainty calculation works (requires pROC):
  ```r
  install.packages("pROC")
  pred <- genra_predict("DTXSID7020182", n_permutations = 50)
  pred$auc  # Should not be NA
  ```
- [ ] Graceful degradation without pROC:
  ```r
  # In fresh R session without pROC
  pred <- genra_predict("DTXSID7020182", n_permutations = 50)
  # Should warn about pROC, return NA for auc/p_value
  ```

---

## References

- Shah et al. (2016). "Using ToxCast Data to Reconstruct Dynamic Cell State Trajectories and Estimate Toxicological Points of Departure." *Environmental Health Perspectives*
- Helman et al. (2019). "Generalized Read-Across (GenRA): A workflow implemented into the EPA CompTox Chemicals Dashboard." *ALTEX*
- EPA GenRA Manual: https://www.epa.gov/comptox-tools/generalized-read-across-genra-manual
- genra-py repository: https://github.com/i-shah/genra-py
- raxR repository: https://github.com/patlewig/raxR
