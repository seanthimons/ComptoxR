# Assimilate Report: GenRA Read-Across Implementation

**Direction**: Implement lightweight read-across functionality integrating with ComptoxR
**Sources**:
- https://www.epa.gov/comptox-tools/generalized-read-across-genra-manual
- https://github.com/patlewig/raxR
- https://github.com/i-shah/genra-py
**Date**: 2026-04-14

---

## Current Repo Profile (ComptoxR)

- **Stack**: R package (4.5.1), httr2-based API wrappers
- **Architecture**: Centralized `generic_request()` / `generic_chemi_request()` templates
- **Key Patterns**:
  - DTXSID-centric chemical identifiers
  - Batch processing with automatic chunking
  - VCR cassette-based testing
  - Tibble-first data returns
- **Existing Relevant Functions**:
  - `ct_similar()` - similarity search via Dashboard API
  - `chemi_toxprint()` / `chemi_toxprints_calculate()` - ToxPrint fingerprints
  - `chemi_cluster()` - similarity matrix and hierarchical clustering
  - `ct_hazard_*` - 23+ hazard endpoint wrappers (ToxVal, ToxRef, genetox, cancer, etc.)
  - `chemi_resolver_*` - chemical ID resolution

---

## Source Repo Profiles

### raxR (R, minimal)
- **Stack**: R package, depends on `rcdk` for chemistry
- **Architecture**: Simple procedural functions, no API integration
- **Key Features**:
  - Morgan fingerprint generation via rcdk
  - k-NN analogue selection with Tanimoto similarity
  - Similarity-weighted activity (SWA) prediction
  - Physicochemical property filtering (SD threshold)
- **Maturity**: Proof of concept, ~300 lines of code

### genra-py (Python, mature)
- **Stack**: Python 3, scikit-learn estimators, RDKit
- **Architecture**: OOP with sklearn-compatible API (`fit`/`predict`)
- **Key Features**:
  - Binary classification (`GenRAPredBinary`)
  - Continuous value prediction (`GenRAPredValue`)
  - Hybrid fingerprint support (`GenRAPredHybrid`) - combines multiple descriptor types
  - Uncertainty quantification (AUC, p-value, optimized threshold)
  - Supports Jaccard, cosine, and other distance metrics
- **Maturity**: Production-ready, published research backing

---

## Architecture Delta

| Aspect | ComptoxR | raxR | genra-py |
|--------|----------|------|----------|
| **Fingerprints** | API-served ToxPrints | Local rcdk Morgan | Local RDKit multiple |
| **Similarity** | API-computed | Local Tanimoto via rcdk | Local via sklearn |
| **Toxicity Data** | API (ToxVal, ToxRef) | External CSV | External data files |
| **Prediction** | None | Simple SWA | sklearn estimator |
| **Dependencies** | httr2 only | rcdk (heavy) | rdkit, sklearn (heavy) |

**Key Barrier**: Both source packages compute fingerprints and similarity locally using chemistry toolkits (rcdk/RDKit). ComptoxR's philosophy is API-first with minimal local dependencies. A direct port would require either:
1. Adding rcdk as a dependency (against package philosophy)
2. Leveraging existing EPA cheminformatics API endpoints for fingerprints/similarity

**Recommendation**: Use EPA's cheminformatics server for fingerprints and similarity, keep prediction logic local.

---

## Findings (Ranked by Practical Value)

### 1. [HIGH] Similarity-Weighted Activity (SWA) Formula
- **What**: Core prediction algorithm that weights neighbor activities by similarity
- **Where**:
  - raxR: `R/utils.R:wtavg()` (26 lines)
  - genra-py: `genra/rax/skl/binary.py:calc_neigh_swa()` (33 lines)
- **Extractability**: Direct port
- **Effort**: Low
- **Why useful**: This is the heart of GenRA - a simple weighted average that can run entirely in R with no external dependencies
- **How to adapt**:
```r
# SWA prediction: sum(activity_j * sim_j) / sum(sim_j)
genra_swa <- function(activities, similarities) {
  sum(activities * similarities, na.rm = TRUE) / sum(similarities, na.rm = TRUE)
}
```

### 2. [HIGH] Analogue Selection via ct_similar + chemi_cluster
- **What**: k-NN neighbor finding using existing ComptoxR infrastructure
- **Where**: Already exists in ComptoxR
- **Extractability**: Adapt existing
- **Effort**: Low
- **Why useful**: No new code needed - `ct_similar()` returns similar compounds, `chemi_cluster()` provides similarity matrix
- **How to adapt**:
```r
# Use existing ct_similar to get analogues
analogues <- ct_similar(target_dtxsid, similarity = 0.7)

# Or use chemi_cluster for full pairwise similarity
cluster_data <- chemi_cluster(c(target, analogue_candidates))
```

### 3. [HIGH] Uncertainty Quantification (AUC + p-value)
- **What**: Permutation-based significance testing for read-across predictions
- **Where**: genra-py `genra/rax/skl/binary.py:calc_uncertainty_from_neigh_swa()` (35 lines)
- **Extractability**: Direct port
- **Effort**: Low
- **Why useful**: Critical for regulatory acceptance - tells you if prediction is better than chance
- **How to adapt**:
```r
genra_uncertainty <- function(y_true, swa_scores, n_permutations = 100) {
  observed_auc <- pROC::auc(y_true, swa_scores)
  null_aucs <- replicate(n_permutations, {
    pROC::auc(sample(y_true), swa_scores)
  })
  p_val <- mean(null_aucs > observed_auc)
  list(auc = observed_auc, p_value = p_val)
}
```

### 4. [HIGH] Hazard Data Integration Pattern
- **What**: Using ToxRefDB/ToxValDB endpoints for training labels
- **Where**: ComptoxR already has `ct_hazard_toxref_*` and `ct_hazard_toxval_*`
- **Extractability**: Leverage existing
- **Effort**: Low
- **Why useful**: Direct access to EPA's curated toxicity data for read-across predictions
- **How to adapt**: Pipeline pattern:
```r
# 1. Get analogues
analogues <- ct_similar("DTXSID7020182", similarity = 0.7)

# 2. Get toxicity data for analogues
tox_data <- ct_hazard_toxref_search(analogues$dtxsid)

# 3. Apply SWA with similarity weights
prediction <- genra_swa(tox_data$effect, analogues$similarity)
```

### 5. [MEDIUM] Optimized Threshold Selection (Balanced Accuracy)
- **What**: Find optimal similarity cutoff maximizing balanced accuracy
- **Where**: genra-py `binary.py:calc_uncertainty_from_neigh_swa()` (ROC analysis)
- **Extractability**: Direct port
- **Effort**: Low
- **Why useful**: Determines best threshold for converting SWA to binary prediction
- **How to adapt**:
```r
genra_optimal_threshold <- function(y_true, swa_scores) {
  roc_obj <- pROC::roc(y_true, swa_scores)
  coords <- pROC::coords(roc_obj, "best", best.method = "closest.topleft")
  coords$threshold
}
```

### 6. [MEDIUM] Hybrid Fingerprint Weighting
- **What**: Combine chemical + bioactivity fingerprints with configurable weights
- **Where**: genra-py `genra/rax/skl/hybrid.py` (250+ lines)
- **Extractability**: Inspiration
- **Effort**: Medium-High
- **Why useful**: EPA research shows hybrid (chemical + bioactivity) outperforms chemical-only
- **How to adapt**: Would require:
  - ToxCast bioactivity data access (exists via `ct_bioactivity_*`?)
  - Weighted similarity combination logic

### 7. [MEDIUM] Physicochemical Property Filtering
- **What**: Remove analogues outside 3 SD of target's properties (MW, logP, HBA, HBD)
- **Where**: raxR `R/utils.R:filter_sd()` (40 lines)
- **Extractability**: Adapt (needs property data source)
- **Effort**: Medium
- **Why useful**: Applicability domain check - ensures analogues are chemically sensible
- **How to adapt**: Use `epi_suite()` or CompTox property endpoints for properties

### 8. [LOW] ToxPrint Fingerprint Integration
- **What**: Using ToxPrint structural alerts as fingerprints
- **Where**: ComptoxR already has `chemi_toxprint()`, `chemi_toxprints_calculate()`
- **Extractability**: Leverage existing
- **Effort**: Low (already exists)
- **Why useful**: ToxPrints are optimized for toxicity prediction (729 features)
- **How to adapt**: Already available - just use existing functions

### 9. [LOW] Sklearn-Compatible Interface
- **What**: fit/predict API matching scikit-learn conventions
- **Where**: genra-py `cls.py`, `reg.py`, `binary.py`
- **Extractability**: Inspiration only
- **Effort**: High
- **Why useful**: Familiar interface for ML practitioners
- **Why low**: R doesn't use this pattern; tidymodels would be the equivalent but adds complexity

---

## Quick Wins (Under 1 Hour Each)

1. **SWA function** - 15 min: Simple weighted average, ~10 lines of R
2. **Wrapper combining ct_similar + ct_hazard** - 30 min: Pipeline existing functions
3. **Uncertainty (AUC + p-value)** - 30 min: Direct port using pROC package
4. **Optimal threshold finder** - 15 min: One pROC call

---

## Not Worth Porting Directly

| Item | Reason |
|------|--------|
| rcdk fingerprint generation | Heavy dependency (Java), ComptoxR has API-based ToxPrints |
| RDKit molecule parsing | Python-only, ComptoxR is API-first |
| sklearn estimator base classes | R doesn't use this pattern |
| Local Morgan fingerprints | Use cheminformatics API instead |
| Hybrid class hierarchy | Over-engineered for R package use case |

---

## Recommended Implementation Architecture

```
genra_predict()
├── genra_find_analogues()     # Wraps ct_similar + optional ct_compound_in_list
├── genra_get_tox_data()       # Wraps ct_hazard_toxref_search or ct_hazard_toxval_search
├── genra_swa()                # Local: weighted average prediction
├── genra_uncertainty()        # Local: AUC + permutation p-value
└── genra_applicability()      # Optional: physicochemical domain check
```

### Minimal Viable Implementation (~150 lines)

```r
#' GenRA Read-Across Prediction
#'
#' @param target_dtxsid Target chemical DTXSID
#' @param endpoint Toxicity endpoint to predict (e.g., "acute_oral")
#' @param k Number of nearest neighbors
#' @param min_similarity Minimum Tanimoto similarity threshold
#' @param n_permutations Permutations for p-value calculation
#'
#' @return List with prediction, uncertainty metrics, and analogue details
genra_predict <- function(
  target_dtxsid,
  endpoint = "acute_oral",
  k = 5,
  min_similarity = 0.5,
  n_permutations = 100
) {
  # 1. Find analogues
  analogues <- ct_similar(target_dtxsid, similarity = min_similarity) |>
    head(k)

  # 2. Get toxicity data for analogues
  tox_data <- ct_hazard_toxref_search(analogues$dtxsid) |>
    filter(endpoint_type == endpoint)

  # 3. Merge similarities
  analogue_tox <- left_join(analogues, tox_data, by = "dtxsid")

  # 4. Calculate SWA prediction
  prediction <- sum(analogue_tox$activity * analogue_tox$similarity) /
                sum(analogue_tox$similarity)

  # 5. Uncertainty quantification
  uncertainty <- genra_uncertainty(
    analogue_tox$activity,
    analogue_tox$similarity,
    n_permutations
  )

  list(
    target = target_dtxsid,
    prediction = prediction,
    auc = uncertainty$auc,
    p_value = uncertainty$p_value,
    n_analogues = nrow(analogue_tox),
    analogues = analogue_tox
  )
}
```

---

## Dependencies to Consider Adding

| Package | Purpose | Recommendation |
|---------|---------|----------------|
| `pROC` | AUC calculation, ROC analysis | Add (lightweight, well-maintained) |
| None else needed | Core algorithm is simple arithmetic | - |

---

## Next Steps

1. **Start with quick wins**: Implement `genra_swa()` and `genra_uncertainty()` as internal helpers
2. **Verify API endpoints**: Check if `ct_hazard_toxref_*` returns data compatible with read-across (need activity values, not just study metadata)
3. **Design user-facing function**: `genra_predict()` or `ct_read_across()` with sensible defaults
4. **Add vignette**: Show complete workflow from target chemical to prediction with uncertainty
