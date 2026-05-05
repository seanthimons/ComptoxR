# Scoring Engine — Tuning Guide & Decision Register
## Road-test this alongside `02_scoring_engine.R`

Every `[TUNE]` is a knob you can turn. Every `[CONSIDER]` is an architectural choice that may need revisiting with real data. Organized by function in the order they execute.

---

## 1. `compute_occurrence_site()`

### [CONSIDER] WQ_Metrics exclusion
WQ parameters are filtered out because they're continuous measurements, not detect/non-detect. If you add biological parameters to the WQ domain that ARE detect-based (e.g., E. coli, chlorophyll-a), you'll need to either split the domain or handle them separately.

### [TUNE] Temporal trend method
**Current:** Pearson correlation of concentration (NDs replaced with 0) against time.

**Problems with current approach:**
- Replacing NDs with 0 biases the correlation downward
- Pearson assumes linearity and normality — neither holds for environmental concentration data

**Alternatives to try:**
- Kendall tau (non-parametric, better for censored data)
- `NADA::cenken()` for proper censored regression
- Only use detected values (ignores censoring but avoids the ND=0 problem)
- Weight recent observations more heavily with exponential decay

### [TUNE] Minimum detections for trend: currently 3
With 144 possible events per site, requiring only 3 detections is very permissive. A compound detected 3 times out of 144 events gives you almost no trend power. Consider raising to 8-10, or computing a trend confidence interval and only propagating "significant" trends.

---

## 2. `compute_occurrence_watershed()`

### [CONSIDER] Spatiotemporal collapse
A compound detected at 18/18 sites once each over 12 years is treated identically to one detected at 18/18 sites every month. Detection frequency (temporal) and spatial ubiquity are separate metrics — you may want a combined "spatiotemporal ubiquity" = fraction of all site-events where detection occurred.

### [CONSIDER] Method coverage in the denominator
The denominator is `n_distinct(site_id)` from the detections table, which only includes sites where the method ran. So 5/5 sites where the method was run = 100% ubiquitous, even though 13 other sites were never tested. This is correct by construction but should be noted in your methods section. The method_coverage table exists for exactly this context.

---

## 3. `score_analytes()` — THE CRITICAL FUNCTION

### [CONSIDER] Benchmark join: one benchmark per analyte per perspective
Current design assumes one row per analyte per perspective. If a compound has BOTH an MCL and an RfD for human health, the benchmark generator should pick one (currently: highest tier / most authoritative). You might instead want the most PROTECTIVE (lowest value). Modify `01_generate_benchmarks.R` to `slice_min(benchmark_value)` grouped by analyte + perspective.

### [TUNE] HQ-to-score transform — THE MOST CONSEQUENTIAL DECISION

**Current:** `(log10(HQ) + 3) / 6`, clamped to [0, 1]

This maps:
| HQ | Score | Interpretation |
|----|-------|----------------|
| 0.001 | 0.00 | 1000x below benchmark |
| 0.01 | 0.17 | 100x below |
| 0.1 | 0.33 | 10x below |
| 1.0 | **0.50** | **AT the benchmark** |
| 10 | 0.67 | 10x above |
| 100 | 0.83 | 100x above |
| 1000 | 1.00 | 1000x above (capped) |

The log transform means orders of magnitude matter more than small differences. A compound at 2x its benchmark scores only slightly higher than one at 1x. This is appropriate for screening but may underweight exceedances if your management wants "above benchmark = high concern."

**Alternatives to road-test:**

1. **Sigmoid:** `1 / (1 + exp(-k * (log10(HQ) - midpoint)))` — tunable steepness (k) and inflection point. k=3, midpoint=0 puts a steep cliff right at HQ=1. More aggressive than log for separating above/below benchmark.

2. **Threshold:** `case_when(HQ < 0.1 ~ 0, HQ < 1 ~ 0.33, HQ < 10 ~ 0.67, TRUE ~ 1)`. Coarse but very interpretable for management. "Green / Yellow / Orange / Red."

3. **Rank-based:** rank all HQs, normalize to [0,1]. Fully relative, no absolute meaning. Good for prioritization, bad for communicating exceedance.

4. **Linear with cap:** `pmin(1, HQ)`. Simple. HQ=1 scores 1.0. Everything above is equal. Only works if most HQs are <1.

**The floor (0.001) and ceiling (1000)** define your dynamic range. Check your real data distribution and adjust. If all your HQs are between 0.01 and 100, change to `(log10(HQ) + 2) / 4` to use the full [0,1] range.

### [TUNE] Detection without benchmark: score = 0.2

This is a **policy decision**, not a statistical one. Options:

| Value | Philosophy |
|-------|-----------|
| 0.0 | "No benchmark = no score" — punishes data-poor compounds, rewards ignorance |
| 0.2 | Mild flag (current) — acknowledges presence without claiming harm |
| 0.5 | Treat as AT-benchmark — precautionary principle |
| `0.2 * detect_freq` | Scale by persistence — more often = more concern |
| `0.5 * spatial_ubiquity` | Scale by spatial extent — everywhere = more concern |

If your program is precautionary, bump to 0.3-0.5. If your management needs "defensible," keep 0.2 and let the completeness layer tell the story.

---

## 4. `aggregate_to_domain()` — Within-domain rollup

### [TUNE] Aggregation strategy: max vs. mean vs. sum

All three are computed. Only ONE propagates up. **Currently: max (worst-case).**

| Strategy | Question it answers | Risk |
|----------|-------------------|------|
| **MAX** | "What's the worst thing in this domain?" | Single outlier dominates; masks pattern of moderate contamination |
| **MEAN** | "On average, how bad is this domain?" | Diluted by many NDs/low scores; misses the single bad actor |
| **SUM** | "What's the total burden in this domain?" | Domains with more analytes score higher mechanically |
| **SUM/n** | "What's the average burden per analyte?" | Normalizes for domain size but loses cumulative signal |

**Recommendation:** Run all three on real data and compare rank stability. If they agree, report whichever is most interpretable. If they disagree, that divergence is a finding.

To switch: in `aggregate_to_family()`, change `domain_score_max` to `domain_score_mean` or `domain_score_sum / n_analyzed`.

### [CONSIDER] Occurrence sub-metric weighting
Four sub-metrics (detect_intensity, temporal_persistence, spatial_extent, trend_signal) are currently averaged equally. Consider weighting them differently by context:
- Single-site assessment: persistence matters most
- Watershed-level prioritization: spatial extent matters most
- Trend-focused reporting: trend signal matters most

### [CONSIDER] Trend signal cancellation
If half the analytes in a domain are increasing and half decreasing, the mean trend ≈ 0. This may mask important dynamics. Consider: `max(abs(trend))` to flag domains with ANY strong trend, or split into separate increasing/decreasing sub-metrics.

---

## 5. `aggregate_to_family()` — Missing domain handling

### [CONSIDER] Weight redistribution for missing domains

When a site-event lacks data for a domain (method wasn't run), the weighted sum only covers present domains, with weights renormalized. This REDISTRIBUTES weight.

**Implications:**
- PRO: Doesn't penalize sites for methods not run
- CON: A site with ONLY Metals data gets its entire score from Metals, potentially looking "cleaner" than one with Metals + PFAS + VOCs

**Alternatives:**
- Impute missing domains as 0 (penalizes missing data — conservative)
- Impute as watershed-wide median for that domain (neutral)
- Only score sites with minimum coverage (e.g., ≥4/7 domains)
- Keep current approach but flag low-coverage sites in the completeness layer

---

## 6. `compute_site_event_score()` — The composite

### [TUNE] Bioassay score transform
**Current:** `log10(fold_induction) / log10(10)`, clamped [0, 1].

Ceiling at 10-fold may be too low. AhR responses can exceed 100-fold for potent agonists. Check your real assay data distribution and adjust: use `log10(fold) / log10(empirical_max)` to calibrate to your observed range.

**Alternative:** Normalize to a reference standard (e.g., % of TCDD-equivalent max response). This would make the score biologically anchored.

### [CONSIDER] Bioassay QC filtering
Currently only "Pass" results are used. Consider:
- Include "Flag-matrix" at reduced confidence weight
- Impute missing bioassay events with site historical median
- Track bioassay coverage separately in the completeness layer

### [TUNE] Top-level slice weights: 0.45 / 0.25 / 0.30
These are hardcoded. **TODO:** Wire to `weights$slice_weights` from the perspective profile so they change with perspective switching.

### [CONSIDER] Missing bioassay → score = 0
When bio data is missing, `bio_score` is filled with 0. This effectively penalizes sites without bioassay data on 30% of their composite. Alternative: redistribute bio weight to chem + occurrence when bio is missing.

### [CONSIDER] Monte Carlo sensitivity
Sample slice weights from a Dirichlet(α=1) distribution (ensures sum to 1), re-score under each draw. Sites whose rank is stable across 1000+ draws are robust; rank-sensitive sites need more data or stronger justification.

---

## 7. `get_perspective_weights()` — Weight profiles

### [TUNE] Every weight in every profile is adjustable
These encode value judgments. Document rationale for each when you finalize.

### [CONSIDER] Deriving weights empirically
Options:
- R² approach (ToxPi baseball paper): weight proportional to correlation with a reference outcome (e.g., bioassay response)
- PCA loadings on domain scores
- Stakeholder elicitation (Delphi, pairwise comparison)
- Show that rankings are robust regardless of weights within a plausible range

### [CONSIDER] Aquatic eco + WQ_Parameters
WQ parameters (DO, pH, temperature) are directly relevant to aquatic organism health. Consider giving WQ_Parameters a non-zero weight in the aquatic_eco perspective, with appropriate benchmarks (DO < 5 mg/L, pH outside 6.5-9.0, temperature > thermal criteria).

---

## 8. `normalize_domain_scores()` — Normalization scope

### [TUNE] Global max vs. alternatives

**Current:** Each domain score is divided by the global max for that domain across all site-events. This makes scores relative to the dataset.

**Consequence:** Adding or removing sites/events changes ALL normalized scores. This is appropriate for ranking within a fixed dataset but problematic for monitoring over time (new data shifts the baseline).

**Alternatives:**
| Method | Pros | Cons |
|--------|------|------|
| Global max (current) | Uses full [0,1] range | Unstable as data grows |
| Fixed reference (HQ=1000 → 1.0) | Stable, absolute meaning | Wastes range if real HQs are all small |
| Per-event max | Removes temporal confounding | Cross-event comparison invalid |
| Percentile rank | Robust to outliers | Loses magnitude information |

For the **expectation-vs-observed spatial analysis**, fixed-reference normalization is better because you need stable scores to compute residuals from the spatial decay model.

---

## 9. `run_scoring_pipeline()` — Site-level summary

### [TUNE] Site ranking metric: mean_composite
Currently sites are ranked by their mean composite score across all events. This gives equal weight to every month over 12 years.

**Alternatives:**
- `max_composite`: "How bad was the worst month?" (acute framing)
- `median`: More robust to outlier events
- `quantile(0.90)`: "What does a bad month look like?"
- Mean of most recent 12-24 events: "What's the current state?"
- Weighted mean with exponential time decay: recent events matter more

### [CONSIDER] Trend detection method
Simple linear regression (`lm`) assumes linear trend. Consider:
- Mann-Kendall test for monotonic trend (non-parametric)
- Segmented regression for changepoint detection ("contamination started in 2019")
- Seasonal decomposition (STL) before trend fitting to avoid seasonal aliasing
- Require p < 0.05 on the trend before reporting it

---

## 10. Cross-cutting concerns

### [CONSIDER] Units harmonization
The synthetic data has mixed units (ug/L, ng/L, mg/L, pCi/L). The HQ calculation works because benchmarks are in the same units as detections. With real data, enforce unit matching or add a conversion step.

### [CONSIDER] Non-detect handling in HQ
NDs currently score 0. If a compound is detected at 0.5x its benchmark and the ND is reported at 0.3x the RL, the ND effectively scores 0 while the detection scores ~0.45. This cliff between "just below RL" and "just above RL" may overweight detection status relative to concentration. Consider using RL/2 as a substituted value for NDs (standard practice in environmental stats, though debated).

### [CONSIDER] Seasonality
Seasonal patterns in VOCs and DO are baked into the synthetic data. If you compute annual summaries (which the site_summary does), seasonal effects average out. But if you compare individual months across sites, a site sampled only in summer will look different from one sampled in winter. Consider seasonal adjustment or require balanced sampling before comparison.

### [CONSIDER] Distance-from-discharge
Not currently used in scoring (by design — we discussed stratification vs. embedding). The spatial structure shows up naturally in the results. When you get to the expectation-vs-observed analysis, you'd build a simple spatial decay model from the scores and look at residuals.
