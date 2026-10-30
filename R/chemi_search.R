#' Cheminformatics Search
#'
#' @md
#' @description
#' `r lifecycle::badge("maturing")`
#'
#' Search the cheminformatics database using various search types including exact structure, substructure, similarity, mass, hazard, and feature searches.
#' @param query Chemical identifier (DTXSID), SMILES string, or MOL file string. Required for exact, substructure, and similar searches. Can be NULL for mass, hazard, and features searches.
#' @param search_type Type of search to perform. One of: \code{"exact"} - Exact structure match \code{"substructure"} - Substructure search \code{"similar"} - Similarity search \code{"mass"} - Mass-based search \code{"hazard"} - Hazard-based search \code{"features"} - Feature-based search
#' @param similarity_type Similarity metric for similar searches. One of \code{"tanimoto"} (default), \code{"euclid"}, or \code{"tversky"}.
#' @param min_similarity Minimum similarity threshold (0-1). Defaults to 0.85.
#' @param hazard_name Hazard endpoint name for hazard searches. Use short names: \code{"acute_oral"}, \code{"acute_inhal"}, \code{"acute_dermal"}, \code{"cancer"}, \code{"geno"}, \code{"endo"}, \code{"reprod"}, \code{"develop"}, \code{"neuro_single"}, \code{"neuro_repeat"}, \code{"sys_single"}, \code{"sys_repeat"}, \code{"skin_sens"}, \code{"skin_irr"}, \code{"eye"}, \code{"aq_acute"}, \code{"aq_chron"}, \code{"persis"}, \code{"bioacc"}, \code{"expo"}.
#' @param min_toxicity Minimum toxicity level for hazard searches. One of \code{"VH"} (Very High), \code{"H"} (High), \code{"M"} (Medium), \code{"L"} (Low), or \code{"A"} (Any).
#' @param min_authority Minimum data authority level for hazard searches. One of \code{"auth"} (Authoritative), \code{"screen"} (Screening), or \code{"qsar"} (QSAR).
#' @param mass_type Type of mass for mass searches. One of \code{"mono"} (monoisotopic mass), \code{"mw"} (molecular weight), or \code{"abu"} (most abundant mass).
#' @param min_mass Minimum mass value for mass searches.
#' @param max_mass Maximum mass value for mass searches.
#' @param filter_features Logical; whether to apply feature filters. Defaults to FALSE.
#' @param feature_filters Named logical vector of feature filters to apply when \code{filter_features = TRUE}. Valid filter names: \code{"stereo"}, \code{"chiral"}, \code{"isotopes"}, \code{"charged"}, \code{"multicomponent"}, \code{"radicals"}, \code{"salts"}, \code{"polymers"}, \code{"sgroups"}.
#' @param element_include Character vector of element symbols to include in results.
#' @param element_exclude Character vector of element symbols to exclude from results.
#' @param exclude_all_others Logical; if TRUE, excludes all elements except those in \code{element_include}. Defaults to FALSE.
#' @param limit Maximum number of results to return per page. Defaults to 50.
#' @param all_pages Logical; if TRUE, automatically fetches all pages via offset/limit pagination. If FALSE (default), returns a single page.
#' @return A tibble containing search results with columns depending on search type. For similarity searches, includes a \code{relationship} column indicating \code{"parent"} (query compound) or \code{"child"} (similar compound).
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_search(query = "DTXSID7020182", search_type = "exact")
#' chemi_search(query = "DTXSID7020182", search_type = "similar", min_similarity = 0.9)
#' chemi_search(query = NULL, search_type = "mass", mass_type = "mono", min_mass = 100L, max_mass = 200L)
#' chemi_search(query = NULL, search_type = "hazard", hazard_name = "cancer", min_toxicity = "H", min_authority = "auth")
#' chemi_search(query = NULL, search_type = "features", element_include = c("C", "N", "O"), exclude_all_others = TRUE, limit = 100)
#' }
# Generated with specmill; do not edit by hand.
chemi_search <- function(
  query = NULL,
  search_type = c("exact", "substructure", "similar", "mass", "hazard", "features"),
  similarity_type = c("tanimoto", "euclid", "tversky"),
  min_similarity = 0.85,
  hazard_name = NULL,
  min_toxicity = c("VH", "H", "M", "L", "A"),
  min_authority = c("auth", "screen", "qsar"),
  mass_type = c("mono", "mw", "abu"),
  min_mass = NULL,
  max_mass = NULL,
  filter_features = FALSE,
  feature_filters = NULL,
  element_include = NULL,
  element_exclude = NULL,
  exclude_all_others = FALSE,
  limit = 50,
  all_pages = FALSE
) {
  params <- base::list(
    "query" = query,
    "search_type" = search_type,
    "similarity_type" = similarity_type,
    "min_similarity" = min_similarity,
    "hazard_name" = hazard_name,
    "min_toxicity" = min_toxicity,
    "min_authority" = min_authority,
    "mass_type" = mass_type,
    "min_mass" = min_mass,
    "max_mass" = max_mass,
    "filter_features" = filter_features,
    "feature_filters" = feature_filters,
    "element_include" = element_include,
    "element_exclude" = element_exclude,
    "exclude_all_others" = exclude_all_others,
    "limit" = limit,
    "all_pages" = function() all_pages
  )
  state <- run_hook(
    "chemi_search",
    "pre_request",
    base::list(
      params = params[c(
        "query",
        "search_type",
        "similarity_type",
        "min_similarity",
        "hazard_name",
        "min_toxicity",
        "min_authority",
        "mass_type",
        "min_mass",
        "max_mass",
        "filter_features",
        "feature_filters",
        "element_include",
        "element_exclude",
        "exclude_all_others",
        "limit"
      )]
    )
  )
  changed <- base::intersect(base::names(params), base::names(state$params))
  changed <- base::intersect(
    changed,
    c(
      "query",
      "search_type",
      "similarity_type",
      "min_similarity",
      "hazard_name",
      "min_toxicity",
      "min_authority",
      "mass_type",
      "min_mass",
      "max_mass",
      "filter_features",
      "feature_filters",
      "element_include",
      "element_exclude",
      "exclude_all_others",
      "limit"
    )
  )
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    .paging_arguments <- base::list(
      method = "POST",
      path = "/search",
      path_params = list(),
      query = list(),
      body = state[["request"]][["body"]],
      body_media = "application/json",
      headers = list(Accept = "application/json"),
      server = list(url = "https://hcd.rtpnc.epa.gov/api"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
      auth = list(),
      response_policy = ".ct_search_page_response",
      request_controls = list(preserve_errors = TRUE)
    )
    if (params[["all_pages"]]() && TRUE) {
      result <- .ct_request_pages(
        function(page) {
          base::do.call(
            base::get(".ct_request", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE),
            utils::modifyList(.paging_arguments, page, keep.null = TRUE),
            quote = TRUE
          )
        },
        parameter = c("body", "offset"),
        start = 0L,
        max_pages = 100L,
        mode = "offset",
        size_parameter = c("body", "params", "limit"),
        page_size = state[["request"]][["options"]][["limit"]],
        items = base::get(
          ".ct_search_page_items",
          envir = base::environment(.ct_request_pages),
          mode = "function",
          inherits = FALSE
        ),
        completed = base::get(
          ".ct_search_page_done",
          envir = base::environment(.ct_request_pages),
          mode = "function",
          inherits = FALSE
        ),
        advance = base::get(
          ".ct_search_page_advance",
          envir = base::environment(.ct_request_pages),
          mode = "function",
          inherits = FALSE
        ),
        error_policy = "partial",
        warn_limits = FALSE,
        warn_errors = FALSE,
        stop_on_empty = FALSE
      )
      if (!base::inherits(result, "httr2_request") && !base::is.null(result)) base::attr(result, "pagination") <- NULL
    } else {
      result <- base::do.call(
        base::get(".ct_request", envir = base::environment(.ct_request_pages), mode = "function", inherits = FALSE),
        .paging_arguments,
        quote = TRUE
      )
    }
  }
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  if (!base::isTRUE(state$skip_request)) {
    result <- base::get(
      ".ct_search_result",
      envir = base::parent.env(base::environment()),
      mode = "function",
      inherits = FALSE
    )(base::list(result = result, params = params))
  }
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  state$result <- result
  result <- run_hook("chemi_search", "post_response", state)
  result
}
