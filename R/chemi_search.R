#' Cheminformatics Search
#'
#' @description
#' `r tryCatch(lifecycle::badge("maturing"), error = function(e) lifecycle::badge("stable"))`
#'
#' Search the cheminformatics database using various search types including
#' exact structure, substructure, similarity, mass, hazard, and feature searches.
#'
#' @param query Chemical identifier (DTXSID), SMILES string, or MOL file string.
#'   Required for exact, substructure, and similar searches. Can be NULL for
#'   mass, hazard, and features searches.
#' @param search_type Type of search to perform. One of:
#'   \itemize{
#'     \item \code{"exact"} - Exact structure match
#'     \item \code{"substructure"} - Substructure search
#'     \item \code{"similar"} - Similarity search
#'     \item \code{"mass"} - Mass-based search
#'     \item \code{"hazard"} - Hazard-based search
#'     \item \code{"features"} - Feature-based search
#'   }
#' @param similarity_type Similarity metric for similar searches. One of
#'   \code{"tanimoto"} (default), \code{"euclid"}, or \code{"tversky"}.
#' @param min_similarity Minimum similarity threshold (0-1). Defaults to 0.85.
#' @param hazard_name Hazard endpoint name for hazard searches. Use short names:
#'   \code{"acute_oral"}, \code{"acute_inhal"}, \code{"acute_dermal"},
#'   \code{"cancer"}, \code{"geno"}, \code{"endo"}, \code{"reprod"},
#'   \code{"develop"}, \code{"neuro_single"}, \code{"neuro_repeat"},
#'   \code{"sys_single"}, \code{"sys_repeat"}, \code{"skin_sens"},
#'   \code{"skin_irr"}, \code{"eye"}, \code{"aq_acute"}, \code{"aq_chron"},
#'   \code{"persis"}, \code{"bioacc"}, \code{"expo"}.
#' @param min_toxicity Minimum toxicity level for hazard searches.
#'   One of \code{"VH"} (Very High), \code{"H"} (High), \code{"M"} (Medium),
#'   \code{"L"} (Low), or \code{"A"} (Any).
#' @param min_authority Minimum data authority level for hazard searches.
#'   One of \code{"auth"} (Authoritative), \code{"screen"} (Screening),
#'   or \code{"qsar"} (QSAR).
#' @param mass_type Type of mass for mass searches. One of \code{"mono"}
#'   (monoisotopic mass), \code{"mw"} (molecular weight), or \code{"abu"}
#'   (most abundant mass).
#' @param min_mass Minimum mass value for mass searches.
#' @param max_mass Maximum mass value for mass searches.
#' @param filter_features Logical; whether to apply feature filters. Defaults to FALSE.
#' @param feature_filters Named logical vector of feature filters to apply when
#'   \code{filter_features = TRUE}. Valid filter names: \code{"stereo"},
#'   \code{"chiral"}, \code{"isotopes"}, \code{"charged"}, \code{"multicomponent"},
#'   \code{"radicals"}, \code{"salts"}, \code{"polymers"}, \code{"sgroups"}.
#' @param element_include Character vector of element symbols to include in results.
#' @param element_exclude Character vector of element symbols to exclude from results.
#' @param exclude_all_others Logical; if TRUE, excludes all elements except those
#'   in \code{element_include}. Defaults to FALSE.
#' @param limit Maximum number of results to return per page. Defaults to 50.
#' @param all_pages Logical; if TRUE, automatically fetches all pages via
#'   offset/limit pagination. If FALSE (default), returns a single page.
#'
#' @return A tibble containing search results with columns depending on search type.
#'   For similarity searches, includes a \code{relationship} column indicating
#'   \code{"parent"} (query compound) or \code{"child"} (similar compound).
#'
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' # Exact search by DTXSID
#' chemi_search("DTXSID7020182", "exact")
#'
#' # Similarity search with custom threshold
#' chemi_search("DTXSID7020182", "similar", min_similarity = 0.9)
#'
#' # Mass range search
#' chemi_search(
#'   query = NULL,
#'   search_type = "mass",
#'   mass_type = "mono",
#'   min_mass = 100,
#'   max_mass = 200
#' )
#'
#' # Hazard search for carcinogenicity
#' chemi_search(
#'   query = NULL,
#'   search_type = "hazard",
#'   hazard_name = "cancer",
#'   min_toxicity = "H",
#'   min_authority = "auth"
#' )
#'
#' # Feature search with element filtering
#' chemi_search(
#'   query = NULL,
#'   search_type = "features",
#'   element_include = c("C", "N", "O"),
#'   exclude_all_others = TRUE,
#'   limit = 100
#' )
#' }
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
  req_data <- run_hook(
    "chemi_search",
    "pre_request",
    list(
      params = list(
        query = query,
        search_type = search_type,
        similarity_type = similarity_type,
        min_similarity = min_similarity,
        hazard_name = hazard_name,
        min_toxicity = min_toxicity,
        min_authority = min_authority,
        mass_type = mass_type,
        min_mass = min_mass,
        max_mass = max_mass,
        filter_features = filter_features,
        feature_filters = feature_filters,
        element_include = element_include,
        element_exclude = element_exclude,
        exclude_all_others = exclude_all_others,
        limit = limit
      )
    )
  )

  if (isTRUE(req_data$skip_request)) {
    result <- req_data$result
  } else {
    result <- generic_chemi_request(
      endpoint = "search",
      body = req_data$request$body,
      options = req_data$request$options,
      tidy = FALSE,
      paginate = all_pages,
      max_pages = 100,
      pagination_strategy = "offset_limit"
    )
  }

  post_data <- req_data
  post_data$result <- result
  run_hook("chemi_search", "post_response", post_data)
}
