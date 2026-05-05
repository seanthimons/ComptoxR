#!/usr/bin/env Rscript
# ==============================================================================
# Pipeline Runner — Execute scoring and produce outputs
# ==============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(tibble)
library(stringr)

data_dir <- "/home/claude/synthetic_watershed_data"
engine_dir <- "/home/claude/scoring_engine"
output_dir <- "/home/claude/scoring_engine/results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# --- Step 0: Generate benchmarks if needed -----------------------------------

if (!file.exists(file.path(data_dir, "benchmarks.csv"))) {
  cat("Generating synthetic benchmarks...\n")
  source(file.path(engine_dir, "01_generate_benchmarks.R"))
}

# --- Load data ---------------------------------------------------------------

cat("Loading data...\n")
detections  <- read_csv(file.path(data_dir, "detections.csv"),
                         show_col_types = FALSE)
benchmarks  <- read_csv(file.path(data_dir, "benchmarks.csv"),
                         show_col_types = FALSE)
bioassay    <- read_csv(file.path(data_dir, "bioassay.csv"),
                         show_col_types = FALSE)
sites       <- read_csv(file.path(data_dir, "sites.csv"),
                         show_col_types = FALSE)
chemicals   <- read_csv(file.path(data_dir, "chemicals.csv"),
                         show_col_types = FALSE)

cat("  Detections:", nrow(detections), "records\n")
cat("  Benchmarks:", nrow(benchmarks), "records\n")
cat("  Bioassay:", nrow(bioassay), "records\n")
cat("  Sites:", nrow(sites), "\n")

# --- Load scoring engine -----------------------------------------------------

source(file.path(engine_dir, "02_scoring_engine.R"))

# =============================================================================
# RUN: Human Health Perspective
# =============================================================================

results_hh <- run_scoring_pipeline(
  detections, benchmarks, bioassay, sites,
  perspective = "human_health"
)

# --- Print site rankings -----------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("SITE RANKINGS — Human Health Perspective\n")
cat("================================================================\n\n")

results_hh$site_summary %>%
  select(site_rank, site_id, site_type, dist_nearest_discharge_km,
         mean_composite, mean_confidence, mean_benchmark_cov,
         mean_chem_concern, mean_occurrence, mean_bio) %>%
  mutate(across(where(is.numeric) & !matches("rank|dist"), ~ round(., 3))) %>%
  print(n = 20)

# --- Domain-level detail for top 5 sites ------------------------------------

cat("\n")
cat("================================================================\n")
cat("DOMAIN PROFILE — Top 5 Sites (most recent year)\n")
cat("================================================================\n\n")

top5 <- results_hh$site_summary %>% slice_min(site_rank, n = 5) %>% pull(site_id)

results_hh$domain_scores %>%
  filter(site_id %in% top5, year == 2024) %>%
  group_by(site_id, domain) %>%
  summarise(
    mean_score = round(mean(domain_score_norm, na.rm = TRUE), 3),
    mean_detect_rate = round(mean(detect_rate, na.rm = TRUE), 3),
    mean_bm_coverage = round(mean(benchmark_coverage, na.rm = TRUE), 3),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = domain,
    values_from = c(mean_score, mean_detect_rate, mean_bm_coverage),
    names_glue = "{domain}_{.value}"
  ) %>%
  print(width = Inf)

# --- Temporal trends ---------------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("TEMPORAL TRENDS — Annual composite scores by site type\n")
cat("================================================================\n\n")

temporal <- results_hh$site_events %>%
  group_by(site_type, year) %>%
  summarise(
    mean_score = round(mean(composite_score, na.rm = TRUE), 4),
    mean_chem  = round(mean(chemical_concern_score, na.rm = TRUE), 4),
    mean_occ   = round(mean(occurrence_score, na.rm = TRUE), 4),
    mean_bio   = round(mean(bio_score, na.rm = TRUE), 4),
    .groups = "drop"
  ) %>%
  arrange(site_type, year)

temporal %>%
  pivot_wider(names_from = site_type, values_from = mean_score) %>%
  print(n = 15)

# --- Confidence analysis -----------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("CONFIDENCE ANALYSIS — Benchmark coverage by domain & site type\n")
cat("================================================================\n\n")

results_hh$domain_scores %>%
  group_by(site_type, domain) %>%
  summarise(
    mean_bm_cov = round(mean(benchmark_coverage, na.rm = TRUE), 3),
    mean_conf   = round(mean(mean_confidence_weight, na.rm = TRUE), 3),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = domain, values_from = c(mean_bm_cov)) %>%
  print(width = Inf)

# --- Occurrence hotspots -----------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("OCCURRENCE HOTSPOTS — Most ubiquitous & persistent analytes\n")
cat("================================================================\n\n")

cat("Top 15 by spatial ubiquity:\n")
results_hh$occurrence_watershed %>%
  arrange(desc(spatial_ubiquity)) %>%
  select(analyte, domain, spatial_ubiquity, n_sites_detected,
         n_sites_analyzed, total_detections) %>%
  head(15) %>%
  print()

cat("\nTop 15 by temporal persistence (across all sites):\n")
results_hh$occurrence_site %>%
  group_by(analyte, domain) %>%
  summarise(
    mean_detect_freq = round(mean(detect_freq, na.rm = TRUE), 3),
    max_detect_freq  = round(max(detect_freq, na.rm = TRUE), 3),
    n_sites = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_detect_freq)) %>%
  head(15) %>%
  print()

# =============================================================================
# RUN: Aquatic Eco Perspective (for comparison)
# =============================================================================

cat("\n\n")
results_aq <- run_scoring_pipeline(
  detections, benchmarks, bioassay, sites,
  perspective = "aquatic_eco"
)

cat("\n")
cat("================================================================\n")
cat("SITE RANKINGS — Aquatic Eco Perspective\n")
cat("================================================================\n\n")

results_aq$site_summary %>%
  select(site_rank, site_id, site_type, dist_nearest_discharge_km,
         mean_composite, mean_confidence, mean_benchmark_cov) %>%
  mutate(across(where(is.numeric) & !matches("rank|dist"), ~ round(., 3))) %>%
  print(n = 20)

# =============================================================================
# PERSPECTIVE COMPARISON
# =============================================================================

cat("\n")
cat("================================================================\n")
cat("PERSPECTIVE COMPARISON — Do rankings change?\n")
cat("================================================================\n\n")

comparison <- results_hh$site_summary %>%
  select(site_id, hh_rank = site_rank, hh_score = mean_composite) %>%
  left_join(
    results_aq$site_summary %>%
      select(site_id, aq_rank = site_rank, aq_score = mean_composite),
    by = "site_id"
  ) %>%
  mutate(
    rank_shift = hh_rank - aq_rank,
    rank_shift_dir = case_when(
      rank_shift > 1 ~ "higher_concern_aquatic",
      rank_shift < -1 ~ "higher_concern_human",
      TRUE ~ "stable"
    )
  ) %>%
  arrange(hh_rank)

comparison %>%
  mutate(across(where(is.numeric), ~ round(., 3))) %>%
  print(n = 20)

cat("\nRank stability: ",
    sum(abs(comparison$rank_shift) <= 2), "of", nrow(comparison),
    "sites shifted ≤2 ranks between perspectives\n")

# =============================================================================
# WRITE RESULTS
# =============================================================================

cat("\nWriting results...\n")

write_csv(results_hh$site_summary,
          file.path(output_dir, "site_rankings_human_health.csv"))
write_csv(results_hh$site_events,
          file.path(output_dir, "site_events_human_health.csv"))
write_csv(results_hh$domain_scores,
          file.path(output_dir, "domain_scores_human_health.csv"))
write_csv(results_hh$occurrence_watershed,
          file.path(output_dir, "occurrence_watershed.csv"))

write_csv(results_aq$site_summary,
          file.path(output_dir, "site_rankings_aquatic_eco.csv"))
write_csv(comparison,
          file.path(output_dir, "perspective_comparison.csv"))

cat("Results written to:", output_dir, "\n")
cat("\nFiles:\n")
list.files(output_dir) %>% walk(~ cat("  -", .x, "\n"))
