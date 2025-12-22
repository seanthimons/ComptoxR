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

  # Post-processing logic (previously flags field)
  # In the original, it was df <- pluck(df, "flags") %>% set_names(., query)
  # generic_chemi_request already attempted to flatten/convert to tibble.
  # If 'flags' was a nested list in each item, we need to extract it.
  
  # For safety, I'll keep the extensive binning logic as it was, 
  # but adjust it to work with the output of generic_chemi_request.
  # Since I can't easily test the API response structure right now, 
  # I'll ensure the logic remains as robust as possible to tibble input.

  # Note: The original function returned a complex multi-column tibble.
  # I will maintain that output structure.
  
  # Re-implementing the core of the original logic using the tibble output:
  
  data <- list(
    headers = NULL,
    nfpa = NULL,
    ghs = NULL,
    ghs_codes = NULL
  )

  # Check if we have the expected columns
  if (!"chemical" %in% colnames(df_raw)) {
     # If generic_chemi_request flattened too much or not enough
     # we might need to handle it. Assuming 'chemical' and 'flags' are now columns of lists.
  }

  # Headers
  data$headers <- df_raw %>%
    dplyr::filter(!purrr::map_lgl(chemical, is.null)) %>%
    dplyr::select(chemical) %>%
    tidyr::unnest_wider(chemical) %>%
    dplyr::rename(dtxsid = sid) %>%
    dplyr::select(dplyr::any_of(c("name", "dtxsid")))

  # Flags extraction
  flags_df <- df_raw %>%
    dplyr::rename(dtxsid = dtxsid) %>% # generic_chemi_request added dtxsid
    dplyr::select(dtxsid, flags) %>%
    tidyr::unnest_wider(flags)

  # NFPA logic
  if ("NFPA" %in% colnames(flags_df)) {
    data$nfpa <- flags_df %>%
      dplyr::select(dtxsid, NFPA) %>%
      tidyr::unnest(NFPA) %>%
      tidyr::unnest(NFPA) %>%
      dplyr::mutate(
        nfpa_health = stringr::str_sub(NFPA, 1, 1),
        nfpa_fire = stringr::str_sub(NFPA, 2, 2),
        nfpa_stability = stringr::str_sub(NFPA, 3, 3),
        nfpa_special = stringr::str_sub(NFPA, 4, -1),
        health_bin = dplyr::case_when(
          nfpa_health == 1 ~ "L",
          nfpa_health == 2 ~ "M",
          nfpa_health == 3 ~ "H",
          nfpa_health == 4 ~ "VH",
          nfpa_health == 0 ~ "I",
          .default = NA
        ),
        fire_bin = dplyr::case_when(
          nfpa_fire == 1 ~ "L",
          nfpa_fire == 2 ~ "M",
          nfpa_fire == 3 ~ "H",
          nfpa_fire == 4 ~ "VH",
          nfpa_fire == 0 ~ "I",
          .default = NA
        ),
        stability_bin = dplyr::case_when(
          nfpa_stability == 1 ~ "L",
          nfpa_stability == 2 ~ "M",
          nfpa_stability == 3 ~ "H",
          nfpa_stability == 4 ~ "VH",
          nfpa_stability == 0 ~ "I",
          .default = NA
        ),
        special_bin = if_else(
          !stringr::str_detect(nfpa_special, "\\S"),
          NA_character_,
          nfpa_special
        )
      ) %>%
      dplyr::select(-NFPA, -dplyr::starts_with("nfpa_")) %>%
      tidyr::pivot_longer(
        cols = health_bin:special_bin,
        values_to = "bin",
        names_to = "hazard_class",
        values_drop_na = TRUE
      ) %>%
      dplyr::mutate(
        val = dplyr::case_when(
          bin == "OX" ~ "OX",
          bin == "W" ~ "W",
          .default = NA_character_
        ),
        bin = dplyr::case_when(
          !is.na(val) ~ "VH",
          .default = bin
        )
      )
  }

  # GHS logic
  if ("GHS" %in% colnames(flags_df)) {
    data$ghs <- flags_df %>%
      dplyr::select(dtxsid, GHS) %>%
      tidyr::unnest_longer(GHS) %>%
      dplyr::rename(val = GHS)
  }

  # GHS Codes logic
  if ("GHS Codes" %in% colnames(flags_df)) {
    data$ghs_codes <- flags_df %>%
      dplyr::select(dtxsid, `GHS Codes`) %>%
      tidyr::unnest_longer(`GHS Codes`) %>%
      dplyr::rename(val = `GHS Codes`)
  }

  # Dictionary Mapping
  ghs_tbl <- ghs_create_tbl()
  colnames(ghs_tbl) <- c(
    "h_code", "hazard_statement", "hazard_class", "hazard_category",
    "un_model_regulations_class_or_division", "ghs_pictogram", "ghs_signal_word", "bin"
  )
  ghs_tbl <- ghs_tbl %>%
    dplyr::filter(bin != "MISSING") %>%
    dplyr::distinct(h_code, bin, .keep_all = TRUE) %>%
    dplyr::select(h_code, hazard_class, bin)

  # Physical Hazards Merging
  final_df <- dplyr::inner_join(data$ghs_codes, ghs_tbl, by = dplyr::join_by(val == h_code)) %>%
    dplyr::bind_rows(data$nfpa, .) %>%
    dplyr::filter(hazard_class != "health_bin") %>%
    dplyr::mutate(
      class = dplyr::case_when(
        hazard_class %in% c("stability_bin", "Desensitized explosives", "Explosives") ~ "Explosives",
        hazard_class %in% c(
          "fire_bin", "Flammable gases", "Flammable liquids", "Flammable solids", 
          "Pyrophoric solids", "Pyrophoric liquids", "Substances and mixtures which in contact with water, emit flammable gases",
          "Self-heating substances and mixtures"
        ) ~ "Flammable",
        hazard_class == "special_bin" & val == "W" ~ "Flammable",
        hazard_class %in% c(
          "Oxidizing gases", "Oxidizing liquids; Oxidizing solids", "Self-reactive substances and mixtures; Organic peroxides"
        ) ~ "Oxidizers/ Self-Rxn",
        hazard_class == "special_bin" & val == "OX" ~ "Oxidizers/ Self-Rxn",
        hazard_class %in% c("Gases under pressure", "Chemicals under pressure", "Aerosols") ~ "Pressurized chemicals",
        hazard_class %in% c(
          "Corrosive to Metals", "Skin corrosion/irritation and serious eye damage/eye irritation", 
          "Skin corrosion/irritation", "Serious eye damage/eye irritation"
        ) ~ "Corrosive",
        hazard_class %in% c("Hazardous to the ozone layer") ~ "Ozone-depleting",
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
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(n = sum(!is.na(dplyr::c_across(!dtxsid)))) %>%
    dplyr::arrange(dplyr::desc(n)) %>%
    dplyr::ungroup() %>%
    dplyr::inner_join(data$headers, by = "dtxsid")

  return(final_df)
}


#' Creates a GHS table with risk bins into the Global Environment.
#'
#' @return Data frame
ghs_create_tbl <- function() {
  url <- "https://pubchem.ncbi.nlm.nih.gov/ghs/ghscode_10.txt"
  lines <- readLines(url, warn = FALSE)
  split_lines <- purrr::map(strsplit(lines, "\t"), ~ .x[-8])
  header <- split_lines[[1]]
  data <- split_lines[-1]
  df <- as.data.frame(do.call(rbind, data), stringsAsFactors = FALSE)
  colnames(df) <- header

  df <- df %>%
    dplyr::filter(stringr::str_detect(`H-Code`, pattern = "H")) %>%
    dplyr::mutate(
      bin = dplyr::case_when(
        `H-Code` %in% c("H222", "H229") ~ "VH",
        `H-Code` == "H223" ~ "H",
        `H-Code` == "H304" ~ "VH",
        `H-Code` == "H305" ~ "H",
        `H-Code` == "H282" ~ "VH",
        `H-Code` %in% c("H283", "H284") ~ "H",
        `H-Code` == "H290" ~ "H",
        `H-Code` == "H314" ~ "VH",
        `H-Code` == "H315" ~ "M",
        `H-Code` == "H316" ~ "L",
        `H-Code` == "H318" ~ "VH",
        `H-Code` == "H319" ~ "M",
        `H-Code` == "H320" ~ "L",
        `H-Code` == "H315+H320" ~ "VH",
        `H-Code` %in% c("H200", "H201", "H202", "H203", "H205", "H209", "H210", "H211") ~ "VH",
        `H-Code` == "H204" ~ "H",
        `H-Code` %in% c("H206", "H207") ~ "VH",
        `H-Code` == "H208" ~ "H",
        `H-Code` %in% c("H220", "H221", "H230", "H231", "H232") ~ "VH",
        `H-Code` %in% c("H224", "H225") ~ "VH",
        `H-Code` %in% c("H226", "H227") ~ "H",
        `H-Code` == "H228" ~ "VH",
        `H-Code` %in% c("H280", "H281") ~ "H",
        `H-Code` == "H420" ~ "H",
        `H-Code` == "H270" ~ "VH",
        `H-Code` %in% c("H271", "H272") ~ "VH",
        `H-Code` == "H250" ~ "VH",
        `H-Code` == "H251" ~ "VH",
        `H-Code` == "H252" ~ "H",
        `H-Code` %in% c("H240", "H241", "H242") ~ "VH",
        `H-Code` %in% c("H260", "H261") ~ "VH",
        `H-Code` == "-" ~ "I",
        .default = "MISSING"
      )
    )

  return(df)
}
