#' Resolver Getsimilaritymap
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param section Optional parameter
#' @param sort Optional logical value passed to the API query string.
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritymap(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_getsimilaritymap <- function(query, idType = "AnyId", section = NULL, sort = NULL) {
  chemicals <- NULL
  req_data <- run_hook(
    "chemi_resolver_getsimilaritymap",
    "pre_request",
    list(params = list(query = query, idType = idType, section = section, sort = sort, chemicals = chemicals))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("idType" %in% names(req_data$params)) {
    idType <- req_data$params[["idType"]]
  }
  if ("section" %in% names(req_data$params)) {
    section <- req_data$params[["section"]]
  }
  if ("sort" %in% names(req_data$params)) {
    sort <- req_data$params[["sort"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(section)) {
    extra_options$section <- section
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "resolver/getsimilaritymap",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE,
    sort = if (!is.null(sort)) tolower(as.character(sort)) else NULL
  )

  # Additional post-processing can be added here

  return(result)
}
