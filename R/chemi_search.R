#' Cheminformatics Search
#'
#' Searching function that interfaces with the Cheminformatics API. Sends POST request.
#'
#' @param query Takes a list of variables (such as DTXSIDs, CASRN, names, etc.) to search by.
#' @param coerce Boolean variable to coerce list to a data.frame. Defaults to `FALSE`.
#' @param searchType string
#' @param similarity_type string
#' @param min_similarity string
#' @param min_toxicity string
#' @param min_auth string
#' @param hazard_name string
#' @param filter_results Boolean to restrict the data returned.
#' @param filter_inc A list of feature subtypes to include. Searches by `AND` operation
#' @param element_inc A vector of elements to include.
#' @param element_exc A vector of elements to exclude, or the option of `ALL` to exclude every element EXCEPT the searched elements.
#' @param mass_type string
#' @param min_mass string
#' @param max_mass string
#' @param debug string
#' @param ... string
#'
#' @return A dataframe
#' @export

chemi_search <- function(
  query,
  searchType = c(
    "exact",
    "substruture",
    "similar",
    "mass",
    "hazard",
    "features"
  ),
  similarity_type = c("tanimoto", "euclid", "tversky"),
  min_similarity = NULL,
  min_toxicity = c("VH", "H", "M", "L", "A"),
  min_auth = c("auth", "screen", "qsar"),
  hazard_name = c(
    "acute_oral",
    "acute_inhal",
    "acute_dermal",
    "cancer",
    "geno",
    "endo",
    "reprod",
    "develop",
    "neuro_single",
    "neuro_repeat",
    "sys_single",
    "sys_repeat",
    "skin_sens",
    "skin_irr",
    "eye",
    "aq_acute",
    "aq_chron",
    "persis",
    "bioacc",
    "expo"
  ),
  filter_results = FALSE,
  filter_inc = list(
    "stereo",
    "chiral",
    "isotopes",
    "charged",
    "multicomponent",
    "radicals",
    "salts",
    "polymers",
    "sgroups"
  ),
  element_inc = NULL,
  element_exc = NULL,
  mass_type = c("mono", "mw", "abu"),
  min_mass = NULL,
  max_mass = NULL,
  debug = F,
  ...
) {
  # searchType --------------------------------------------------------------

  if (missing(searchType) | is.null(searchType) | length(searchType) > 1) {
    cli_abort("Missing searchType!")
  } else {
    searchType <- case_when(
      searchType == "exact" ~ "EXACT",
      searchType == "substructure" ~ "SUBSTRUCTURE",
      searchType == "similar" ~ "SIMILAR",
      searchType == "toxprints" ~ "TOXPRINTS",
      searchType == "hazard" ~ "HAZARD",
      searchType == "mass" ~ "MASS",
      searchType == "features" ~ "FEATURES"
    )
  }

  # query -------------------------------------------------------------------

  if (missing(query) == TRUE) {
    query <- NULL
  }

  query_string <- query

  if (searchType %in% c("HAZARD", "FEATURES")) {
    mass_type <- "mono" # seems to be always needed?
    query <- "\n  Ketcher  4112412132D 1   1.00000     0.00000     0\n\n  0  0  0     0  0            999 V2000\nM  END\n"
  } else {
    if (searchType %in% c("MASS")) {
      query <- NULL
    } else {
      cli_alert_info(paste0("Grabbing MOL file for {query}"))
    }
    query <- ct_file(query = query)
    mass_type <- "mono" # seems to be always needed?
  }

  # records -----------------------------------------------------------------

  records <- 51L

  # similarity --------------------------------------------------------------

  if (missing(similarity_type)) {
    similarity_type <- "tanimoto"
  }

  similarity_type <-
    case_when(
      similarity_type == "tanimoto" ~ "tanimoto",
      similarity_type == "euclid" ~ "euclid-sub",
      similarity_type == "tversky" ~ "tversky",
    )

  min_sim <- if (is.null(min_similarity)) {
    0.85
  } else {
    as.numeric(min_similarity)
  }

  # mass --------------------------------------------------------------------

  if (searchType == "mass" & length(mass_type) > 1) {
    cli_abort("Missing mass search type!")
  } else {
    mass_type <- case_when(
      mass_type == "mono" ~ "monoisotopic-mass",
      mass_type == "mw" ~ "moleculuar-weight",
      mass_type == "abu" ~ "most-abundant-mass",
    )
  }

  # toxicity ----------------------------------------------------------------

  min_toxicity <-
    if (missing(min_toxicity) | is.null(min_toxicity)) {
      NULL
    } else {
      match.arg(min_toxicity, c("VH", "H", "M", "L", "A"))
    }

  # auth --------------------------------------------------------------------

  if (length(min_auth) > 1) {
    min_auth <- NULL
  } else {
    min_auth <- case_when(
      min_auth == "auth" ~ "Authoritative",
      min_auth == "screen" ~ "Screening",
      min_auth == "qsar" ~ "QSAR"
    )
  }

  # hazard endpoint ---------------------------------------------------------

  if (missing(hazard_name)) {
    hazard_name <- NULL
  }

  hazard_name <-
    case_when(
      hazard_name == "acute_oral" ~ "Acute Mammalian Toxicity Oral",
      hazard_name == "acute_inhal" ~ "Acute Mammalian Toxicity Inhalation",
      hazard_name == "acute_dermal" ~ "Acute Mammalian Toxicity Dermal",
      hazard_name == "cancer" ~ "Carcinogenicity",
      hazard_name == "geno" ~ "Genotoxicity Mutagenicity",
      hazard_name == "endo" ~ "Endocrine Disruption",
      hazard_name == "reprod" ~ "Reproductive",
      hazard_name == "develop" ~ "Developmental",
      hazard_name == "neuro_single" ~ "Neurotoxicity	",
      hazard_name == "neuro_repeat" ~ "Neurotoxicity Repeat Exposure",
      hazard_name == "sys_single" ~ "Systemic Toxicity Single Exposure",
      hazard_name == "sys_repeat" ~ "Systemic Toxicity Repeat Exposure",
      hazard_name == "skin_sens" ~ "Skin Sensitization",
      hazard_name == "skin_irr" ~ "Skin Irritation",
      hazard_name == "eye" ~ "Eye Irritation",
      hazard_name == "aq_acute" ~ "Acute Aquatic Toxicity",
      hazard_name == "aq_chron" ~ "Chronic Aquatic Toxicity",
      hazard_name == "persis" ~ "Persistence",
      hazard_name == "bioacc" ~ "Bioaccumulation",
      hazard_name == "expo" ~ "Exposure"
    )

  # features -----------------------------------------------------------------

  if (searchType == 'FEATURES' & filter_results == FALSE) {
    cli_alert_warning('WARNING: Missing feature filters!')
    filt_list <- list(NULL)
  }

  if (filter_results == FALSE & searchType != 'FEATURES') {
    # cli_alert('No filter')
    filt_list <- list(NULL)
  } else {
    if (searchType == 'FEATURES' & filter_results == TRUE) {
      # cli_alert('Filtering')
      filt_list <- list(
        "charged",
        "chiral",
        "isotopes",
        "multicomponent",
        "polymers",
        "radicals",
        "salts",
        "sgroups",
        "stereo"
      )

      filt_list <- map(filter_inc, ~ is.element(., filt_list)) %>%
        set_names(., ~ paste0("filter-", filter_inc))
    }
  }

  # elements ----------------------------------------------------------------
  ## include ----------------------------------------------------------------

  if (!is.null(element_inc)) {
    element_inc_orig <- element_inc
    element_inc <- paste(element_inc, collapse = ",")
  }
  ## exclude ----------------------------------------------------------------

  if (is.null(element_exc)) {
    #print('No exlusion')
    element_exc <- NULL
  } else {
    if (is.character(element_exc) & element_exc != 'ALL') {
      # print(element_exc)
      element_exc <- paste(element_exc, collapse = " ,")
    } else {
      if (element_exc == 'ALL') {
        #print("Exlude all")
        element_exc <- ComptoxR::pt$elements %>%
          filter(., !c(Symbol %in% element_inc_orig)) %>%
          filter(., as.numeric(Number) <= 103) %>%
          select(Symbol) %>%
          unique() %>%
          unlist() %>%
          sort() %>%
          paste0(., collapse = ", ")
        #print(element_exc)
      }
    }
  }

  # payload -----------------------------------------------------------------

  params <- list(
    `limit` = 50,
    `similarity-type` = similarity_type,
    `min-similarity` = min_sim,
    `min-toxicity` = min_toxicity,
    `min-authority` = min_auth,
    `hazard-name` = hazard_name,
    `include-elements` = element_inc,
    `exclude-elements` = element_exc,
    `mass-type` = mass_type,
    `min-mass` = min_mass,
    `max-mass` = max_mass
  ) %>%
    append(filt_list) %>%
    compact()

  payload <- list(
    "inputType" = "MOL",
    "searchType" = searchType,
    "params" = params,
    "query" = query
  ) %>%
    compact()

  # payload alert -----------------------------------------------------------

  cli_text('\n')
  cli_rule(left = "Payload options")
  cli_dl(
    c(
      "Search type" = "{searchType}",
      "Similarity type" = "{similarity_type}",
      "Minimum simularity" = "{min_sim}",
      "Minimum toxicity" = "{min_toxicity}"
      # "Params" = "{params}"
    )
  )
  cli_rule()

  # request -----------------------------------------------------------------

  response <- POST(
    url = paste0(Sys.getenv("chemi_burl"), "api/search"),
    body = payload,
    content_type("application/json"),
    #accept("*/*"),
    encode = "json",
    progress()
  )

  if (response$status_code == 200) {
    df <- content(response, "text", encoding = "UTF-8") %>%
      fromJSON(simplifyVector = FALSE)

    trc <- df$totalRecordsCount

    df <- df %>%
      pluck(., 'records') %>%
      map(., as_tibble) %>%
      list_rbind()

    if ('similarity' %in% colnames(df)) {
      df <- df %>%
        mutate(
          relationship = case_when(
            sid == query_string ~ 'parent',
            .default = 'child'
          )
        )
    } else {
      df
    }

    cli_alert_success('{trc} compounds found!')
  } else {
    cli_alert_danger("\nBad request at search!")
  }

  # debug -------------------------------------------------------------------

  if (debug == TRUE) {
    data <- list()
    data$payload <- payload
    data$response <- response
    data$content <- df
    return(data)
  } else {
    return(df)
  }
}
