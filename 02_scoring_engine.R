#!/usr/bin/env Rscript
# ==============================================================================
# Hierarchical Site Prioritization Scoring Engine
# ==============================================================================
#
# Architecture:
#   analyte_score → domain_score → family_score → order_score → site_event_score
#
# Three parallel order-level slices:
#   1. Chemical Concern  (HQ-based, from benchmarks)
#   2. Occurrence Signal  (detection frequency, spatial ubiquity, trend)
#   3. Bioactivity        (AhR fold-induction or other endpoints)
#
# Completeness/confidence travels alongside as metadata, never baked into score.
#
# Switchable perspective profiles control which endpoints and weights are active.
#
# Usage:
#   source("02_scoring_engine.R")
#   results <- run_scoring_pipeline(
#     detections, benchmarks, bioassay, sites,
#     perspective = "human_health",
#     weights = NULL  # uses defaults
#   )
# ==============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(tibble)

# =============================================================================
# PART 1: PRE-COMPUTATION — Occurrence Features
# =============================================================================

#' Compute per-analyte, per-site temporal occurrence features
#'
#' @param detections Full detection dataset
#' @return tibble with site_id, analyte_id, detect_freq, conc_trend, max_conc, etc.
compute_occurrence_site <- function(detections) {
  detections %>%
    filter(domain != "WQ_Metrics") %>%
    group_by(site_id, analyte_id, analyte, domain, family, order) %>%
    summarise(
      n_events_analyzed = n(),
      n_detected        = sum(detected, na.rm = TRUE),
      detect_freq       = n_detected / n_events_analyzed,
      max_conc          = max(concentration, na.rm = TRUE),
      median_conc       = median(concentration[detected == 1], na.rm = TRUE),
      # Temporal trend: correlation of concentration with time
      # Positive = increasing, negative = decreasing
      # [TUNE] min detections for trend; see TUNING_GUIDE.md §1
      conc_trend = if (sum(detected) >= 3) {
        suppressWarnings(
          cor(as.numeric(sample_date),
              replace(concentration, is.na(concentration), 0),
              use = "complete.obs")
        )
      } else { NA_real_ },
      .groups = "drop"
    ) %>%
    mutate(
      max_conc    = if_else(is.infinite(max_conc), NA_real_, max_conc),
      median_conc = if_else(is.nan(median_conc), NA_real_, median_conc)
    )
}

#' Compute per-analyte watershed-wide spatial ubiquity
#'
#' @param detections Full detection dataset
#' @return tibble with analyte_id, n_sites_analyzed, n_sites_detected, spatial_ubiquity
compute_occurrence_watershed <- function(detections) {
  detections %>%
    filter(domain != "WQ_Metrics") %>%
    group_by(analyte_id, analyte, domain) %>%
    summarise(
      n_sites_analyzed  = n_distinct(site_id),
      n_sites_detected  = n_distinct(site_id[detected == 1]),
      spatial_ubiquity  = n_sites_detected / n_sites_analyzed,
      total_detections  = sum(detected, na.rm = TRUE),
      .groups = "drop"
    )
}

# =============================================================================
# PART 2: ANALYTE-LEVEL SCORING
# =============================================================================

#' Score individual analytes at a site-event
#'
#' For each detected analyte, compute:
#'   - Hazard Quotient (concentration / benchmark) if benchmark exists
#'   - Detection-only flag if no benchmark
#'   - Attach occurrence features and confidence metadata
#'
#' @param detections Detection data (can be filtered to one site-event or full)
#' @param benchmarks Benchmark table for the active perspective
#' @param occurrence_site Pre-computed site-level occurrence features
#' @param occurrence_watershed Pre-computed watershed-level occurrence features
#' @return tibble with scored analytes
score_analytes <- function(detections, benchmarks, occurrence_site,
                           occurrence_watershed) {

  scored <- detections %>%
    filter(domain != "WQ_Metrics") %>%
    # Join benchmarks
    left_join(
      benchmarks %>%
        select(analyte_id, perspective,
               benchmark_value, benchmark_tier,
               authority_label, confidence_weight),
      by = "analyte_id"
    ) %>%
    # Compute HQ
    mutate(
      has_benchmark = !is.na(benchmark_value) & benchmark_tier < 6,
      hazard_quotient = case_when(
        detected == 1 & has_benchmark ~ concentration / benchmark_value,
        detected == 1 & !has_benchmark ~ NA_real_,
        TRUE ~ 0
      ),
      # [TUNE] HQ-to-score transform — see TUNING_GUIDE.md §3 for alternatives
      # log10 mapping: HQ=0.001→0, HQ=1→0.5, HQ=1000→1
      hq_score = case_when(
        detected == 0 ~ 0,
        has_benchmark  ~ pmin(log10(pmax(hazard_quotient, 0.001)) + 3, 6) / 6,
        # [TUNE] Detection without benchmark — see TUNING_GUIDE.md §3
        !has_benchmark & detected == 1 ~ 0.2,
        TRUE ~ 0
      ),
      # Clamp to [0, 1]
      hq_score = pmax(0, pmin(1, hq_score))
    ) %>%
    # Join occurrence features
    left_join(
      occurrence_site %>%
        select(site_id, analyte_id, detect_freq, conc_trend),
      by = c("site_id", "analyte_id")
    ) %>%
    left_join(
      occurrence_watershed %>%
        select(analyte_id, spatial_ubiquity),
      by = "analyte_id"
    )

  return(scored)
}

# =============================================================================
# PART 3: HIERARCHICAL AGGREGATION
# =============================================================================

#' Aggregate analyte scores to domain level (the ToxPi "slice")
#'
#' For each domain at a site-event:
#'   - Score: max HQ score across analytes (worst-case within domain)
#'   - Also compute mean for robustness comparison
#'   - Track completeness: % of detected analytes with benchmarks
#'
#' @param scored_analytes Output of score_analytes()
#' @return tibble at the site_id × event_id × domain level
aggregate_to_domain <- function(scored_analytes) {
  scored_analytes %>%
    group_by(site_id, event_id, sample_date, year, month,
             site_type, dist_nearest_discharge_km,
             domain, family, order) %>%
    summarise(
      # --- Chemical concern scores ---
      n_analyzed       = n(),
      n_detected       = sum(detected, na.rm = TRUE),
      n_with_benchmark = sum(has_benchmark & detected == 1, na.rm = TRUE),
      detect_rate      = n_detected / n_analyzed,

      # [TUNE] Within-domain aggregation — see TUNING_GUIDE.md §4
      # Currently MAX propagates up; switch in aggregate_to_family()
      # Max HQ score (worst-case driver)
      domain_score_max  = if (any(detected == 1)) max(hq_score[detected == 1],
                                                       na.rm = TRUE) else 0,
      # Mean HQ score (central tendency)
      domain_score_mean = if (any(detected == 1)) mean(hq_score[detected == 1],
                                                        na.rm = TRUE) else 0,
      # Sum of HQ scores (cumulative burden)
      domain_score_sum  = sum(hq_score, na.rm = TRUE),

      # --- Occurrence signal ---
      occ_detect_intensity = n_detected / n_analyzed,
      occ_temporal_persistence = if (any(!is.na(detect_freq)))
        mean(detect_freq[detected == 1], na.rm = TRUE) else 0,
      occ_spatial_extent = if (any(!is.na(spatial_ubiquity)))
        mean(spatial_ubiquity[detected == 1], na.rm = TRUE) else 0,
      occ_trend_signal = if (any(!is.na(conc_trend)))
        mean(conc_trend[detected == 1], na.rm = TRUE) else 0,

      # --- Confidence metadata ---
      benchmark_coverage = if (n_detected > 0)
        n_with_benchmark / n_detected else NA_real_,
      mean_confidence_weight = if (any(has_benchmark & detected == 1))
        mean(confidence_weight[has_benchmark & detected == 1],
             na.rm = TRUE) else 0,
      authority_mix = paste(sort(unique(
        authority_label[detected == 1 & has_benchmark]
      )), collapse = "|"),

      .groups = "drop"
    ) %>%
    mutate(
      # Normalize domain scores to [0, 1] will happen later at the
      # site-event level (relative to all domains in this event)
      domain_score_max  = if_else(is.infinite(domain_score_max), 0,
                                   domain_score_max),
      domain_score_mean = if_else(is.nan(domain_score_mean), 0,
                                   domain_score_mean)
    )
}

#' Aggregate domain scores to family level
#'
#' @param domain_scores Output of aggregate_to_domain()
#' @param domain_weights Named vector of domain weights (NULL = equal)
#' @return tibble at the site_id × event_id × family level
aggregate_to_family <- function(domain_scores, domain_weights = NULL) {

  if (is.null(domain_weights)) {
    # Equal weights across domains
    all_domains <- unique(domain_scores$domain)
    domain_weights <- setNames(rep(1, length(all_domains)), all_domains)
  }

  # Normalize weights
  domain_weights <- domain_weights / sum(domain_weights)

  # [CONSIDER] Missing domain weight redistribution — see TUNING_GUIDE.md §5
  domain_scores %>%
    mutate(
      w = domain_weights[domain],
      w = replace_na(w, 0)
    ) %>%
    group_by(site_id, event_id, sample_date, year, month,
             site_type, dist_nearest_discharge_km,
             family, order) %>%
    summarise(
      family_score = sum(domain_score_max * w, na.rm = TRUE) / sum(w),
      family_occ   = sum(occ_detect_intensity * w, na.rm = TRUE) / sum(w),
      family_benchmark_coverage = weighted.mean(
        replace_na(benchmark_coverage, 0), w, na.rm = TRUE
      ),
      family_confidence = weighted.mean(
        mean_confidence_weight, w, na.rm = TRUE
      ),
      n_domains = n(),
      .groups = "drop"
    )
}

#' Aggregate family scores to order level
#'
#' @param family_scores Output of aggregate_to_family()
#' @param family_weights Named vector of family weights (NULL = equal)
#' @return tibble at the site_id × event_id × order level
aggregate_to_order <- function(family_scores, family_weights = NULL) {

  if (is.null(family_weights)) {
    all_families <- unique(family_scores$family)
    family_weights <- setNames(rep(1, length(all_families)), all_families)
  }

  family_weights <- family_weights / sum(family_weights)

  family_scores %>%
    mutate(
      w = family_weights[family],
      w = replace_na(w, 0)
    ) %>%
    group_by(site_id, event_id, sample_date, year, month,
             site_type, dist_nearest_discharge_km,
             order) %>%
    summarise(
      order_score      = sum(family_score * w, na.rm = TRUE) / sum(w),
      order_occ        = sum(family_occ * w, na.rm = TRUE) / sum(w),
      order_confidence = weighted.mean(family_confidence, w, na.rm = TRUE),
      order_benchmark_coverage = weighted.mean(
        family_benchmark_coverage, w, na.rm = TRUE
      ),
      n_families = n(),
      .groups = "drop"
    )
}

# =============================================================================
# PART 4: SITE-EVENT COMPOSITE SCORE
# =============================================================================

#' Compute final site-event scores combining all order-level slices
#'
#' @param order_scores Output of aggregate_to_order()
#' @param bioassay Bioassay data
#' @param order_weights Named vector of order weights (NULL = equal)
#' @param bio_weight Weight for bioactivity slice (default 1)
#' @return tibble with one row per site-event
compute_site_event_score <- function(order_scores, bioassay,
                                      order_weights = NULL,
                                      bio_weight = 1) {

  if (is.null(order_weights)) {
    all_orders <- unique(order_scores$order)
    order_weights <- setNames(rep(1, length(all_orders)), all_orders)
  }

  order_weights <- order_weights / sum(order_weights)

  # --- Chemical Concern slice ---
  chem_concern <- order_scores %>%
    mutate(
      w = order_weights[order],
      w = replace_na(w, 0)
    ) %>%
    group_by(site_id, event_id, sample_date, year, month,
             site_type, dist_nearest_discharge_km) %>%
    summarise(
      chemical_concern_score = sum(order_score * w, na.rm = TRUE) / sum(w),
      occurrence_score       = sum(order_occ * w, na.rm = TRUE) / sum(w),
      overall_confidence     = weighted.mean(order_confidence, w, na.rm = TRUE),
      overall_benchmark_cov  = weighted.mean(
        order_benchmark_coverage, w, na.rm = TRUE
      ),
      n_orders = n(),
      .groups = "drop"
    )

  # --- Bioactivity slice ---
  bio_slice <- bioassay %>%
    filter(ahr_qc_flag == "Pass") %>%
    mutate(
      # [TUNE] Bio score transform — see TUNING_GUIDE.md §6
      # fold=1→0, fold=10→1 (capped); adjust ceiling for your assay range
      bio_score = pmin(1, pmax(0, log10(pmax(ahr_fold_induction, 1)) / log10(10)))
    ) %>%
    select(site_id, event_id, bio_score, ahr_fold_induction, ahr_significant)

  # --- Combine ---
  # [TUNE] Top-level slice weights — see TUNING_GUIDE.md §6
  # TODO: wire to weights$slice_weights from perspective profile
  # These are the Monte Carlo sensitivity targets
  w_chem <- 0.45
  w_occ  <- 0.25
  w_bio  <- 0.30

  site_event <- chem_concern %>%
    left_join(bio_slice, by = c("site_id", "event_id")) %>%
    mutate(
      bio_score = replace_na(bio_score, 0),

      # === THE COMPOSITE SCORE ===
      composite_score = (
        w_chem * chemical_concern_score +
        w_occ  * occurrence_score +
        w_bio  * bio_score
      ),

      # Rank (1 = highest concern)
      composite_rank = rank(-composite_score, ties.method = "average")
    )

  return(site_event)
}

# =============================================================================
# PART 5: PERSPECTIVE PROFILES
# =============================================================================

#' Define perspective weight profiles
#'
#' Returns a list of weight vectors for different risk perspectives.
#' These control which domains/families/orders get emphasized.
get_perspective_weights <- function(perspective = "human_health") {

  profiles <- list(

    human_health = list(
      order_weights  = c(
        "Organics"       = 3,
        "Inorganics"     = 2,
        "Radionuclides"  = 2,
        "WQ_Parameters"  = 0  # excluded
      ),
      domain_weights = c(
        "VOCs"           = 2,
        "SVOCs"          = 2,
        "PFAS"           = 3,
        "Hydrocarbons"   = 1,
        "Metals"         = 2,
        "Radionuclides"  = 2,
        "WQ_Metrics"     = 0
      ),
      slice_weights = c(chem = 0.45, occ = 0.25, bio = 0.30)
    ),

    aquatic_eco = list(
      order_weights  = c(
        "Organics"       = 3,
        "Inorganics"     = 3,
        "Radionuclides"  = 1,
        "WQ_Parameters"  = 0
      ),
      domain_weights = c(
        "VOCs"           = 1,
        "SVOCs"          = 2,
        "PFAS"           = 3,
        "Hydrocarbons"   = 3,
        "Metals"         = 3,
        "Radionuclides"  = 1,
        "WQ_Metrics"     = 0
      ),
      slice_weights = c(chem = 0.35, occ = 0.25, bio = 0.40)
    ),

    terrestrial_eco = list(
      order_weights  = c(
        "Organics"       = 2,
        "Inorganics"     = 3,
        "Radionuclides"  = 2,
        "WQ_Parameters"  = 0
      ),
      domain_weights = c(
        "VOCs"           = 2,
        "SVOCs"          = 2,
        "PFAS"           = 2,
        "Hydrocarbons"   = 1,
        "Metals"         = 3,
        "Radionuclides"  = 2,
        "WQ_Metrics"     = 0
      ),
      slice_weights = c(chem = 0.40, occ = 0.30, bio = 0.30)
    ),

    emergency_response = list(
      order_weights  = c(
        "Organics"       = 3,
        "Inorganics"     = 2,
        "Radionuclides"  = 3,
        "WQ_Parameters"  = 0
      ),
      domain_weights = c(
        "VOCs"           = 3,    # acute inhalation concern
        "SVOCs"          = 1,
        "PFAS"           = 2,
        "Hydrocarbons"   = 3,    # fire/explosion
        "Metals"         = 1,
        "Radionuclides"  = 3,
        "WQ_Metrics"     = 0
      ),
      # Emergency: care more about what's there NOW, less about history
      slice_weights = c(chem = 0.60, occ = 0.10, bio = 0.30)
    )
  )

  if (!perspective %in% names(profiles)) {
    stop("Unknown perspective: ", perspective,
         ". Available: ", paste(names(profiles), collapse = ", "))
  }

  return(profiles[[perspective]])
}

# =============================================================================
# PART 6: NORMALIZATION (ToxPi-style, no trig)
# =============================================================================

#' Normalize domain scores within each site-event to [0, 1]
#' using max-normalization across the full dataset (not per-event)
#'
#' @param domain_scores Output of aggregate_to_domain()
#' @return Same tibble with normalized score columns added
normalize_domain_scores <- function(domain_scores) {
  # [TUNE] Normalization scope: global max — see TUNING_GUIDE.md §8
  # Global max per domain (across all site-events)
  global_max <- domain_scores %>%
    group_by(domain) %>%
    summarise(
      max_score = max(domain_score_max, na.rm = TRUE),
      max_occ   = max(occ_detect_intensity, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      max_score = if_else(max_score == 0, 1, max_score),
      max_occ   = if_else(max_occ == 0, 1, max_occ)
    )

  domain_scores %>%
    left_join(global_max, by = "domain") %>%
    mutate(
      domain_score_norm = domain_score_max / max_score,
      domain_occ_norm   = occ_detect_intensity / max_occ
    ) %>%
    select(-max_score, -max_occ)
}

# =============================================================================
# PART 7: MASTER PIPELINE
# =============================================================================

#' Run the full scoring pipeline
#'
#' @param detections Full detection dataset
#' @param benchmarks Full benchmark dataset
#' @param bioassay Bioassay dataset
#' @param sites Site metadata
#' @param perspective One of: human_health, aquatic_eco, terrestrial_eco, emergency_response
#' @param custom_weights Optional list to override perspective weights
#' @return List with all intermediate and final results
run_scoring_pipeline <- function(detections, benchmarks, bioassay, sites,
                                  perspective = "human_health",
                                  custom_weights = NULL) {

  cat("=== Scoring Pipeline ===\n")
  cat("Perspective:", perspective, "\n\n")

  # Get weights
  if (is.null(custom_weights)) {
    weights <- get_perspective_weights(perspective)
  } else {
    weights <- custom_weights
  }

  # Filter benchmarks to perspective
  bench_active <- benchmarks %>%
    filter(perspective == !!perspective)

  cat("Step 1: Pre-computing occurrence features...\n")
  occ_site      <- compute_occurrence_site(detections)
  occ_watershed <- compute_occurrence_watershed(detections)

  cat("Step 2: Scoring analytes...\n")
  scored <- score_analytes(detections, bench_active, occ_site, occ_watershed)

  cat("Step 3: Aggregating to domain level...\n")
  domain_scores <- aggregate_to_domain(scored)
  domain_scores <- normalize_domain_scores(domain_scores)

  cat("Step 4: Aggregating to family level...\n")
  family_scores <- aggregate_to_family(domain_scores, weights$domain_weights)

  cat("Step 5: Aggregating to order level...\n")
  order_scores <- aggregate_to_order(family_scores)

  cat("Step 6: Computing site-event composite scores...\n")
  site_event <- compute_site_event_score(
    order_scores, bioassay,
    order_weights = weights$order_weights
  )

  cat("Step 7: Computing site-level summaries...\n")
  site_summary <- site_event %>%
    group_by(site_id, site_type, dist_nearest_discharge_km) %>%
    summarise(
      n_events = n(),
      mean_composite  = mean(composite_score, na.rm = TRUE),
      max_composite   = max(composite_score, na.rm = TRUE),
      sd_composite    = sd(composite_score, na.rm = TRUE),
      mean_confidence = mean(overall_confidence, na.rm = TRUE),
      mean_benchmark_cov = mean(overall_benchmark_cov, na.rm = TRUE),
      mean_chem_concern = mean(chemical_concern_score, na.rm = TRUE),
      mean_occurrence   = mean(occurrence_score, na.rm = TRUE),
      mean_bio          = mean(bio_score, na.rm = TRUE),
      # [TUNE] Trend method — see TUNING_GUIDE.md §9
      # Consider Mann-Kendall or changepoint detection
      trend_slope = if (n() >= 6) {
        suppressWarnings(
          coef(lm(composite_score ~ as.numeric(sample_date)))[2]
        )
      } else { NA_real_ },
      .groups = "drop"
    ) %>%
    mutate(
      # [TUNE] Ranking uses mean_composite — see TUNING_GUIDE.md §9
      # Alternatives: max, median, quantile(0.90), recent-N mean
      site_rank = rank(-mean_composite, ties.method = "average")
    ) %>%
    arrange(site_rank)

  cat("\nDone!\n")

  return(list(
    perspective     = perspective,
    weights         = weights,
    scored_analytes = scored,
    domain_scores   = domain_scores,
    family_scores   = family_scores,
    order_scores    = order_scores,
    site_events     = site_event,
    site_summary    = site_summary,
    occurrence_site = occ_site,
    occurrence_watershed = occ_watershed
  ))
}
