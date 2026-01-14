#' Cheminformatics Search
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
#' @param limit Maximum number of results to return. Defaults to 50.
#'
#' @return A tibble containing search results with columns depending on search type.
#'   For similarity searches, includes a \code{relationship} column indicating
#'   \code{"parent"} (query compound) or \code{"child"} (similar compound).
#'
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
    limit = 50
) {
  # 1. Match and validate arguments
  search_type <- match.arg(search_type)
  similarity_type <- match.arg(similarity_type)

  # Only match these if they're single values (not using defaults)
  if (!missing(min_toxicity) && length(min_toxicity) == 1) {
    min_toxicity <- match.arg(min_toxicity)
  } else {
    min_toxicity <- NULL
  }

  if (!missing(min_authority) && length(min_authority) == 1) {
    min_authority <- match.arg(min_authority)
  } else {
    min_authority <- NULL
  }

  if (!missing(mass_type) && length(mass_type) == 1) {
    mass_type <- match.arg(mass_type)
  } else {
    mass_type <- NULL
  }

  # 2. Validate inputs
  validate_search_inputs(
    search_type = search_type,
    query = query,
    hazard_name = hazard_name,
    min_similarity = min_similarity
  )

  # 3. Get MOL representation for the query
  mol_query <- get_mol_for_search(query, search_type)

  # 4. Build search parameters
  params <- build_search_params(
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

  # 5. Verbose payload display
  if (as.logical(Sys.getenv("run_verbose", "FALSE"))) {
    cli::cli_text("\n")
    cli::cli_rule(left = "Payload options")
    cli::cli_dl(c(list("Search type" = search_type), params))
    cli::cli_rule()
  }

  # 6. Make the API request
  response <- generic_search_request(
    search_type = .search_type_map[search_type],
    input_type = "MOL",
    query = mol_query,
    params = params
  )

  # 7. Process and return results
  process_search_response(response, query)
}
#' Search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param searchType Required parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param inputType Optional parameter. Options: UNKNOWN, AUTO, MOL, RXN, SDF, RDF, SMI, SMILES, SMIRKS, CSV, TSV, JSON, XLSX, TXT, MSP
#' @param query Optional parameter
#' @param smiles Optional parameter
#' @param querySmiles Optional parameter
#' @param offset Optional parameter
#' @param limit Optional parameter
#' @param sortBy Optional parameter
#' @param sortDirection Optional parameter
#' @param params Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search(searchType = c("DTXSID70198443", "DTXSID80161401", "DTXSID2023270"))
#' }
chemi_search <- function(searchType, inputType = NULL, query = NULL, smiles = NULL, querySmiles = NULL, offset = NULL, limit = NULL, sortBy = NULL, sortDirection = NULL, params = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(inputType)) options$inputType <- inputType
  if (!is.null(query)) options$query <- query
  if (!is.null(smiles)) options$smiles <- smiles
  if (!is.null(querySmiles)) options$querySmiles <- querySmiles
  if (!is.null(offset)) options$offset <- offset
  if (!is.null(limit)) options$limit <- limit
  if (!is.null(sortBy)) options$sortBy <- sortBy
  if (!is.null(sortDirection)) options$sortDirection <- sortDirection
  if (!is.null(params)) options$params <- params
  result <- generic_chemi_request(
    query = searchType,
    endpoint = "search",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


