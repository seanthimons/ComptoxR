#' Safety + GHS data from Cheminformatics
#'
#' @description
#' Returns a data frame that contains a binned comparison table generated from the GHS codes and the NFPA 704 'safety diamond'
#'
#'
#' @param query A list of DTXSIDs to search for
#'
#' @return A list of data
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety(query = "DTXSID7020182")
#' }
chemi_safety <- function(query) {
  
  # Request standardized via generic_chemi_request
  df_raw <- generic_chemi_request(
    query = query,
    endpoint = "safety",
    server = 'chemi_burl',
    wrap = FALSE
  )
  
  if (nrow(df_raw) == 0) return(invisible(NULL))

  # Tidy up headers early using vectorized logic
  headers <- df_raw %>%
    dplyr::filter(!purrr::map_lgl(chemical, is.null)) %>%
    dplyr::select(dtxsid = sid, chemical) %>%
    tidyr::unnest_wider(chemical) %>%
    dplyr::select(dplyr::any_of(c("name", "dtxsid")))

  # Extract flags into a long-format dataframe for cleaner processing
  flags_long <- df_raw %>%
    dplyr::select(dtxsid, flags) %>%
    tidyr::unnest_wider(flags)

  # --- Optimized NFPA Decoding ---
  nfpa <- NULL
  if ("NFPA" %in% colnames(flags_long)) {
    # Static mapping for NFPA codes to bins
    nfpa_bin_map <- c("1" = "L", "2" = "M", "3" = "H", "4" = "VH", "0" = "I")
    
    nfpa <- flags_long %>%
      dplyr::select(dtxsid, NFPA) %>%
      tidyr::unnest(NFPA) %>%
      tidyr::unnest(NFPA) %>%
      dplyr::mutate(
        nfpa_health = stringr::str_sub(NFPA, 1, 1),
        nfpa_fire = stringr::str_sub(NFPA, 2, 2),
        nfpa_stability = stringr::str_sub(NFPA, 3, 3),
        nfpa_special = stringr::str_sub(NFPA, 4, -1),
        # Vectorized lookup instead of case_when
        health_bin = nfpa_bin_map[nfpa_health],
        fire_bin = nfpa_bin_map[nfpa_fire],
        stability_bin = nfpa_bin_map[nfpa_stability],
        special_bin = dplyr::if_else(!stringr::str_detect(nfpa_special, "\\S"), NA_character_, nfpa_special)
      ) %>%
      dplyr::select(-NFPA, -dplyr::starts_with("nfpa_")) %>%
      tidyr::pivot_longer(
        cols = health_bin:special_bin,
        values_to = "bin",
        names_to = "hazard_class",
        values_drop_na = TRUE
      ) %>%
      dplyr::mutate(
        # Handle special VH overrides for oxidizing/water-reactive
        bin = dplyr::case_when(
          bin %in% c("OX", "W") ~ "VH",
          .default = bin
        )
      )
  }

  # --- Optimized GHS Mapping ---
  ghs_codes <- NULL
  if ("GHS Codes" %in% colnames(flags_long)) {
    ghs_tbl <- ghs_create_tbl() # Uses session cache internally
    
    ghs_codes <- flags_long %>%
      dplyr::select(dtxsid, `GHS Codes`) %>%
      tidyr::unnest_longer(`GHS Codes`) %>%
      dplyr::rename(h_code = `GHS Codes`) %>%
      # Fast join against the GHS dictionary
      dplyr::inner_join(ghs_tbl, by = "h_code")
  }

  # --- Physical Hazards Summary Merging ---
  final_df <- dplyr::bind_rows(nfpa, ghs_codes) %>%
    dplyr::filter(hazard_class != "health_bin") %>%
    dplyr::mutate(
      # Grouping endpoints into logical classes
      class = dplyr::case_when(
        hazard_class %in% c("stability_bin", "Desensitized explosives", "Explosives") ~ "Explosives",
        hazard_class %in% c(
          "fire_bin", "Flammable gases", "Flammable liquids", "Flammable solids", 
          "Pyrophoric solids", "Pyrophoric liquids", "Substances and mixtures which in contact with water, emit flammable gases",
          "Self-heating substances and mixtures"
        ) ~ "Flammable",
        hazard_class %in% c(
          "Oxidizing gases", "Oxidizing liquids; Oxidizing solids", "Self-reactive substances and mixtures; Organic peroxides"
        ) ~ "Oxidizers/ Self-Rxn",
        hazard_class %in% c("Gases under pressure", "Chemicals under pressure", "Aerosols") ~ "Pressurized chemicals",
        hazard_class %in% c(
          "Corrosive to Metals", "Skin corrosion/irritation and serious eye damage/eye irritation", 
          "Skin corrosion/irritation", "Serious eye damage/eye irritation"
        ) ~ "Corrosive",
        hazard_class == "Hazardous to the ozone layer" ~ "Ozone-depleting",
        .default = hazard_class
      ),
      bin = factor(bin, levels = c("VH", "H", "M", "L", "I", "ND", NA)),
    ) %>%
    dplyr::arrange(bin) %>%
    dplyr::distinct(dtxsid, class, .keep_all = TRUE) %>%
    tidyr::pivot_wider(
      id_cols = dtxsid,
      names_from = class,
      values_from = bin,
      values_fill = NA
    )

  # Final summary counts using rowSums (vectorized) instead of rowwise()
  final_df <- final_df %>%
    dplyr::mutate(n = rowSums(!is.na(dplyr::across(-dtxsid)))) %>%
    dplyr::arrange(dplyr::desc(n)) %>%
    dplyr::inner_join(headers, by = "dtxsid") %>%
    dplyr::relocate(name, .before = dtxsid)

  return(final_df)
}


#' Optimized GHS Table Creation with Session Caching
#'
#' @return Data frame
ghs_create_tbl <- function() {
  # Check if table is already in session cache
  if (!is.null(.ComptoxREnv$ghs_table)) {
    return(.ComptoxREnv$ghs_table)
  }

  url <- "https://pubchem.ncbi.nlm.nih.gov/ghs/ghscode_10.txt"
  lines <- tryCatch(readLines(url, warn = FALSE), error = function(e) return(NULL))
  
  if (is.null(lines)) return(tibble::tibble())

  split_lines <- purrr::map(strsplit(lines, "\t"), ~ .x[-8])
  # Header is actually H-Code, Statement, Class, Category, UN, Pictogram, Signal
  # We only need H-Code and the bin logic.
  df <- as.data.frame(do.call(rbind, split_lines[-1]), stringsAsFactors = FALSE)
  colnames(df) <- split_lines[[1]]

  # Unified binning logic
  res <- df %>%
    dplyr::filter(stringr::str_detect(`H-Code`, pattern = "H")) %>%
    dplyr::mutate(
      bin = dplyr::case_when(
        `H-Code` %in% c("H222", "H229", "H304", "H282", "H314", "H318", "H315+H320", "H220", "H221", "H230", "H231", "H232", "H224", "H225", "H228", "H270", "H271", "H272", "H250", "H251") ~ "VH",
        `H-Code` %in% c("H240", "H241", "H242", "H260", "H261", "H200", "H201", "H202", "H203", "H205", "H209", "H210", "H211", "H206", "H207") ~ "VH",
        `H-Code` %in% c("H223", "H305", "H283", "H284", "H290", "H204", "H208", "H226", "H227", "H280", "H281", "H420", "H252") ~ "H",
        `H-Code` %in% c("H315", "H319") ~ "M",
        `H-Code` %in% c("H316", "H320") ~ "L",
        `H-Code` == "-" ~ "I",
        .default = "MISSING"
      )
    ) %>%
    dplyr::filter(bin != "MISSING") %>%
    dplyr::select(h_code = `H-Code`, hazard_class = `Hazard Class`, bin) %>%
    dplyr::distinct(h_code, bin, .keep_all = TRUE)

  # Cache the result for the remainder of the session
  .ComptoxREnv$ghs_table <- res
  
  return(res)
}
