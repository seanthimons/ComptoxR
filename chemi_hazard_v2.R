#!/usr/bin/env Rscript
# ==============================================================================
# Chemical Hazard Assessment Pipeline — v2 (refactored)
# ==============================================================================
#
# Retrieves and processes chemical hazard data from EPA's HCD API for
# integration into the hierarchical site scoring framework.
#
# Key improvements over v1:
#   - Midpoint lookup table (single source of truth, cited, auditable)
#   - 'I' (insufficient) distinguished from 'ND' (no data) in output
#   - Characterization score: quantifies how well-informed each compound is
#   - Read-across integration point for data-poor compounds
#   - Response caching to avoid re-hitting the API
#   - Inversion logic documented and isolated
#   - Diagnostic pass with coverage reporting
#
# Dependencies: httr, jsonlite, stringr, dplyr, tidyr, purrr, cli
# Optional: ComptoxR (for ct_list, ct_search)
#
# Usage:
#   source("chemi_hazard_v2.R")
#   results <- chemi_hazard(
#     query = c("DTXSID1020560", "DTXSID7020182"),
#     coerce = "numerical",
#     cache_dir = "cache/hcd"
#   )
# ==============================================================================

# =============================================================================
# SECTION 1: MIDPOINT LOOKUP TABLE
# =============================================================================
# Single source of truth for converting categorical hazard bins to numerical
# values. Each row is citable to a GHS category range or expert judgment.
#
# For dose-based endpoints (LD50, LC50, EC50): the midpoint of the GHS
# category range. Lower dose = more toxic = higher hazard.
# These get INVERTED (1/amount) downstream so higher = worse in ToxPi.
#
# For effect-based endpoints (carcinogenicity, genotoxicity, etc.):
# ordinal scores on a log scale where higher = more concern.
#
# The 'invert' column flags which endpoints need 1/x transformation.

hazard_midpoints <- tribble(
  ~endpoint_pattern,              ~score, ~midpoint, ~source,                         ~invert,
  # ═══════════════════════════════════════════════════════════════
  # ACUTE MAMMALIAN — Oral LD50 (mg/kg)
  # GHS Cat 1: ≤5, Cat 2: 5-50, Cat 3: 50-300, Cat 4: 300-2000
  # Midpoints of each range
  # ═══════════════════════════════════════════════════════════════
  "acuteMammalianOral",           "VH",   50,        "GHS_Cat2_midpoint",             TRUE,
  "acuteMammalianOral",           "H",    175,       "GHS_Cat3_midpoint",             TRUE,
  "acuteMammalianOral",           "M",    1150,      "GHS_Cat4_midpoint",             TRUE,
  "acuteMammalianOral",           "L",    2000,      "GHS_Cat5_lower",                TRUE,

  # ACUTE MAMMALIAN — Dermal LD50 (mg/kg)
  # GHS Cat 1: ≤50, Cat 2: 50-200, Cat 3: 200-1000, Cat 4: 1000-2000
  "acuteMammalianDermal",         "VH",   200,       "GHS_Cat2_midpoint",             TRUE,
  "acuteMammalianDermal",         "H",    600,       "GHS_Cat3_midpoint",             TRUE,
  "acuteMammalianDermal",         "M",    1500,      "GHS_Cat4_midpoint",             TRUE,
  "acuteMammalianDermal",         "L",    2000,      "GHS_Cat5_lower",                TRUE,

  # ACUTE MAMMALIAN — Inhalation LC50 (mg/L)
  # GHS Cat 1: ≤0.5, Cat 2: 0.5-2, Cat 3: 2-10, Cat 4: 10-20
  "acuteMammalianInhalation",     "VH",   2,         "GHS_Cat2_midpoint",             TRUE,
  "acuteMammalianInhalation",     "H",    6,         "GHS_Cat3_midpoint",             TRUE,
  "acuteMammalianInhalation",     "M",    15,        "GHS_Cat4_midpoint",             TRUE,
  "acuteMammalianInhalation",     "L",    20,        "GHS_Cat4_upper",                TRUE,

  # ═══════════════════════════════════════════════════════════════
  # CHRONIC/SYSTEMIC ENDPOINTS — Ordinal effect scores
  # Higher number = more concern (no inversion needed)
  # Scale: L=1, M=10, H=100-1000, VH=1000-10000
  # Log-spaced to match the dynamic range of HQ scoring
  # ═══════════════════════════════════════════════════════════════
  "carcinogenicity",              "VH",   10000,     "IARC_Group1_analog",            FALSE,
  "carcinogenicity",              "H",    1000,      "IARC_Group2A_analog",           FALSE,
  "carcinogenicity",              "M",    10,        "IARC_Group2B_analog",           FALSE,
  "carcinogenicity",              "L",    1,         "IARC_Group3_analog",            FALSE,

  "genotoxicity",                 "VH",   1000,      "positive_clastogen",            FALSE,
  "genotoxicity",                 "H",    500,       "positive_mutagen",              FALSE,
  "genotoxicity",                 "L",    1,         "negative",                      FALSE,

  "endocrine",                    "H",    1000,      "positive_ED",                   FALSE,
  "endocrine",                    "L",    1,         "negative",                      FALSE,

  "reproductive",                 "H",    1000,      "positive_repro",                FALSE,
  "reproductive",                 "M",    10,        "suggestive",                    FALSE,
  "reproductive",                 "L",    1,         "negative",                      FALSE,

  "developmental",                "H",    1000,      "positive_dev",                  FALSE,
  "developmental",                "M",    10,        "suggestive",                    FALSE,
  "developmental",                "L",    1,         "negative",                      FALSE,

  "neurotoxicitySingle",          "H",    500,       "positive_neuro",                FALSE,
  "neurotoxicitySingle",          "M",    100,       "suggestive",                    FALSE,

  "neurotoxicityRepeat",          "H",    500,       "positive_neuro_chronic",        FALSE,
  "neurotoxicityRepeat",          "M",    100,       "suggestive",                    FALSE,

  "systemicToxicitySingle",       "H",    500,       "positive_systemic",             FALSE,
  "systemicToxicitySingle",       "M",    100,       "suggestive",                    FALSE,

  "systemicToxicityRepeat",       "H",    500,       "positive_systemic_chronic",     FALSE,
  "systemicToxicityRepeat",       "M",    100,       "suggestive",                    FALSE,

  # ═══════════════════════════════════════════════════════════════
  # IRRITATION / SENSITIZATION — Ordinal
  # ═══════════════════════════════════════════════════════════════
  "skinSensitization",            "H",    100,       "positive_sensitizer",           FALSE,
  "skinSensitization",            "L",    1,         "negative",                      FALSE,

  "skinIrritation",               "VH",   1000,      "corrosive",                     FALSE,
  "skinIrritation",               "H",    100,       "irritant",                      FALSE,
  "skinIrritation",               "M",    10,        "mild_irritant",                 FALSE,
  "skinIrritation",               "L",    1,         "non_irritant",                  FALSE,

  "eyeIrritation",                "VH",   1000,      "serious_damage",                FALSE,
  "eyeIrritation",                "H",    100,       "irritant",                      FALSE,
  "eyeIrritation",                "M",    10,        "mild_irritant",                 FALSE,

  # ═══════════════════════════════════════════════════════════════
  # AQUATIC TOXICITY — EC50/LC50 (mg/L)
  # GHS Acute: Cat 1 ≤1, Cat 2 1-10, Cat 3 10-100
  # GHS Chronic: Cat 1 ≤0.1, Cat 2 0.1-1, Cat 3 1-10
  # Lower value = more toxic → INVERT
  # ═══════════════════════════════════════════════════════════════
  "acuteAquatic",                 "VH",   1,         "GHS_Acute1_midpoint",           TRUE,
  "acuteAquatic",                 "H",    5,         "GHS_Acute2_midpoint",           TRUE,
  "acuteAquatic",                 "M",    50,        "GHS_Acute3_midpoint",           TRUE,
  "acuteAquatic",                 "L",    100,       "GHS_Acute3_upper",              TRUE,

  "chronicAquatic",               "VH",   0.1,       "GHS_Chronic1_midpoint",         TRUE,
  "chronicAquatic",               "H",    0.55,      "GHS_Chronic2_midpoint",         TRUE,
  "chronicAquatic",               "M",    5.5,       "GHS_Chronic3_midpoint",         TRUE,
  "chronicAquatic",               "L",    10,        "GHS_Chronic3_upper",            TRUE,

  # ═══════════════════════════════════════════════════════════════
  # ENVIRONMENTAL FATE
  # ═══════════════════════════════════════════════════════════════
  "persistence",                  "VH",   1000,      "very_persistent",               FALSE,
  "persistence",                  "H",    100,       "persistent",                    FALSE,
  "persistence",                  "M",    10,        "moderate",                      FALSE,
  "persistence",                  "L",    1,         "not_persistent",                FALSE,

  "bioaccumulation",              "H",    1000,      "BCF_high",                      FALSE,
  "bioaccumulation",              "L",    1,         "BCF_low",                       FALSE
)


# =============================================================================
# SECTION 2: HAZARD ENDPOINT METADATA
# =============================================================================
# Canonical ordering and grouping for the 19 HCD endpoints.
# Used for display, pivoting, and perspective filtering.

hazard_endpoints <- tribble(
  ~hazardId,                    ~display_name,                ~group,          ~order,
  "acuteMammalianOral",         "Acute Mamm. Oral",           "human_acute",   1,
  "acuteMammalianDermal",       "Acute Mamm. Dermal",         "human_acute",   2,
  "acuteMammalianInhalation",   "Acute Mamm. Inhalation",     "human_acute",   3,
  "developmental",              "Developmental",              "human_chronic", 4,
  "reproductive",               "Reproductive",               "human_chronic", 5,
  "endocrine",                  "Endocrine Disruption",       "human_chronic", 6,
  "genotoxicity",               "Genotoxicity",               "human_chronic", 7,
  "carcinogenicity",            "Carcinogenicity",            "human_chronic", 8,
  "neurotoxicitySingle",        "Neurotox. (Single)",         "human_chronic", 9,
  "neurotoxicityRepeat",        "Neurotox. (Repeat)",         "human_chronic", 10,
  "systemicToxicitySingle",     "Systemic Tox. (Single)",     "human_chronic", 11,
  "systemicToxicityRepeat",     "Systemic Tox. (Repeat)",     "human_chronic", 12,
  "eyeIrritation",              "Eye Irritation",             "human_local",   13,
  "skinIrritation",             "Skin Irritation",            "human_local",   14,
  "skinSensitization",          "Skin Sensitization",         "human_local",   15,
  "acuteAquatic",               "Acute Aquatic",              "eco_aquatic",   16,
  "chronicAquatic",             "Chronic Aquatic",            "eco_aquatic",   17,
  "persistence",                "Persistence",                "eco_fate",      18,
  "bioaccumulation",            "Bioaccumulation",            "eco_fate",      19
)


# =============================================================================
# SECTION 3: CHARACTERIZATION SCORE
# =============================================================================
# For each compound, compute how well-informed the hazard assessment is.
# This runs PARALLEL to the hazard score and is used in the blind-spots
# analysis.
#
# Dimensions:
#   1. Endpoint coverage: what fraction of the 19 endpoints have data?
#   2. Authority quality: are the scores from Authoritative, Screening, or QSAR?
#   3. Data source diversity: how many independent sources contributed?
#   4. Read-across flag: was the score gap-filled via analogs?
#
# Output: a [0, 1] score where 1 = fully characterized, 0 = total blind spot.

#' Compute characterization score for a set of hazard records
#'
#' @param hazard_data The data$data output from chemi_hazard()
#' @return Tibble with dtxsid and characterization metrics
compute_characterization <- function(hazard_data) {

  n_endpoints <- nrow(hazard_endpoints)

  hazard_data %>%
    group_by(dtxsid) %>%
    summarise(
      # --- Endpoint coverage ---
      n_total_endpoints  = n_endpoints,
      n_with_data        = sum(finalScore != "ND" & !is.na(finalScore)),
      n_insufficient     = sum(finalScore == "I", na.rm = TRUE),
      n_no_data          = sum(finalScore == "ND" | is.na(finalScore)),
      endpoint_coverage  = n_with_data / n_endpoints,

      # --- Authority quality ---
      # Weight: Authoritative=1, Screening=0.7, QSAR=0.4, NA=0
      authority_score = {
        auth_vals <- case_when(
          finalAuthority == "Authoritative" ~ 1.0,
          finalAuthority == "Screening"     ~ 0.7,
          finalAuthority == "QSAR Model"    ~ 0.4,
          TRUE                              ~ 0
        )
        if (any(auth_vals > 0)) mean(auth_vals[auth_vals > 0]) else 0
      },

      # --- Source diversity ---
      n_unique_sources = n_distinct(source[!is.na(source)]),

      # --- Composite characterization score ---
      # Weighted: 50% coverage, 30% authority, 20% diversity (capped)
      characterization = (
        0.50 * endpoint_coverage +
        0.30 * authority_score +
        0.20 * pmin(1, n_unique_sources / 5)
      ),

      .groups = "drop"
    ) %>%
    mutate(
      # Classify into tiers for management communication
      char_tier = case_when(
        characterization >= 0.7  ~ "Well-characterized",
        characterization >= 0.4  ~ "Partially characterized",
        characterization >= 0.15 ~ "Data-poor",
        TRUE                     ~ "Blind spot"
      )
    )
}


# =============================================================================
# SECTION 4: COERCION FUNCTIONS
# =============================================================================
# Each coercion mode is its own function for clarity.

#' Simple coercion: ordinal integer mapping
coerce_simple <- function(data) {
  data %>%
    mutate(
      amount = case_when(
        finalScore == "VH" ~ 5,
        finalScore == "H"  ~ 4,
        finalScore == "M"  ~ 3,
        finalScore == "L"  ~ 2,
        finalScore == "I"  ~ 0.5,  # [CHANGED] I ≠ ND; gets a trace signal
        .default = NA_real_
      )
    ) %>%
    pivot_wider(
      id_cols = dtxsid,
      names_from = hazardId,
      values_from = amount
    )
}

#' Bin coercion: authority-penalized ordinal
coerce_bin <- function(data) {
  data %>%
    mutate(
      auth_val = case_when(
        finalAuthority == "Authoritative" ~ 0,
        finalAuthority == "Screening"     ~ 1 / 3,
        finalAuthority == "QSAR Model"    ~ 2 / 3,
        .default = 0
      ),
      score_val = case_when(
        finalScore == "VH" ~ 5,
        finalScore == "H"  ~ 4,
        finalScore == "M"  ~ 3,
        finalScore == "L"  ~ 2,
        finalScore == "I"  ~ 0.5,
        .default = NA_real_
      ),
      amount = score_val - auth_val
    ) %>%
    pivot_wider(
      id_cols = dtxsid,
      names_from = hazardId,
      values_from = amount
    )
}

#' Numerical coercion: directional value selection + midpoint fallback
#'
#' Logic:
#'   1. For each dtxsid × endpoint, gather all valueMass records
#'   2. Pick the most protective value based on endpoint directionality:
#'      - Inverted endpoints (lower = worse): pick min(valueMass)
#'      - Non-inverted endpoints (higher = worse): pick max(valueMass)
#'   3. If no valueMass exists but a finalScore does: use midpoint lookup
#'   4. Apply inversion (1/x) for dose-response endpoints so higher = worse
#'   5. ND/I records get NA with provenance tracking
#'
#' @param data data$data from chemi_hazard (one row per dtxsid × hazardId,
#'   already trumped by API)
#' @param raw_records The raw API records with valueMass, hazardCode, source, etc.
#'   (multiple rows per dtxsid × hazardId)
coerce_numerical <- function(data, raw_records) {

  # --- Get inversion flags from the midpoint lookup ---
  invert_flags <- hazard_midpoints %>%
    distinct(endpoint_pattern, invert)

  # --- Combine the trumped data with raw records ---
  # data has one row per dtxsid × hazardId (the API's adjudicated score)
  # raw_records has multiple rows per dtxsid × hazardId (the underlying studies)
  temp_df <- left_join(
    data %>% select(data_id, dtxsid, hazardId, finalScore, finalAuthority),
    raw_records,
    by = "data_id"
  ) %>%
    mutate(
      hazardCode = str_replace_all(hazardCode, "-", NA_character_),
      # Exclude T.E.S.T. binary predictions (no meaningful valueMass)
      valueMass = case_when(
        str_detect(source, "T.E.S.T.") &
          str_detect(rationale, "Positive for|Negative for") ~ NA_real_,
        # Exclude cancer slope factor values (different scale)
        str_detect(source, "mid-Atlantic") &
          str_detect(rationale, "SFO") ~ NA_real_,
        .default = valueMass
      )
    ) %>%
    # Attach directionality
    left_join(invert_flags, by = c("hazardId" = "endpoint_pattern"))

  # =================================================================
  # STEP 1: For endpoints WITH valueMass records, pick directionally
  # =================================================================
  value_summary <- temp_df %>%
    filter(!is.na(valueMass), finalScore != "ND", finalScore != "I") %>%
    group_by(dtxsid, hazardId, finalScore, invert) %>%
    summarise(
      n_values      = n(),
      # Directional selection:
      #   invert=TRUE  (lower=worse): pick min → most toxic
      #   invert=FALSE (higher=worse): pick max → most concerning
      value_pick    = if_else(first(invert) == TRUE,
                              min(valueMass, na.rm = TRUE),
                              max(valueMass, na.rm = TRUE)),
      # Carry spread as a confidence metric
      value_min     = min(valueMass, na.rm = TRUE),
      value_max     = max(valueMass, na.rm = TRUE),
      value_spread  = value_max / value_min,
      value_source  = "experimental",
      .groups = "drop"
    )

  # =================================================================
  # STEP 2: For endpoints WITHOUT valueMass, fall back to midpoints
  # =================================================================
  # These are records where the API gave a score (L/M/H/VH) but the
  # underlying records don't carry numerical values (e.g., list-based
  # classifications, H-code only, or categorical predictions)

  endpoints_with_values <- value_summary %>%
    distinct(dtxsid, hazardId)

  midpoint_fallback <- data %>%
    filter(finalScore != "ND", finalScore != "I") %>%
    anti_join(endpoints_with_values, by = c("dtxsid", "hazardId")) %>%
    inner_join(
      hazard_midpoints %>%
        select(endpoint_pattern, score, midpoint, invert),
      by = c("hazardId" = "endpoint_pattern", "finalScore" = "score")
    ) %>%
    transmute(
      dtxsid,
      hazardId,
      finalScore,
      invert,
      n_values     = 0L,
      value_pick   = midpoint,
      value_min    = midpoint,
      value_max    = midpoint,
      value_spread = 1,
      value_source = "midpoint_lookup"
    )

  # =================================================================
  # STEP 3: ND and I records — no value, provenance only
  # =================================================================
  nd_records <- data %>%
    filter(finalScore == "ND" | finalScore == "I") %>%
    left_join(invert_flags, by = c("hazardId" = "endpoint_pattern")) %>%
    transmute(
      dtxsid,
      hazardId,
      finalScore,
      invert,
      n_values     = 0L,
      value_pick   = NA_real_,
      value_min    = NA_real_,
      value_max    = NA_real_,
      value_spread = NA_real_,
      value_source = if_else(finalScore == "I", "insufficient", "no_data")
    )

  # =================================================================
  # STEP 4: Combine and apply inversion
  # =================================================================
  all_records <- bind_rows(value_summary, midpoint_fallback, nd_records) %>%
    mutate(
      # Invert dose-response endpoints so higher = worse for ToxPi
      amount = case_when(
        invert == TRUE & !is.na(value_pick) ~ 1 / value_pick,
        TRUE ~ value_pick
      )
    )

  # =================================================================
  # STEP 5: Pivot to wide format
  # =================================================================
  records_wide <- all_records %>%
    select(dtxsid, hazardId, amount) %>%
    pivot_wider(
      id_cols = dtxsid,
      names_from = hazardId,
      values_from = amount
    )

  # Source metadata for the characterization layer
  source_meta <- all_records %>%
    select(dtxsid, hazardId, value_source) %>%
    pivot_wider(
      id_cols = dtxsid,
      names_from = hazardId,
      values_from = value_source,
      names_prefix = "source_"
    )

  # Spread metadata for the confidence layer
  spread_meta <- all_records %>%
    select(dtxsid, hazardId, value_spread, n_values) %>%
    pivot_wider(
      id_cols = dtxsid,
      names_from = hazardId,
      values_from = c(value_spread, n_values),
      names_glue = "{.value}_{hazardId}"
    )

  return(list(
    records = records_wide,
    sources = source_meta,
    spread  = spread_meta
  ))
}


# =============================================================================
# SECTION 5: CACHING
# =============================================================================

#' Cache API responses to disk
#'
#' @param query Vector of DTXSIDs
#' @param cache_dir Directory for cache files
#' @return Path to cache file, or NULL if no cache
get_cache_path <- function(query, cache_dir) {
  if (is.null(cache_dir)) return(NULL)
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  # Hash the query to create a unique filename
  hash <- digest::digest(sort(query), algo = "md5")
  file.path(cache_dir, paste0("hcd_", hash, ".rds"))
}

#' Load cached response if available and fresh
#'
#' @param cache_path Path from get_cache_path()
#' @param max_age_days Maximum age of cache in days (default 30)
#' @return Cached data or NULL
load_cache <- function(cache_path, max_age_days = 30) {
  if (is.null(cache_path) || !file.exists(cache_path)) return(NULL)

  file_age <- difftime(Sys.time(), file.mtime(cache_path), units = "days")
  if (as.numeric(file_age) > max_age_days) {
    message("Cache expired (", round(file_age, 1), " days old). Re-fetching.")
    return(NULL)
  }

  message("Loading cached HCD response (", round(file_age, 1), " days old)")
  readRDS(cache_path)
}


# =============================================================================
# SECTION 6: READ-ACROSS INTEGRATION POINT
# =============================================================================
# This section defines the interface for gap-filling data-poor compounds.
# The actual read-across search uses chemi_hazard's existing analog parameters
# or can be done separately via GenRA.

#' Flag compounds that are blind spots and candidates for read-across
#'
#' @param characterization Output of compute_characterization()
#' @param threshold_char Characterization score below which to flag
#' @return Tibble of DTXSIDs that need read-across
identify_readacross_candidates <- function(characterization,
                                            threshold_char = 0.15) {
  characterization %>%
    filter(characterization < threshold_char) %>%
    select(dtxsid, characterization, char_tier,
           endpoint_coverage, n_with_data, n_no_data) %>%
    arrange(characterization)
}

#' Merge read-across results with direct hazard data
#'
#' Read-across values are tagged with lower confidence weights and
#' a distinct authority label ("Read-across") for the confidence layer.
#'
#' @param direct_records Records from direct HCD query
#' @param readacross_records Records from analog-based query
#' @param similarity_threshold Minimum Tanimoto similarity for acceptance
#' @return Merged records with provenance tracking
merge_readacross <- function(direct_records, readacross_records,
                              similarity_threshold = 0.6) {
  # Only fill gaps — don't overwrite direct data
  gaps <- direct_records %>%
    pivot_longer(-dtxsid, names_to = "endpoint", values_to = "direct_value") %>%
    filter(is.na(direct_value))

  if (nrow(gaps) == 0) {
    message("No gaps to fill via read-across.")
    return(direct_records)
  }

  # Join read-across values for gap endpoints only
  filled <- gaps %>%
    left_join(
      readacross_records %>%
        pivot_longer(-dtxsid, names_to = "endpoint", values_to = "ra_value"),
      by = c("dtxsid", "endpoint")
    ) %>%
    mutate(
      # Use read-across value if available, otherwise stays NA
      final_value = coalesce(direct_value, ra_value),
      filled_by_readacross = !is.na(ra_value) & is.na(direct_value)
    )

  message("Read-across filled ", sum(filled$filled_by_readacross),
          " of ", nrow(gaps), " gaps (",
          round(mean(filled$filled_by_readacross) * 100, 1), "%)")

  # Rebuild wide format
  filled %>%
    select(dtxsid, endpoint, final_value) %>%
    pivot_wider(id_cols = dtxsid, names_from = endpoint,
                values_from = final_value)
}


# =============================================================================
# SECTION 7: DIAGNOSTICS
# =============================================================================

#' Print a coverage report for hazard data
#'
#' @param data The data$data output from chemi_hazard()
diagnose_hazard_coverage <- function(data) {
  cat("\n=== Hazard Data Coverage Report ===\n\n")

  # Per-endpoint coverage
  cat("Endpoint coverage (% of compounds with data):\n")
  data %>%
    mutate(has_data = finalScore != "ND" & !is.na(finalScore)) %>%
    group_by(hazardId) %>%
    summarise(
      n_compounds = n_distinct(dtxsid),
      n_with_data = n_distinct(dtxsid[has_data]),
      pct         = round(n_with_data / n_compounds * 100, 1),
      n_auth      = n_distinct(dtxsid[finalAuthority == "Authoritative"]),
      n_screen    = n_distinct(dtxsid[finalAuthority == "Screening"]),
      n_qsar      = n_distinct(dtxsid[finalAuthority == "QSAR Model"]),
      .groups = "drop"
    ) %>%
    left_join(hazard_endpoints %>% select(hazardId, display_name, group),
              by = "hazardId") %>%
    arrange(pct) %>%
    select(display_name, group, pct, n_auth, n_screen, n_qsar) %>%
    print(n = 20)

  # Per-compound characterization distribution
  cat("\nCharacterization tier distribution:\n")
  char <- compute_characterization(data)
  char %>%
    count(char_tier) %>%
    mutate(pct = round(n / sum(n) * 100, 1)) %>%
    print()

  cat("\nBlind spots (characterization < 0.15):\n")
  char %>%
    filter(char_tier == "Blind spot") %>%
    select(dtxsid, characterization, endpoint_coverage, n_with_data) %>%
    print(n = 20)
}


# =============================================================================
# SECTION 8: MAIN FUNCTION (placeholder for API plumbing)
# =============================================================================
# The actual API call, response parsing, and payload generation are
# identical to v1. The refactored parts are:
#   - Coercion uses lookup tables instead of repeated case_when
#   - I vs ND are distinguished in output
#   - Characterization score is computed and returned
#   - Caching layer wraps the API call
#   - Diagnostic report runs automatically
#
# To integrate: replace the body of chemi_hazard() with the v1 API
# plumbing, then swap the coercion switch with calls to
# coerce_simple(), coerce_bin(), or coerce_numerical().
# Add compute_characterization() to the return list.
#
# Sketch of the updated return structure:
#
# chemi_hazard <- function(query, coerce = "numerical", cache_dir = NULL, ...) {
#
#   # [v1 API plumbing goes here, with caching wrapper]
#   # cache_path <- get_cache_path(query, cache_dir)
#   # cached <- load_cache(cache_path)
#   # if (!is.null(cached)) { df <- cached } else { ... POST ... saveRDS(df, cache_path) }
#
#   # [v1 cleaning and merging goes here]
#
#   # Coerce
#   data$records <- switch(coerce,
#     simple    = coerce_simple(data$data),
#     bin       = coerce_bin(data$data),
#     numerical = coerce_numerical(data$data, raw_records)
#   )
#
#   # Characterization (NEW)
#   data$characterization <- compute_characterization(data$data)
#
#   # Read-across candidates (NEW)
#   data$blind_spots <- identify_readacross_candidates(data$characterization)
#
#   # Diagnostics
#   diagnose_hazard_coverage(data$data)
#
#   return(data)
# }

cat("chemi_hazard_v2.R loaded.\n")
cat("Available: hazard_midpoints (", nrow(hazard_midpoints), "rows),",
    "hazard_endpoints (", nrow(hazard_endpoints), "rows)\n")
cat("Functions: coerce_simple(), coerce_bin(), coerce_numerical(),\n")
cat("           compute_characterization(), identify_readacross_candidates(),\n")
cat("           merge_readacross(), diagnose_hazard_coverage()\n")
