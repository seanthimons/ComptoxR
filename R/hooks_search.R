# Search Hook Primitives
# Thin pre/post hooks over the pure helpers in chemi_search_helpers.R.
# These wire the composed chemi_search() interface into the run_hook() system.

#' Build the cheminformatics search request
#'
#' Pre-request hook that normalizes the composed `chemi_search()` arguments,
#' validates them, resolves the query to a MOL string, builds the API `params`
#' block, and assembles the `{inputType, searchType, params, query}` body.
#'
#' @param data Hook data with `params` holding the composed arguments.
#' @return Modified data with `request$body` and `request$options` populated.
#' @noRd
chemi_search_pre_request <- function(data) {
  p <- data$params

  search_type <- match.arg(
    p$search_type,
    c("exact", "substructure", "similar", "mass", "hazard", "features")
  )
  similarity_type <- match.arg(
    p$similarity_type,
    c("tanimoto", "euclid", "tversky")
  )

  # These accept the full default vector to mean "not supplied" -> NULL.
  min_toxicity <- if (length(p$min_toxicity) == 1) {
    match.arg(p$min_toxicity, c("VH", "H", "M", "L", "A"))
  } else {
    NULL
  }
  min_authority <- if (length(p$min_authority) == 1) {
    match.arg(p$min_authority, c("auth", "screen", "qsar"))
  } else {
    NULL
  }
  mass_type <- if (length(p$mass_type) == 1) {
    match.arg(p$mass_type, c("mono", "mw", "abu"))
  } else {
    NULL
  }

  validate_search_inputs(
    search_type = search_type,
    query = p$query,
    hazard_name = p$hazard_name,
    min_similarity = p$min_similarity
  )

  mol_query <- get_mol_for_search(p$query, search_type)

  params <- build_search_params(
    search_type = search_type,
    similarity_type = similarity_type,
    min_similarity = p$min_similarity,
    hazard_name = p$hazard_name,
    min_toxicity = min_toxicity,
    min_authority = min_authority,
    mass_type = mass_type,
    min_mass = p$min_mass,
    max_mass = p$max_mass,
    filter_features = p$filter_features,
    feature_filters = p$feature_filters,
    element_include = p$element_include,
    element_exclude = p$element_exclude,
    exclude_all_others = p$exclude_all_others,
    limit = p$limit
  )

  body <- list(
    inputType = "MOL",
    searchType = unname(.search_type_map[search_type]),
    params = params
  )
  if (!is.null(mol_query)) {
    body$query <- mol_query
  }

  data$request <- list(
    body = body,
    options = list(limit = p$limit)
  )
  data
}

#' Shape the cheminformatics search response
#'
#' Post-response hook that converts the raw search payload into a tibble via
#' [process_search_response()], tagging similarity results by relationship.
#'
#' @param data Hook data with `result` (raw payload) and `params$query`.
#' @return A tibble of search results.
#' @noRd
chemi_search_post_response <- function(data) {
  process_search_response(data$result, data$params$query)
}
