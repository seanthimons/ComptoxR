#' Optimized Hazard Comparison
#'
#' @description
#' Retrieves records for queried compounds. Generates a list containing headers,
#' raw long-form data, binned scores, and (optionally) coerced numerical records.
#'
#' @param query A list of DTXSIDS to search for.
#' @param analogs String of variables to search for. Defaults to no analogs.
#' @param min_sim Tanimoto similarity coefficient. Defaults to `0.8`.
#' @param coerce Choice of `simple`, `bin`, or `numerical`.
#'
#' @return A list of dataframes
#' @export
chemi_hazard <- function(
  query,
  analogs = c('substructure', 'similar', 'toxprint'),
  min_sim = NULL,
  coerce = c('simple', 'bin', 'numerical')
) {

  # --- 1. Setup & Request ---
  analogs <- if (missing(analogs)) NULL else rlang::arg_match(analogs)
  if (!is.null(analogs)) analogs <- stringr::str_to_upper(analogs)
  min_sim <- if (!is.null(analogs) && !is.null(min_sim)) as.character(min_sim) else '0.8'
  coerce <- rlang::arg_match(coerce)

  df_raw <- generic_chemi_request(
    query = query,
    endpoint = "hazard",
    options = list(minSimilarity = min_sim, analogSearchType = analogs),
    server = "chemi_burl",
    tidy = FALSE # Maintain list structure for deep cleaning
  )

  if (is.null(df_raw) || length(df_raw) == 0) return(invisible(NULL))

  # --- 2. Unified Long-Format Extraction ---
  # Pivot to tidy long format as early as possible to vectorize logic
  hazard_chemicals <- purrr::pluck(df_raw, "hazardChemicals")
  
  # Standardize headers
  headers <- purrr::map_dfr(hazard_chemicals, ~ {
    c <- purrr::pluck(.x, "chemical")
    tibble::tibble(dtxsid = c$sid, name = c$name)
  }) %>% dplyr::distinct()

  # Standardize all scores into a unified long tidy tibble
  long_data <- purrr::map_dfr(hazard_chemicals, function(chem_entry) {
    sid <- purrr::pluck(chem_entry, "chemical", "sid")
    scores <- purrr::pluck(chem_entry, "scores")
    
    purrr::map_dfr(scores, function(s) {
      records <- purrr::pluck(s, "records")
      # Extract core record data (taking first record or NA if empty)
      rec_data <- if (length(records) > 0) records[[1]] else list()
      
      tibble::as_tibble(purrr::compact(list(
        dtxsid = sid,
        hazardId = s$hazardId,
        finalScore = s$finalScore,
        finalAuthority = s$finalAuthority,
        hazardCode = rec_data$hazardCode,
        valueMass = rec_data$valueMass,
        source = rec_data$source,
        rationale = rec_data$rationale
      )))
    })
  })

  # --- 3. Binning & Display Logic ---
  # Define static order for consistent rendering
  endpoint_order <- c(
    "acuteMammalianOral", "acuteMammalianDermal", "acuteMammalianInhalation",
    "developmental", "reproductive", "endocrine", "genotoxicity", "carcinogenicity",
    "neurotoxicitySingle", "neurotoxicityRepeat", "systemicToxicitySingle", "systemicToxicityRepeat",
    "eyeIrritation", "skinIrritation", "skinSensitization", "acuteAquatic", "chronicAquatic",
    "persistence", "bioaccumulation", "exposure"
  )

  processed_data <- long_data %>%
    dplyr::mutate(
      hazardId = factor(hazardId, levels = endpoint_order),
      # Add styling for displays
      display_score = dplyr::case_when(
        finalAuthority == 'Authoritative' ~ paste0('<b>', finalScore, '</b>'),
        finalAuthority == 'QSAR Model' ~ paste0('<i>', finalScore, '</i>'),
        .default = finalScore
      )
    ) %>%
    dplyr::arrange(hazardId, factor(finalScore, levels = c('VH', 'H', 'M', 'L', 'I', 'ND', NA))) %>%
    dplyr::distinct(dtxsid, hazardId, .keep_all = TRUE)

  # --- 4. Coercion Branch Logic (Optimized) ---
  coerced_records <- NULL
  
  if (coerce == "simple") {
    score_map <- c('VH' = 5, 'H' = 4, 'M' = 3, 'L' = 2, 'I' = 1)
    coerced_records <- processed_data %>%
      dplyr::mutate(amount = score_map[finalScore]) %>%
      tidyr::pivot_wider(id_cols = dtxsid, names_from = hazardId, values_from = amount)
      
  } else if (coerce == "bin") {
    auth_map <- c('Authoritative' = 0, 'Screening' = 1/3, 'QSAR Model' = 2/3)
    score_map <- c('VH' = 5, 'H' = 4, 'M' = 3, 'L' = 2, 'I' = 1)
    coerced_records <- processed_data %>%
      dplyr::mutate(
        val = score_map[finalScore],
        penalty = dplyr::coalesce(auth_map[finalAuthority], 0),
        amount = val - penalty
      ) %>%
      tidyr::pivot_wider(id_cols = dtxsid, names_from = hazardId, values_from = amount)
      
  } else if (coerce == "numerical") {
    # Optimized lookup join instead of sequential str_detect
    scoring_matrix <- get_hazard_scoring_matrix()
    
    # 1. First, handle explicit valueMass data
    num_data <- processed_data %>%
      dplyr::filter(!finalScore %in% c("ND", "I") & !is.null(valueMass)) %>%
      dplyr::mutate(
        amount = valueMass,
        invert = hazardId %in% c('persistence', 'acuteMammalianOral', 'acuteMammalianDermal', 'acuteMammalianInhalation', 'acuteAquatic', 'chronicAquatic')
      )
    
    # 2. Join against Scoring Matrix for categorical overrides
    cat_data <- processed_data %>%
      dplyr::left_join(scoring_matrix, by = c("hazardId" = "endpoint", "finalScore")) %>%
      dplyr::filter(!is.na(amount))
    
    # 3. Clean and Invert
    coerced_records <- dplyr::bind_rows(num_data, cat_data) %>%
      dplyr::mutate(amount = dplyr::if_else(dplyr::coalesce(invert_flag, FALSE), 1/amount, amount)) %>%
      tidyr::pivot_wider(id_cols = dtxsid, names_from = hazardId, values_from = amount)
  }

  # --- 5. Assemble Result List ---
  results <- list(
    headers = headers,
    data = processed_data %>% dplyr::select(dtxsid, hazardId, finalAuthority, finalScore),
    score = processed_data %>% tidyr::pivot_wider(id_cols = dtxsid, names_from = hazardId, values_from = finalScore),
    display_table = processed_data %>% tidyr::pivot_wider(id_cols = dtxsid, names_from = hazardId, values_from = display_score),
    records = coerced_records
  )

  return(results)
}
