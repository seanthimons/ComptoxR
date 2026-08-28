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
#' @param sort Logical value controlling API result ordering (default: FALSE)
#' @param hclust_method Hierarchical clustering method passed to stats::hclust()
#' @param format Output format: cluster result, long-form similarities, or raw API response
#' @return A cluster list containing a named similarity matrix and hclust object, long-form similarity tibble, or raw API response, selected by `format`
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritymap(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_getsimilaritymap <- function(query, idType = "AnyId", section = NULL, sort = FALSE, hclust_method = "complete", format = c("cluster", "long", "raw")) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook("chemi_resolver_getsimilaritymap", "pre_request", list(params = list(`query` = query, `idType` = idType, `section` = section, `sort` = sort, `hclust_method` = hclust_method, `format` = format, `chemicals` = chemicals, `server` = server)))
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
  if ("hclust_method" %in% names(req_data$params)) {
    hclust_method <- req_data$params[["hclust_method"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(section)) extra_options$section <- section

  result <- generic_chemi_request(
    query = query,
    endpoint = "resolver/getsimilaritymap",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    sort = if (!is.null(sort)) tolower(as.character(sort)) else NULL,
    server = server
  )

  result <- run_hook("chemi_resolver_getsimilaritymap", "post_response", list(result = result, params = list(`query` = query, `idType` = idType, `section` = section, `sort` = sort, `hclust_method` = hclust_method, `format` = format)))
  # Additional post-processing can be added here

  return(result)
}
