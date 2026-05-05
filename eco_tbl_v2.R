#!/usr/bin/env Rscript
# ==============================================================================
# ECOTOX Risk Binning Pipeline — v2 (refactored)
# ==============================================================================
#
# Produces per-compound ecotoxicity hazard bins across species groups and
# exposure durations (acute/chronic) for integration into the hierarchical
# site scoring framework.
#
# Key improvements over v1:
#   - Binning thresholds extracted to a citable lookup table (eco_bins)
#   - Gap-free binning via upper_bound approach with Inf catch-all
#   - Chronic thresholds derived from acute using published ACR values
#   - Endpoint cleaning via regex instead of 13+ case_when branches
#   - Lifestage mapping via lookup tibble with explicit priority ordering
#   - Diagnostic pass to quantify data loss at each filtering stage
#   - super_bin carries both mean and max aggregation
#
# Data sources for thresholds:
#   - EPA Appendix I ecotoxicity categories (birds, fish, mammals, bees)
#   - PPDB/BPDB v.March 2026, Section 5.2 Ecotoxicology (Univ. Hertfordshire)
#   - GHS Rev.7, Annex 9 (aquatic hazard classification)
#
# Chronic threshold derivation:
#   Using default ACR = 10 supported by:
#   - Kenaga (1982) Environ. Toxicol. Chem. 1(1): avg ACR=12, 93% ≤25
#   - Lange et al. (1998) Chemosphere 36(1): median ACR 10.5/7.0/5.4 (fish/daph/algae)
#   - ECETOC TR 91 (2003): >50% ACRs <10; 90th pctile=24.5 for organics
#   - Ahlers et al. (2006) Environ. Toxicol. Chem. 25(11): median 10.5/7.0/5.4
#   - Raimondo et al. (2007) Environ. Toxicol. Chem. 26(11): overall median=8.3
#   - Kienzler et al. (2016) Environ. Sci. Pollut. Res. 23: median 12.0/8.8
#
# Requires: dplyr, tidyr, readr, stringr, tibble, DBI, duckdb
# Requires: ComptoxR (for ct_list, ct_details, ct_search)
# Assumes: ECOTOX DuckDB at "ecotox.duckdb" with tables:
#          tests, species, results, app_exposure_types, lifestage_codes
# ==============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)
# library(DBI)     # uncomment when connecting to ECOTOX DuckDB
# library(duckdb)  # uncomment when connecting to ECOTOX DuckDB
# library(ComptoxR)  # uncomment when running with real data

# =============================================================================
# SECTION 1: BINNING THRESHOLDS LOOKUP TABLE
# =============================================================================
# Every threshold is traceable to a source. Chronic thresholds derived from
# acute via ACR are tagged with the ACR value used.
#
# Bins: VH (very high hazard) → H → M → L → VL (very low hazard)
# For dose-based endpoints (LD50, LC50): LOWER value = MORE toxic = HIGHER bin
# upper_bound is the MAXIMUM value that falls into this bin.
# Inf = catch-all for the lowest hazard tier.

eco_bins <- tribble(
  ~eco_group,      ~test_type, ~upper_bound, ~bin,  ~source,                              ~notes,

  # ═══════════════════════════════════════════════════════════════════════════
  # FISH — Acute (96hr LC50, mg/L)
  # Source: EPA AppI (5-tier) subdividing PPDB (3-tier)
  # PPDB 5.2: <0.1=High, 0.1-100=Moderate, >100=Low
  # EPA AppI: <0.1/0.1-1/1-10/10-100/>100
  # GHS Annex 9: <1=Acute1, 1-10=Acute2, 10-100=Acute3
  # ═══════════════════════════════════════════════════════════════════════════
  "Fish",          "acute",     0.1,          "VH",  "EPA_AppI + PPDB_High",               "Very highly toxic",
  "Fish",          "acute",     1,            "H",   "EPA_AppI + GHS_Acute1",              "Highly toxic",
  "Fish",          "acute",     10,           "M",   "EPA_AppI + GHS_Acute2",              "Moderately toxic",
  "Fish",          "acute",     100,          "L",   "EPA_AppI + GHS_Acute3",              "Slightly toxic",
  "Fish",          "acute",     Inf,          "VL",  "EPA_AppI + PPDB_Low",                "Practically nontoxic",

  # FISH — Chronic (21d NOEC, mg/L)
  # PPDB 5.2: <0.01=High, 0.01-10=Moderate, >10=Low
  # Subdivided using ACR=10 (Kienzler 2016 median=12; Lange 1998 median=10.5)
  "Fish",          "chronic",   0.01,         "VH",  "PPDB_High",                          "Chronic VH = acute VH / ACR10",
  "Fish",          "chronic",   0.1,          "H",   "ACR10 from EPA_Highly",              "0.01-0.1; derived",
  "Fish",          "chronic",   1,            "M",   "ACR10 from EPA_Moderately",          "0.1-1; derived",
  "Fish",          "chronic",   10,           "L",   "PPDB_Moderate_upper",                "1-10; PPDB boundary",
  "Fish",          "chronic",   Inf,          "VL",  "PPDB_Low",                           ">10",

  # ═══════════════════════════════════════════════════════════════════════════
  # CRUSTACEANS / AQUATIC INVERTEBRATES — Acute (48hr EC50, mg/L)
  # PPDB 5.2: Same thresholds as fish acute
  # ═══════════════════════════════════════════════════════════════════════════
  "Crustaceans",   "acute",     0.1,          "VH",  "PPDB_High",                          "Same as fish acute",
  "Crustaceans",   "acute",     1,            "H",   "EPA_analog + GHS_Acute1",            "",
  "Crustaceans",   "acute",     10,           "M",   "EPA_analog + GHS_Acute2",            "",
  "Crustaceans",   "acute",     100,          "L",   "EPA_analog + GHS_Acute3",            "",
  "Crustaceans",   "acute",     Inf,          "VL",  "PPDB_Low",                           "",

  # CRUSTACEANS — Chronic (21d NOEC, mg/L)
  # PPDB 5.2: <0.01=High, 0.01-10=Moderate, >10=Low
  # Subdivided using ACR=9 (Raimondo 2007 median=8.3; Kienzler 2016 median=8.8)
  "Crustaceans",   "chronic",   0.01,         "VH",  "PPDB_High",                          "Chronic boundary from PPDB",
  "Crustaceans",   "chronic",   0.1,          "H",   "ACR9 from acute_H",                  "0.01-0.1; derived via ACR~9",
  "Crustaceans",   "chronic",   1,            "M",   "ACR9 from acute_M",                  "0.1-1; derived",
  "Crustaceans",   "chronic",   10,           "L",   "PPDB_Moderate_upper",                "1-10",
  "Crustaceans",   "chronic",   Inf,          "VL",  "PPDB_Low",                           ">10",

  # ═══════════════════════════════════════════════════════════════════════════
  # GENERAL AQUATIC INVERTEBRATES (non-crustacean)
  # PPDB uses same thresholds as crustaceans for aquatic inverts
  # ═══════════════════════════════════════════════════════════════════════════
  "Invertebrates", "acute",     0.1,          "VH",  "PPDB_aquatic_invert",                "Analog to crustacean",
  "Invertebrates", "acute",     1,            "H",   "PPDB_aquatic_invert",                "",
  "Invertebrates", "acute",     10,           "M",   "PPDB_aquatic_invert",                "",
  "Invertebrates", "acute",     100,          "L",   "PPDB_aquatic_invert",                "",
  "Invertebrates", "acute",     Inf,          "VL",  "PPDB_Low",                           "",

  "Invertebrates", "chronic",   0.01,         "VH",  "PPDB_High",                          "",
  "Invertebrates", "chronic",   0.1,          "H",   "ACR10 from acute",                   "",
  "Invertebrates", "chronic",   1,            "M",   "ACR10 from acute",                   "",
  "Invertebrates", "chronic",   10,           "L",   "PPDB_Moderate_upper",                "",
  "Invertebrates", "chronic",   Inf,          "VL",  "PPDB_Low",                           "",

  # ═══════════════════════════════════════════════════════════════════════════
  # MOLLUSCS — Use aquatic invertebrate thresholds
  # PPDB 5.2 lists marine bivalves as "No interpretation" (note 11)
  # Using invertebrate analogs as best available; document as opinionated
  # ═══════════════════════════════════════════════════════════════════════════
  "Molluscs",      "acute",     0.1,          "VH",  "analog_aquatic_invert",              "PPDB has no mollusc bins; analog used",
  "Molluscs",      "acute",     1,            "H",   "analog_aquatic_invert",              "",
  "Molluscs",      "acute",     10,           "M",   "analog_aquatic_invert",              "",
  "Molluscs",      "acute",     100,          "L",   "analog_aquatic_invert",              "",
  "Molluscs",      "acute",     Inf,          "VL",  "analog_aquatic_invert",              "",

  "Molluscs",      "chronic",   0.01,         "VH",  "analog_aquatic_invert",              "",
  "Molluscs",      "chronic",   0.1,          "H",   "analog_aquatic_invert",              "",
  "Molluscs",      "chronic",   1,            "M",   "analog_aquatic_invert",              "",
  "Molluscs",      "chronic",   10,           "L",   "analog_aquatic_invert",              "",
  "Molluscs",      "chronic",   Inf,          "VL",  "analog_aquatic_invert",              "",

  # ═══════════════════════════════════════════════════════════════════════════
  # WORMS (Earthworms) — PPDB 5.2 terrestrial section
  # Acute: 14d LC50 (mg/kg soil): <10=High, 10-1000=Moderate, >1000=Low
  # Chronic: NOEC reproduction (mg/kg): <0.1=High, 0.1-100=Moderate, >100=Low
  # ═══════════════════════════════════════════════════════════════════════════
  "Worms",         "acute",     10,           "VH",  "PPDB_earthworm_High",                "<10 mg/kg soil",
  "Worms",         "acute",     100,          "H",   "PPDB_earthworm_subdiv",              "Subdivide PPDB Moderate",
  "Worms",         "acute",     1000,         "M",   "PPDB_earthworm_Moderate_upper",      "",
  "Worms",         "acute",     Inf,          "L",   "PPDB_earthworm_Low",                 ">1000",

  "Worms",         "chronic",   0.1,          "VH",  "PPDB_earthworm_chr_High",            "<0.1 mg/kg",
  "Worms",         "chronic",   1,            "H",   "PPDB_earthworm_chr_subdiv",          "Subdivide PPDB Moderate",
  "Worms",         "chronic",   10,           "M",   "PPDB_earthworm_chr_subdiv",          "",
  "Worms",         "chronic",   100,          "L",   "PPDB_earthworm_chr_Moderate_upper",  "",
  "Worms",         "chronic",   Inf,          "VL",  "PPDB_earthworm_chr_Low",             ">100",

  # ═══════════════════════════════════════════════════════════════════════════
  # ALGAE / FUNGI / MOSS (aquatic primary producers)
  # PPDB 5.2 + Note 6: TER ratios 1/10th of fish/daphnids
  # Acute EC50 (mg/L): <0.01=High, 0.01-10=Moderate, >10=Low
  # Chronic NOEC (mg/L): <0.001=High, 0.001-1=Moderate, >1=Low
  # ═══════════════════════════════════════════════════════════════════════════
  "Algae",         "acute",     0.01,         "VH",  "PPDB_algae_High",                    "Note 6: 1/10th fish",
  "Algae",         "acute",     0.1,          "H",   "PPDB_algae_subdiv",                  "",
  "Algae",         "acute",     1,            "M",   "PPDB_algae_subdiv",                  "",
  "Algae",         "acute",     10,           "L",   "PPDB_algae_Moderate_upper",          "",
  "Algae",         "acute",     Inf,          "VL",  "PPDB_algae_Low",                     "",

  "Algae",         "chronic",   0.001,        "VH",  "PPDB_algae_chr_High",                "PPDB boundary",
  "Algae",         "chronic",   0.01,         "H",   "PPDB_algae_chr_subdiv",              "Subdivide PPDB Moderate",
  "Algae",         "chronic",   0.1,          "M",   "PPDB_algae_chr_subdiv",              "",
  "Algae",         "chronic",   1,            "L",   "PPDB_algae_chr_Moderate_upper",      "",
  "Algae",         "chronic",   Inf,          "VL",  "PPDB_algae_chr_Low",                 "",

  # Apply same bins to Fungi and Moss (PPDB groups them with algae for note 6)
  "Fungi",         "acute",     0.01,         "VH",  "analog_algae_PPDB_note6",            "",
  "Fungi",         "acute",     0.1,          "H",   "analog_algae",                       "",
  "Fungi",         "acute",     1,            "M",   "analog_algae",                       "",
  "Fungi",         "acute",     10,           "L",   "analog_algae",                       "",
  "Fungi",         "acute",     Inf,          "VL",  "analog_algae",                       "",

  "Moss, Hornworts","acute",    0.01,         "VH",  "analog_algae_PPDB_note6",            "",
  "Moss, Hornworts","acute",    0.1,          "H",   "analog_algae",                       "",
  "Moss, Hornworts","acute",    1,            "M",   "analog_algae",                       "",
  "Moss, Hornworts","acute",    10,           "L",   "analog_algae",                       "",
  "Moss, Hornworts","acute",    Inf,          "VL",  "analog_algae",                       "",

  # ═══════════════════════════════════════════════════════════════════════════
  # FLOWERS, TREES, SHRUBS, FERNS
  # PPDB 5.2: Aquatic plants same as algae; terrestrial = "No interpretation"
  # Using aquatic plant thresholds as best available
  # ═══════════════════════════════════════════════════════════════════════════
  "Flowers, Trees, Shrubs, Ferns", "acute",  0.01,  "VH",  "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "acute",  0.1,   "H",   "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "acute",  1,     "M",   "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "acute",  10,    "L",   "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "acute",  Inf,   "VL",  "PPDB_aquatic_plant_analog",  "",

  "Flowers, Trees, Shrubs, Ferns", "chronic", 0.001, "VH", "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "chronic", 0.01,  "H",  "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "chronic", 0.1,   "M",  "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "chronic", 1,     "L",  "PPDB_aquatic_plant_analog",  "",
  "Flowers, Trees, Shrubs, Ferns", "chronic", Inf,   "VL", "PPDB_aquatic_plant_analog",  "",

  # ═══════════════════════════════════════════════════════════════════════════
  # BIRDS — Acute (oral LD50, mg/kg-bw)
  # EPA AppI: <10/10-50/51-500/501-2000/>2000
  # PPDB 5.2: <100=High, 100-2000=Moderate, >2000=Low (less granular)
  # Using EPA 5-tier as primary
  # ═══════════════════════════════════════════════════════════════════════════
  "Birds",         "acute",     10,           "VH",  "EPA_AppI_VeryHighly",                "LD50 mg/kg-bw",
  "Birds",         "acute",     50,           "H",   "EPA_AppI_Highly",                    "",
  "Birds",         "acute",     500,          "M",   "EPA_AppI_Moderately",                "",
  "Birds",         "acute",     2000,         "L",   "EPA_AppI_Slightly",                  "",
  "Birds",         "acute",     Inf,          "VL",  "EPA_AppI_Practically",               "",

  # BIRDS — Chronic (mg/kg/d)
  # PPDB 5.2: <10=High, 10-200=Moderate, >200=Low
  "Birds",         "chronic",   10,           "VH",  "PPDB_birds_chr_High",                "mg/kg/d",
  "Birds",         "chronic",   50,           "H",   "PPDB_birds_chr_subdiv",              "Subdivide Moderate",
  "Birds",         "chronic",   200,          "M",   "PPDB_birds_chr_Moderate_upper",      "",
  "Birds",         "chronic",   Inf,          "L",   "PPDB_birds_chr_Low",                 "",

  # ═══════════════════════════════════════════════════════════════════════════
  # AMPHIBIANS / REPTILES
  # No dedicated bins in EPA or PPDB. EPA groups amphibians with birds for
  # terrestrial phase and with fish for aquatic phase.
  # Using bird thresholds for terrestrial exposure per EPA convention.
  # Document this analog explicitly.
  # ═══════════════════════════════════════════════════════════════════════════
  "Amphibians",    "acute",     10,           "VH",  "EPA_analog_birds_terrestrial",       "Per EPA convention",
  "Amphibians",    "acute",     50,           "H",   "EPA_analog_birds",                   "",
  "Amphibians",    "acute",     500,          "M",   "EPA_analog_birds",                   "",
  "Amphibians",    "acute",     2000,         "L",   "EPA_analog_birds",                   "",
  "Amphibians",    "acute",     Inf,          "VL",  "EPA_analog_birds",                   "",

  "Amphibians",    "chronic",   10,           "VH",  "EPA_analog_birds_chr",               "",
  "Amphibians",    "chronic",   50,           "H",   "EPA_analog_birds_chr",               "",
  "Amphibians",    "chronic",   200,          "M",   "EPA_analog_birds_chr",               "",
  "Amphibians",    "chronic",   Inf,          "L",   "EPA_analog_birds_chr",               "",

  "Reptiles",      "acute",     10,           "VH",  "EPA_analog_birds_terrestrial",       "",
  "Reptiles",      "acute",     50,           "H",   "EPA_analog_birds",                   "",
  "Reptiles",      "acute",     500,          "M",   "EPA_analog_birds",                   "",
  "Reptiles",      "acute",     2000,         "L",   "EPA_analog_birds",                   "",
  "Reptiles",      "acute",     Inf,          "VL",  "EPA_analog_birds",                   "",

  "Reptiles",      "chronic",   10,           "VH",  "EPA_analog_birds_chr",               "",
  "Reptiles",      "chronic",   50,           "H",   "EPA_analog_birds_chr",               "",
  "Reptiles",      "chronic",   200,          "M",   "EPA_analog_birds_chr",               "",
  "Reptiles",      "chronic",   Inf,          "L",   "EPA_analog_birds_chr",               "",

  # ═══════════════════════════════════════════════════════════════════════════
  # MAMMALS — Acute (oral LD50, mg/kg-bw)
  # GHS Rev.7: <5/5-50/50-300/300-2000/>2000 (Cat 1-5)
  # PPDB 5.2: <100=High, 100-2000=Moderate, >2000=Low
  # EPA AppI: Uses same 5-tier as birds but different cutpoints
  # Using GHS as primary (finer resolution at low end)
  # ═══════════════════════════════════════════════════════════════════════════
  "Mammals",       "acute",     5,            "XH",  "GHS_Cat1_Fatal",                     "mg/kg-bw",
  "Mammals",       "acute",     50,           "VH",  "GHS_Cat2_Fatal",                     "",
  "Mammals",       "acute",     300,          "H",   "GHS_Cat3_Toxic",                     "",
  "Mammals",       "acute",     2000,         "M",   "GHS_Cat4_Harmful + PPDB_Moderate",   "",
  "Mammals",       "acute",     Inf,          "L",   "PPDB_Low",                           "",

  # MAMMALS — Chronic (mg/kg/d)
  # PPDB 5.2: <1=High, 1-100=Moderate, >100=Low
  "Mammals",       "chronic",   1,            "VH",  "PPDB_mamm_chr_High",                 "mg/kg/d",
  "Mammals",       "chronic",   10,           "H",   "PPDB_mamm_chr_subdiv",               "Subdivide Moderate",
  "Mammals",       "chronic",   100,          "M",   "PPDB_mamm_chr_Moderate_upper",       "",
  "Mammals",       "chronic",   Inf,          "L",   "PPDB_mamm_chr_Low",                  "",

  # ═══════════════════════════════════════════════════════════════════════════
  # BEES — Acute (LD50, µg/bee)
  # EPA: <2=Highly, 2-11=Moderately, >11=Practically nontoxic
  # PPDB 5.2: <1=High, 1-100=Moderate, >100=Low
  # Hybrid: use PPDB VH cutoff (<1) + EPA H cutoff (2) for finer resolution
  # ═══════════════════════════════════════════════════════════════════════════
  "Bees",          "acute",     1,            "VH",  "PPDB_High",                          "µg/bee",
  "Bees",          "acute",     2,            "H",   "EPA_AppI_Highly",                    "EPA boundary",
  "Bees",          "acute",     11,           "M",   "EPA_AppI_Moderately",                "EPA boundary",
  "Bees",          "acute",     100,          "L",   "PPDB_Moderate_upper",                "",
  "Bees",          "acute",     Inf,          "VL",  "PPDB_Low",                           "",

  # ═══════════════════════════════════════════════════════════════════════════
  # INSECTS/SPIDERS (non-bee terrestrial arthropods)
  # PPDB 5.2: Parasitic wasps & predatory mites have LR50 bins
  # Others (note 11): "No interpretation"
  # Using bee thresholds as analog for contact LD50
  # ═══════════════════════════════════════════════════════════════════════════
  "Insects/Spiders","acute",    1,            "VH",  "analog_bees",                        "µg/organism; analog",
  "Insects/Spiders","acute",    2,            "H",   "analog_bees",                        "",
  "Insects/Spiders","acute",    11,           "M",   "analog_bees",                        "",
  "Insects/Spiders","acute",    100,          "L",   "analog_bees",                        "",
  "Insects/Spiders","acute",    Inf,          "VL",  "analog_bees",                        ""
)


# =============================================================================
# SECTION 2: BINNING FUNCTION (gap-free)
# =============================================================================

#' Assign ecotoxicity hazard bin based on lookup table
#'
#' For each row, finds the tightest (smallest upper_bound) bin that the
#' value fits into. The Inf final tier guarantees no value falls through.
#'
#' @param data Data frame with eco_group, test_type, and a value column
#' @param value_col Name of the column containing the toxicity value
#' @param bin_table The eco_bins lookup table
#' @return Input data with `bin` and `bin_source` columns added
assign_eco_bin <- function(data, value_col = "new_value",
                           bin_table = eco_bins) {

  # Validate: check for gaps in bin table
  gap_check <- bin_table %>%
    group_by(eco_group, test_type) %>%
    arrange(upper_bound, .by_group = TRUE) %>%
    mutate(
      prev_bound = lag(upper_bound, default = 0),
      has_gap = prev_bound > 0 & (upper_bound / prev_bound) > 100
    ) %>%
    filter(has_gap)

  if (nrow(gap_check) > 0) {
    warning("Potential gaps detected in bin table for: ",
            paste(unique(gap_check$eco_group), collapse = ", "))
  }

  # Perform binning via non-equi join logic
  data %>%
    # Ensure the join columns exist
    inner_join(
      bin_table %>%
        select(eco_group, test_type, upper_bound, bin, source),
      by = c("eco_group", "test_type"),
      relationship = "many-to-many"
    ) %>%
    # Keep only bins where value <= upper_bound
    filter(.data[[value_col]] <= upper_bound) %>%
    # Take the tightest (smallest upper_bound) match
    group_by(across(-c(upper_bound, bin, source))) %>%
    slice_min(upper_bound, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    rename(bin_source = source) %>%
    select(-upper_bound)
}


# =============================================================================
# SECTION 3: NUMERIC BIN SCORES (for ToxPi integration)
# =============================================================================

#' Convert letter bins to integer scores
#' @param bin_col Character vector of bins
#' @return Integer vector
bin_to_int <- function(bin_col) {
  case_when(
    bin_col == "XH" ~ 6L,
    bin_col == "VH" ~ 5L,
    bin_col == "H"  ~ 4L,
    bin_col == "M"  ~ 3L,
    bin_col == "L"  ~ 2L,
    bin_col == "VL" ~ 1L,
    TRUE            ~ NA_integer_
  )
}

#' Convert integer scores back to letter bins
#' @param int_col Integer vector
#' @return Character vector
int_to_bin <- function(int_col) {
  case_when(
    int_col >= 6L ~ "XH",
    int_col == 5L ~ "VH",
    int_col == 4L ~ "H",
    int_col == 3L ~ "M",
    int_col == 2L ~ "L",
    int_col == 1L ~ "VL",
    int_col == 0L ~ "ND",
    TRUE          ~ "ND"
  )
}


# =============================================================================
# SECTION 4: ENDPOINT CLEANING (regex-based)
# =============================================================================

#' Clean endpoint strings from ECOTOX
#' Strips trailing qualifiers (*, /, */) and normalizes
#' @param endpoint_col Character vector of raw endpoints
#' @return Cleaned character vector
clean_endpoints <- function(endpoint_col) {
  endpoint_col %>%
    str_remove("[*/]+$") %>%  # EC50*/ → EC50, LC50* → LC50, etc.
    str_remove("R$")          # LOELR → LOEL, NOELR → NOEL
}

#' Simplify effect codes
#' @param effect_col Character vector of raw effect codes
#' @return Simplified character vector
clean_effects <- function(effect_col) {
  case_when(
    str_detect(effect_col, "MOR") ~ "MOR",
    str_detect(effect_col, "DVP|GRO|MPH") ~ "DVP_GRO_MPH",
    TRUE ~ effect_col
  )
}


# =============================================================================
# SECTION 5: LIFESTAGE LOOKUP TABLE
# =============================================================================
# Priority column controls match order: lower number = matched first.
# This avoids the order-sensitivity bugs in the v1 case_when chain.

lifestage_lookup <- tribble(
  ~pattern,                                   ~life_stage,          ~priority,
  # Exact or near-exact matches first (priority 1)
  "^unspecified$",                            "Other/Unknown",       1,
  "^not reported$",                           "Other/Unknown",       1,
  "^adult$",                                  "Adult",               1,
  "^egg$",                                    "Egg/Embryo",          1,
  "^embryo",                                  "Egg/Embryo",          1,
  "^blastula$",                               "Egg/Embryo",          1,
  "^gastrula$",                               "Egg/Embryo",          1,
  "^morula$",                                 "Egg/Embryo",          1,
  "^zygote$",                                 "Egg/Embryo",          1,
  "^zygospore$",                              "Egg/Embryo",          1,
  "^oocyte",                                  "Egg/Embryo",          1,
  "^cleavage stage$",                         "Egg/Embryo",          1,
  "^eyed egg",                                "Egg/Embryo",          1,
  "^mid-neurula$",                            "Egg/Embryo",          1,
  "^neurala$",                                "Egg/Embryo",          1,

  # Larval/juvenile stages (priority 2)
  "^larva-pupa$",                             "Larva/Juvenile",      2,
  "^prolarva$",                               "Larva/Juvenile",      2,
  "^protolarvae$",                            "Larva/Juvenile",      2,
  "^larva",                                   "Larva/Juvenile",      3,
  "^juvenile$",                               "Larva/Juvenile",      2,
  "^fry$",                                    "Larva/Juvenile",      2,
  "^sac fry",                                 "Larva/Juvenile",      2,
  "^yolk sac",                                "Larva/Juvenile",      2,
  "^fingerling$",                             "Larva/Juvenile",      2,
  "^alevin$",                                 "Larva/Juvenile",      2,
  "^elver$",                                  "Larva/Juvenile",      2,
  "^parr$",                                   "Larva/Juvenile",      2,
  "^smolt$",                                  "Larva/Juvenile",      2,
  "^swim-up$",                                "Larva/Juvenile",      2,
  "^froglet$",                                "Larva/Juvenile",      2,
  "^tadpole$",                                "Larva/Juvenile",      2,
  "^neonate$",                                "Larva/Juvenile",      2,
  "^newborn$",                                "Larva/Juvenile",      2,
  "^nauplii$",                                "Larva/Juvenile",      2,
  "^nymph$",                                  "Larva/Juvenile",      2,
  "^copepodid",                               "Larva/Juvenile",      2,
  "^instar",                                  "Larva/Juvenile",      2,
  "^mysis$",                                  "Larva/Juvenile",      2,
  "^zoea$",                                   "Larva/Juvenile",      2,
  "^megalopa$",                               "Larva/Juvenile",      2,
  "^glochidia$",                              "Larva/Juvenile",      2,
  "^veliger$",                                "Larva/Juvenile",      2,
  "^protozoea$",                              "Larva/Juvenile",      2,
  "^seedling$",                               "Larva/Juvenile",      2,
  "^sporeling$",                              "Larva/Juvenile",      2,
  "^weanling$",                               "Larva/Juvenile",      2,
  "^yearling$",                               "Larva/Juvenile",      2,
  "^underyearling$",                          "Larva/Juvenile",      2,
  "^pullet$",                                 "Larva/Juvenile",      2,
  "^prepupal$",                               "Larva/Juvenile",      2,
  "^pupa$",                                   "Larva/Juvenile",      2,
  "^new, newly or recent hatch",              "Larva/Juvenile",      2,
  "^post-larva$",                             "Larva/Juvenile",      2,
  "^pre-larva$",                              "Larva/Juvenile",      2,
  "^post-smolt$",                             "Larva/Juvenile",      2,
  "^pre-smolt$",                              "Larva/Juvenile",      2,
  "young",                                    "Larva/Juvenile",      4,

  # Subadult (priority 3)
  "^immature$",                               "Subadult/Immature",   3,
  "^sexually immature$",                      "Subadult/Immature",   3,
  "^subadult$",                               "Subadult/Immature",   3,
  "^pre-.*adult",                             "Subadult/Immature",   3,
  "^young adult$",                            "Subadult/Immature",   3,

  # Mature/adult — specific variants first, then general
  "^mature dormant$",                         "Dormant/Senescent",   2,
  "^mature reproductive$",                    "Reproductive",        2,
  "^mature vegetative$",                      "Other/Unknown",       2,
  "^mature.*post-bloom",                      "Adult",               2,
  "^mature.*pit-hardening",                   "Adult",               2,
  "^mature.*side-green",                      "Adult",               2,
  "^mature.*full-bloom",                      "Adult",               2,
  "^sexually mature$",                        "Adult",               2,
  "^mature$",                                 "Adult",               3,
  "^imago$",                                  "Adult",               2,
  "^cocoon$",                                 "Adult",               2,
  "^post-emergence$",                         "Adult",               2,

  # Reproductive stages
  "^f[0-9]+ generation",                      "Reproductive",        2,
  "^spawning$",                               "Reproductive",        2,
  "^pre-spawning$",                           "Reproductive",        2,
  "^post-spawning$",                          "Reproductive",        2,
  "^gestation$",                              "Reproductive",        2,
  "^lactational$",                            "Reproductive",        2,
  "^postpartum$",                             "Reproductive",        2,
  "^egg laying$",                             "Reproductive",        2,
  "^flower",                                  "Reproductive",        2,
  "^gamete$",                                 "Reproductive",        2,
  "^sperm$",                                  "Reproductive",        2,
  "^pollen",                                  "Reproductive",        2,
  "gametophyte",                              "Reproductive",        2,
  "^prebloom$",                               "Reproductive",        2,

  # Dormant
  "^cyst$",                                   "Dormant/Senescent",   2,
  "^senescence$",                             "Dormant/Senescent",   2,
  "^stationary growth",                       "Dormant/Senescent",   2,
  "^germinated seed$",                        "Dormant/Senescent",   2,

  # Plant-specific adult stages
  "^seed$",                                   "Adult",               3,
  "^shoot$",                                  "Adult",               3,
  "^corm$",                                   "Adult",               3,
  "^tuber$",                                  "Adult",               3,
  "^rhizome$",                                "Adult",               3,
  "^rooted cuttings$",                        "Adult",               3,
  "^sapling$",                                "Adult",               3,
  "^spat$",                                   "Adult",               3,
  "^tiller",                                  "Adult",               3,
  "^heading$",                                "Adult",               3,
  "^boot$",                                   "Adult",               3,
  "^jointing$",                               "Adult",               3,
  "^internode",                               "Adult",               3,
  "^grain or seed",                           "Adult",               3,
  "^incipient bud$",                          "Adult",               3,
  "^scape",                                   "Adult",               3,
  "^bud blast",                               "Adult",               3
) %>%
  arrange(priority)

#' Assign life stage from ECOTOX lifestage description
#' @param raw_stage Character vector of raw lifestage descriptions
#' @return Character vector of standardized life stages
assign_lifestage <- function(raw_stage) {
  raw_lower <- tolower(raw_stage)
  result <- rep("Other/Unknown", length(raw_lower))

  for (i in seq_len(nrow(lifestage_lookup))) {
    matches <- str_detect(raw_lower, lifestage_lookup$pattern[i])
    # Only overwrite if not already assigned by a higher-priority rule
    # (but since we process in priority order, first match wins —
    #  we need to track what's been matched)
    unmatched <- result == "Other/Unknown"
    result[matches & unmatched] <- lifestage_lookup$life_stage[i]
  }

  factor(result, levels = c(
    "Egg/Embryo", "Larva/Juvenile", "Subadult/Immature",
    "Adult", "Reproductive", "Dormant/Senescent", "Other/Unknown"
  ))
}


# =============================================================================
# SECTION 6: ECO GROUP CLASSIFICATION
# =============================================================================

#' Assign eco_group from ECOTOX family and ecotox_group fields
#' @param family Character: taxonomic family
#' @param ecotox_group Character: ECOTOX group classification
#' @return Character: standardized eco_group
assign_eco_group <- function(family, ecotox_group) {
  case_when(
    str_detect(family, "Megachilidae|Apidae") ~ "Bees",
    str_detect(ecotox_group, "Insects/Spiders")                ~ "Insects/Spiders",
    str_detect(ecotox_group, "Flowers, Trees, Shrubs, Ferns")  ~ "Flowers, Trees, Shrubs, Ferns",
    str_detect(ecotox_group, "Fungi")                          ~ "Fungi",
    str_detect(ecotox_group, "Algae")                          ~ "Algae",
    str_detect(ecotox_group, "Fish")                           ~ "Fish",
    str_detect(ecotox_group, "Crustaceans")                    ~ "Crustaceans",
    str_detect(ecotox_group, "Molluscs")                       ~ "Molluscs",
    str_detect(ecotox_group, "Invertebrates")                  ~ "Invertebrates",
    str_detect(ecotox_group, "Worms")                          ~ "Worms",
    str_detect(ecotox_group, "Birds")                          ~ "Birds",
    str_detect(ecotox_group, "Mammals")                        ~ "Mammals",
    str_detect(ecotox_group, "Amphibians")                     ~ "Amphibians",
    str_detect(ecotox_group, "Reptiles")                       ~ "Reptiles",
    str_detect(ecotox_group, "Moss, Hornworts")                ~ "Moss, Hornworts",
    TRUE                                                       ~ ecotox_group
  )
}


# =============================================================================
# SECTION 7: SUPER_BIN AGGREGATION
# =============================================================================

#' Aggregate multiple records per compound × eco_group × test_type
#' into a single representative bin.
#'
#' Returns BOTH mean-based (current v1 approach) and max-based aggregation
#' so the downstream consumer can choose.
#'
#' @param binned_data Output of assign_eco_bin()
#' @return Tibble with one row per test_cas × eco_group × test_type
aggregate_to_super_bin <- function(binned_data) {
  binned_data %>%
    mutate(bin_int = bin_to_int(bin)) %>%
    filter(!is.na(bin_int)) %>%
    group_by(test_cas, test_type, eco_group) %>%
    summarise(
      n_records     = n(),
      bin_int_mean  = ceiling(mean(bin_int, na.rm = TRUE)),
      bin_int_max   = max(bin_int, na.rm = TRUE),
      bin_int_min   = min(bin_int, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      # Mean-based (v1 approach): central tendency, then ceiling
      super_bin_mean = int_to_bin(bin_int_mean),
      # Max-based: most protective — one high-toxicity study dominates
      super_bin_max  = int_to_bin(bin_int_max),
      # Spread: if max != min, there's disagreement among studies
      bin_spread     = bin_int_max - bin_int_min
    )
}


# =============================================================================
# SECTION 8: DIAGNOSTIC FUNCTIONS
# =============================================================================

#' Report data loss at each stage of the pipeline
#' @param data Data at current stage
#' @param stage_name Character label for this stage
#' @param group_cols Character vector of columns to group diagnostics by
diagnose_coverage <- function(data, stage_name, group_cols = "eco_group") {
  cat("\n--- Diagnostic:", stage_name, "---\n")
  cat("Total rows:", nrow(data), "\n")

  data %>%
    group_by(across(all_of(group_cols))) %>%
    summarise(n = n(), .groups = "drop") %>%
    arrange(desc(n)) %>%
    print(n = 30)
}

#' Report test_type classification capture rate
#' @param data Data with test_type column (may contain NAs)
diagnose_test_type_capture <- function(data) {
  cat("\n--- Test type classification capture rate ---\n")
  data %>%
    mutate(classified = !is.na(test_type)) %>%
    group_by(eco_group) %>%
    summarise(
      total    = n(),
      captured = sum(classified),
      dropped  = sum(!classified),
      capture_rate = round(captured / total, 3),
      .groups = "drop"
    ) %>%
    arrange(capture_rate) %>%
    print(n = 30)
}

#' Report binning coverage (how many records got a bin vs fell to NA)
#' @param data Data after binning attempt
diagnose_binning <- function(data) {
  cat("\n--- Binning coverage ---\n")
  if ("bin" %in% names(data)) {
    data %>%
      mutate(binned = !is.na(bin)) %>%
      group_by(eco_group, test_type) %>%
      summarise(
        total  = n(),
        binned = sum(binned),
        pct    = round(binned / total * 100, 1),
        .groups = "drop"
      ) %>%
      arrange(pct) %>%
      print(n = 30)
  } else {
    cat("No 'bin' column found — binning may not have run.\n")
  }
}

#' Verify bin table has no gaps (contiguous coverage for each group)
verify_bin_table <- function(bin_table = eco_bins) {
  cat("\n--- Bin table coverage verification ---\n")
  issues <- bin_table %>%
    group_by(eco_group, test_type) %>%
    summarise(
      n_tiers  = n(),
      has_inf  = any(is.infinite(upper_bound)),
      min_bound = min(upper_bound[is.finite(upper_bound)]),
      .groups = "drop"
    ) %>%
    filter(!has_inf)

  if (nrow(issues) > 0) {
    cat("WARNING: Missing Inf catch-all tier for:\n")
    print(issues)
  } else {
    cat("All eco_group × test_type combinations have Inf catch-all. OK.\n")
  }

  # List all covered groups
  bin_table %>%
    distinct(eco_group, test_type) %>%
    arrange(eco_group, test_type) %>%
    print(n = 50)
}

# =============================================================================
# SECTION 9: VALIDATION
# =============================================================================
# Run this when sourcing to confirm the bin table is well-formed

verify_bin_table(eco_bins)
