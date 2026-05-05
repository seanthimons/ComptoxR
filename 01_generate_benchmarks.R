#!/usr/bin/env Rscript
# ==============================================================================
# Synthetic Benchmark Generator
# ==============================================================================
# Creates placeholder benchmark/threshold data for the chemical portfolio.
# Simulates the tiered benchmark cascade:
#   Tier 1: Regulatory (MCLs, PHGs)
#   Tier 2: Risk-based (RfDs, CTVs from DCAP)
#   Tier 3: Hazard-derived (ECOTOX eco_tbl midpoints)
#   Tier 4: ML-predicted (von Borries PODs, chemi_hazard numerical)
#   Tier 5: Screening (GHS H-code midpoints)
#   Tier 6: None (no benchmark)
#
# Each benchmark record includes:
#   - analyte_id, cas
#   - benchmark_value (in same units as detection data)
#   - benchmark_tier (1-6)
#   - benchmark_source (descriptive)
#   - authority_label
#   - perspective (human_health, aquatic_eco, terrestrial_eco, general)
#   - confidence_weight (0-1, derived from tier + data quality)
#
# REPLACE THIS with real data from ToxValDB, ECOTOX, DCAP, von Borries et al.
# ==============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(tibble)

set.seed(123)

data_dir <- "/home/claude/synthetic_watershed_data"
chemicals <- read_csv(file.path(data_dir, "chemicals.csv"), show_col_types = FALSE)

# --- Benchmark coverage probabilities by domain ------------------------------
# Simulates real-world pattern: well-studied compounds get more benchmarks

domain_coverage <- tribble(
  ~domain,          ~tier1_prob, ~tier2_prob, ~tier3_prob, ~tier4_prob, ~tier5_prob,
  "VOCs",           0.70,        0.15,        0.05,        0.05,        0.03,
  "SVOCs",          0.50,        0.20,        0.10,        0.10,        0.05,
  "Hydrocarbons",   0.25,        0.15,        0.10,        0.10,        0.10,
  "PFAS",           0.30,        0.20,        0.15,        0.20,        0.10,
  "Metals",         0.85,        0.10,        0.03,        0.01,        0.01,
  "Radionuclides",  0.80,        0.10,        0.05,        0.03,        0.02,
  "WQ_Metrics",     0.90,        0.05,        0.03,        0.01,        0.01
)

# --- Generate benchmarks per perspective -------------------------------------

perspectives <- c("human_health", "aquatic_eco", "terrestrial_eco")

# For each chemical, assign a benchmark tier per perspective
# Some chemicals have benchmarks in one perspective but not another

benchmarks <- chemicals %>%
  select(analyte_id, analyte, cas, domain, units, typical_conc_ug_l) %>%
  cross_join(tibble(perspective = perspectives)) %>%
  left_join(domain_coverage, by = "domain") %>%
  rowwise() %>%
  mutate(
    # Draw which tier this chemical gets for this perspective
    tier_draw = {
      probs <- c(tier1_prob, tier2_prob, tier3_prob, tier4_prob, tier5_prob)
      # Adjust by perspective: eco perspectives have fewer regulatory benchmarks
      if (perspective == "aquatic_eco") {
        probs[1] <- probs[1] * 0.5   # fewer MCLs for aquatic
        probs[3] <- probs[3] * 2.5   # more ECOTOX data
      }
      if (perspective == "terrestrial_eco") {
        probs[1] <- probs[1] * 0.3
        probs[3] <- probs[3] * 2.0
      }
      # Remaining probability = tier 6 (no benchmark)
      prob_none <- max(0, 1 - sum(probs))
      probs <- c(probs, prob_none)
      probs <- probs / sum(probs)  # renormalize
      sample(1:6, 1, prob = probs)
    }
  ) %>%
  ungroup() %>%
  mutate(
    benchmark_tier = tier_draw,

    # Generate synthetic benchmark values
    # Tier 1-2: benchmark ~ 0.5-5x the typical concentration (regulatory)
    # Tier 3-4: benchmark ~ 0.3-10x (more variance, less precision)
    # Tier 5: benchmark ~ 0.1-20x (screening, wide range)
    benchmark_value = case_when(
      benchmark_tier == 1 ~ typical_conc_ug_l * exp(rnorm(n(), 0.5, 0.3)),
      benchmark_tier == 2 ~ typical_conc_ug_l * exp(rnorm(n(), 0.3, 0.5)),
      benchmark_tier == 3 ~ typical_conc_ug_l * exp(rnorm(n(), 0.0, 0.8)),
      benchmark_tier == 4 ~ typical_conc_ug_l * exp(rnorm(n(), 0.0, 1.0)),
      benchmark_tier == 5 ~ typical_conc_ug_l * exp(rnorm(n(), 0.0, 1.2)),
      benchmark_tier == 6 ~ NA_real_
    ),

    # Confidence weight: higher tier = higher confidence
    # Within ML tier, simulate variable CI widths
    confidence_weight = case_when(
      benchmark_tier == 1 ~ runif(n(), 0.90, 1.00),
      benchmark_tier == 2 ~ runif(n(), 0.75, 0.90),
      benchmark_tier == 3 ~ runif(n(), 0.55, 0.75),
      benchmark_tier == 4 ~ runif(n(), 0.35, 0.60),
      benchmark_tier == 5 ~ runif(n(), 0.20, 0.40),
      benchmark_tier == 6 ~ 0
    ),

    benchmark_source = case_when(
      benchmark_tier == 1 ~ sample(c("MCL", "PHG", "HAL", "MCLG"),
                                    n(), replace = TRUE),
      benchmark_tier == 2 ~ sample(c("RfD", "CTV_DCAP", "RSL"),
                                    n(), replace = TRUE),
      benchmark_tier == 3 ~ sample(c("ECOTOX_LC50", "ECOTOX_NOEC", "eco_tbl_bin"),
                                    n(), replace = TRUE),
      benchmark_tier == 4 ~ sample(c("vonBorries_POD", "chemi_hazard_num", "QSAR_TEST"),
                                    n(), replace = TRUE),
      benchmark_tier == 5 ~ sample(c("GHS_Hcode_midpoint", "screening_level"),
                                    n(), replace = TRUE),
      benchmark_tier == 6 ~ "none"
    ),

    authority_label = case_when(
      benchmark_tier == 1 ~ "Regulatory",
      benchmark_tier == 2 ~ "Risk-based",
      benchmark_tier == 3 ~ "Hazard-derived",
      benchmark_tier == 4 ~ "ML-predicted",
      benchmark_tier == 5 ~ "Screening",
      benchmark_tier == 6 ~ "None"
    )
  ) %>%
  select(
    analyte_id, analyte, cas, domain, perspective,
    benchmark_tier, benchmark_value, benchmark_source,
    authority_label, confidence_weight
  )

# --- Summary -----------------------------------------------------------------

cat("Benchmark coverage by perspective and tier:\n\n")
benchmarks %>%
  count(perspective, authority_label) %>%
  pivot_wider(names_from = authority_label, values_from = n, values_fill = 0) %>%
  print()

cat("\nBenchmark coverage by domain (human_health perspective):\n\n")
benchmarks %>%
  filter(perspective == "human_health") %>%
  count(domain, authority_label) %>%
  pivot_wider(names_from = authority_label, values_from = n, values_fill = 0) %>%
  print()

# --- Write -------------------------------------------------------------------

write_csv(benchmarks, file.path(data_dir, "benchmarks.csv"))
cat("\nBenchmarks written to:", file.path(data_dir, "benchmarks.csv"), "\n")
