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

chemi_safety <- function(query) {
  # url <- "https://hcd.rtpnc.epa.gov/api/safety"
  url <- "https://ccte-cced-cheminformatics.epa.gov/api/resolver/safety-flags"

  chemicals <- vector(mode = "list", length = length(query))

  chemicals <- map2(
    chemicals,
    query,
    \(x, y)
      x <- list(
        sid = y
      )
  )

  payload <- chemicals

  cli_rule(left = "Safety payload options")
  cli_dl(
    c(
      "Number of compounds" = "{length(query)}"
    )
  )
  cli_rule()
  cli_end()

  response <- POST(
    url = url,
    body = payload,
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = "json",
    progress()
  )
  cli_rule()

  df <- content(response, "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(simplifyVector = FALSE)

  df <- pluck(df, "flags") %>%
    set_names(., query)

  data <- list(
    headers = NULL,
    # rqcode = NULL,
    # reg_info = NULL,
    # handling = NULL,
    # accident_release = NULL,
    nfpa = NULL,
    ghs = NULL,
    ghs_codes = NULL
  )

  # Headers----
  data$headers <- df %>%
    map_dfr(., ~ pluck(., "chemical")) %>%
    rename(dtxsid = sid) %>%
    select(., name, dtxsid)

  # NFPA --------------------------------------------------------------------

  data$nfpa <- df %>%
    map(., ~ pluck(., "flags", "NFPA")) %>%
    compact() %>%
    # list_flatten() %>% #more trouble than needed, swapped to double unnest
    enframe(., name = "dtxsid", value = "val") %>%
    unnest(., cols = val) %>%
    unnest(., cols = val) %>%
    mutate(
      nfpa_health = str_sub(val, 1, 1),
      nfpa_fire = str_sub(val, 2, 2),
      nfpa_stability = str_sub(val, 3, 3),
      nfpa_special = str_sub(val, 4, -1),
      health_bin = case_when(
        nfpa_health == 1 ~ "L",
        nfpa_health == 2 ~ "M",
        nfpa_health == 3 ~ "H",
        nfpa_health == 4 ~ "VH",
        nfpa_health == 0 ~ "I",
        .default = NA
      ),
      fire_bin = case_when(
        nfpa_fire == 1 ~ "L",
        nfpa_fire == 2 ~ "M",
        nfpa_fire == 3 ~ "H",
        nfpa_fire == 4 ~ "VH",
        nfpa_fire == 0 ~ "I",
        .default = NA
      ),
      stability_bin = case_when(
        nfpa_stability == 1 ~ "L",
        nfpa_stability == 2 ~ "M",
        nfpa_stability == 3 ~ "H",
        nfpa_stability == 4 ~ "VH",
        nfpa_stability == 0 ~ "I",
        .default = NA
      ),
      special_bin = if_else(
        !str_detect(nfpa_special, "\\S"),
        NA_character_,
        nfpa_special
      )
    ) %>%
    select(
      -val,
      -starts_with("nfpa_")
    ) %>%
    pivot_longer(
      .,
      cols = health_bin:special_bin,
      values_to = "bin",
      names_to = "hazard_class",
      values_drop_na = T
    ) %>%
    mutate(
      val = case_when(
        bin == "OX" ~ "OX",
        bin == "W" ~ "W",
        .default = NA_character_
      ),
      bin = case_when(
        !is.na(val) ~ "VH",
        .default = bin
      )
    )

  # GHS----

  data$ghs <- df %>%
    map(., ~ pluck(., "flags", "GHS")) %>%
    compact() %>%
    enframe(., name = "dtxsid", value = "val") %>%
    unnest_longer(., col = val)

  # GHS codes----

  data$ghs_codes <- df %>%
    map(., ~ pluck(., "flags", "GHS Codes")) %>%
    enframe(., name = "dtxsid", value = "val") %>%
    unnest_longer(., col = val)

  # Dictionary-----

  ghs_tbl <- ghs_create_tbl()

  colnames(ghs_tbl) <- c(
    "h_code",
    "hazard_statement",
    "hazard_class",
    "hazard_category",
    "un_model_regulations_class_or_division",
    "ghs_pictogram",
    "ghs_signal_word",
    "bin"
  )

  ghs_tbl <- filter(ghs_tbl, bin != "MISSING") %>%
    distinct(h_code, bin, .keep_all = T) %>%
    select(h_code, hazard_class, bin)

  # Physical Hazards --------------------------------------------------------

  df <- inner_join(data$ghs_codes, ghs_tbl, join_by("val" == "h_code")) %>%
    bind_rows(data$nfpa, .) %>%
    filter(hazard_class != "health_bin") %>%
    mutate(
      class = case_when(
        hazard_class %in%
          c(
            "stability_bin",
            "Desensitized explosives",
            "Explosives"
          ) ~
          "Explosives",
        hazard_class %in%
          c(
            "fire_bin",
            "Flammable gases",
            "Flammable gases ",
            "Flammable liquids",
            "Flammable solids",
            "Pyrophoric solids",
            "Pyrophoric liquids",
            "Substances and mixtures which in contact with water, emit flammable gases",
            "Self-heating substances and mixtures"
          ) ~
          "Flammable",
        hazard_class == "special_bin" & val == "W" ~ "Flammable",
        hazard_class %in%
          c(
            "Oxidizing gases",
            "Oxidizing liquids; Oxidizing solids",
            "Self-reactive substances and mixtures; Organic peroxides"
          ) ~
          "Oxidizers/ Self-Rxn",
        hazard_class == "special_bin" & val == "OX" ~ "Oxidizers/ Self-Rxn",
        hazard_class %in%
          c(
            "Gases under pressure",
            "Chemicals under pressure",
            "Aerosols"
          ) ~
          "Pressurized chemicals",
        hazard_class %in%
          c(
            "Corrosive to Metals",
            "Skin corrosion/irritation and serious eye damage/eye irritation",
            "Skin corrosion/irritation",
            "Serious eye damage/eye irritation"
          ) ~
          "Corrosive",
        hazard_class %in% c("Hazardous to the ozone layer") ~ "Ozone-depleting", # may not be needed
        .default = hazard_class
      ),
      bin = factor(bin, levels = c("VH", "H", "M", "L", "I", "ND", NA)),
    ) %>%
    arrange(bin) %>%
    distinct(., dtxsid, class, .keep_all = T) %>%
    pivot_wider(
      .,
      id_cols = dtxsid,
      names_from = class,
      values_from = bin,
      values_fill = NA
    ) %>%
    rowwise() %>%
    mutate(n = sum(!is.na(c_across(!dtxsid)))) %>%
    arrange(desc(n)) %>%
    ungroup() %>%
    inner_join(data$headers, ., join_by(dtxsid))

  return(df)
}

#' Retrieve a specific section of safety data from Cheminformatics.
#'
#' @description
#' This function retrieves a specific section of safety data for a given list of DTXSIDs
#' from the Cheminformatics API.  It supports sections like "GHS Classification",
#' "Regulatory Information", "Record Description", and "Accidental Release Measures".
#'
#' @param query A list of DTXSIDs to search for.
#' @param section The specific section of safety data to retrieve.
#'               Must be one of: 'GHS Classification', 'Regulatory Information',
#'               'Record Description', 'Regulatory Information', 'Accidental Release Measures'.
#'
#' @return No return. Aborts if there are any issues with the query or section.
#' @export
chemi_safety_section <- function(query, section = NULL) {
  if (is.null(section) | missing(section)) {
    cli::cli_abort('Missing section!')
  }

  if (
    section %ni%
      c(
        'GHS Classification',
        'Regulatory Information',
        'Record Description',
        'Regulatory Information',
        'Accidental Release Measures'
      )
  ) {
    cli::cli_abort('Wrong section request!')
  }

  if (is.null(query) | missing(query)) {
    cli::cli_abort('Request missing')
  }

  chemicals <- vector(mode = "list", length = length(query))

  cli_rule(left = "Safety section payload options")
  cli_dl(
    c(
      "Number of compounds" = "{length(query)}",
      "Section" = "{section}"
    )
  )
  cli_rule()
  cli_end()

  req_list <- map(
    query,
    ~ {
      request(
        base_url = Sys.getenv('chemi_burl')
      ) %>%
        req_url_path_append("api/resolver/pubchem-section") %>%
        req_url_query(query = .x) %>%
        req_url_query(idType = 'DTXSID') %>%
        req_url_query(section = section)
    }
  )

  resps <- req_list %>%
    req_perform_sequential(., on_error = 'continue', progress = TRUE)

  df <- resps %>%
    set_names(query) %>%
    resps_successes() %>%
    resps_data(\(resp) resp_body_json(resp)) %>%
    map(
      .,
      ~ map(
        .x,
        ~ if (is.null(.x)) {
          NA
        } else {
          .x
        }
      )
    ) %>%

    compact()

  if (length(df) > 0) {
    return(df)
  } else {
    cli::cli_alert_danger('No data found!')
    return(NULL)
  }
}

q1 <- chemi_safety_section(
  query = 'DTXSID8031865',
  section = 'Regulatory Information'
)

#' Creates a GHS table with risk bins into the Global Environment.
#'
#'
#' @return Data frame

ghs_create_tbl <- function() {
  url <- "https://pubchem.ncbi.nlm.nih.gov/ghs/ghscode_10.txt"
  lines <- readLines(url, warn = FALSE)

  # Split the lines by tab
  split_lines <- map(strsplit(lines, "\t"), ~ .x[-8])

  # Get the header
  header <- split_lines[[1]]

  # Get the data
  data <- split_lines[-1]

  # Create a data frame
  df <- as.data.frame(do.call(rbind, data), stringsAsFactors = FALSE)

  # Set column names
  colnames(df) <- header

  df <- df %>%
    filter(., str_detect(`H-Code`, pattern = "H")) %>%
    mutate(
      bin = case_when(
        `H-Code` == "H222" ~ "VH", # Aerosols
        `H-Code` == "H223" ~ "H", # Aerosols
        `H-Code` == "H229" ~ "VH", # Aerosols

        `H-Code` == "H304" ~ "VH", # Aspiration hazard
        `H-Code` == "H305" ~ "H", # Aspiration hazard

        `H-Code` == "H282" ~ "VH", # Chemicals under pressure
        `H-Code` == "H283" ~ "H", # Chemicals under pressure
        `H-Code` == "H284" ~ "H", # Chemicals under pressure

        `H-Code` == "H290" ~ "H", # Corrosive to Metals

        `H-Code` == "H314" ~ "VH", # Skin corrosion/irritation
        `H-Code` == "H315" ~ "M", # Skin corrosion/irritation
        `H-Code` == "H316" ~ "L", # Skin corrosion/irritation

        `H-Code` == "H318" ~ "VH", # Eye corrosion/irritation
        `H-Code` == "H319" ~ "M", # Eye corrosion/irritation
        `H-Code` == "H320" ~ "L", # Eye corrosion/irritation

        `H-Code` == "H315+H320" ~ "VH", # Skin corrosion/irritation and serious eye damage/eye irritation

        `H-Code` == "H200" ~ "VH", # Explosives, old; difficult to bin due to legacy category
        `H-Code` == "H201" ~ "VH", # Explosives, old
        `H-Code` == "H202" ~ "VH", # Explosives, old
        `H-Code` == "H203" ~ "VH", # Explosives, old
        `H-Code` == "H205" ~ "VH", # Explosives, old; keyword is 'may', falls under VH due to div class

        `H-Code` == "H209" ~ "VH", # Explosives
        `H-Code` == "H210" ~ "VH", # Explosives
        `H-Code` == "H211" ~ "VH", # Explosives
        `H-Code` == "H204" ~ "H", # Explosives

        `H-Code` == "H206" ~ "VH", # Desensitized explosives
        `H-Code` == "H207" ~ "VH", # Desensitized explosives
        `H-Code` == "H208" ~ "H", # Desensitized explosives

        `H-Code` == "H220" ~ "VH", # Flammable gases
        `H-Code` == "H221" ~ "VH", # Flammable gases
        `H-Code` == "H230" ~ "VH", # Flammable gases
        `H-Code` == "H231" ~ "VH", # Flammable gases
        `H-Code` == "H232" ~ "VH", # Flammable gases

        `H-Code` == "H224" ~ "VH", # Flammable liquids
        `H-Code` == "H225" ~ "VH", # Flammable liquids
        `H-Code` == "H226" ~ "H", # Flammable liquids
        `H-Code` == "H227" ~ "H", # Flammable liquids

        `H-Code` == "H228" ~ "VH", # Flammable solids

        `H-Code` == "H280" ~ "H", # Gases under pressure
        `H-Code` == "H281" ~ "H", # Gases under pressure

        `H-Code` == "H420" ~ "H", # Hazardous to the ozone layer

        `H-Code` == "H270" ~ "VH", # Oxidizing gases

        `H-Code` == "H271" ~ "VH", # Oxidizing liquids; Oxidizing solids
        `H-Code` == "H272" ~ "VH", # Oxidizing liquids; Oxidizing solids

        `H-Code` == "H250" ~ "VH", # Pyrophoric solids

        `H-Code` == "H251" ~ "VH", # Self-heating substances and mixtures
        `H-Code` == "H252" ~ "H", # Self-heating substances and mixtures

        `H-Code` == "H240" ~ "VH", # Self-reactive substances and mixtures; Organic peroxides
        `H-Code` == "H241" ~ "VH", # Self-reactive substances and mixtures; Organic peroxides
        `H-Code` == "H242" ~ "VH", # Self-reactive substances and mixtures; Organic peroxides

        `H-Code` == "H260" ~ "VH", # Substances and mixtures which in contact with water, emit flammable gases
        `H-Code` == "H261" ~ "VH", # Substances and mixtures which in contact with water, emit flammable gases

        `H-Code` == "-" ~ "I", # Self-reactive substances and mixtures, Organic peroxides, explosives

        .default = "MISSING" # should just be health and enviromental endpoints
      )
    )

  return(df)
}
