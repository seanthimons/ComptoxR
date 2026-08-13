#' Resolver Getpubchemlist
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
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getpubchemlist(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_getpubchemlist <- function(query, idType = "AnyId", section = NULL, all_pages = TRUE, max_pages = 100) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_resolver_getpubchemlist",
    "pre_request",
    list(
      params = list(
        `query` = query,
        `idType` = idType,
        `section` = section,
        `all_pages` = all_pages,
        `max_pages` = max_pages,
        `chemicals` = chemicals,
        `server` = server
      )
    )
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
  if ("all_pages" %in% names(req_data$params)) {
    all_pages <- req_data$params[["all_pages"]]
  }
  if ("max_pages" %in% names(req_data$params)) {
    max_pages <- req_data$params[["max_pages"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(section)) {
    extra_options$section <- section
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "resolver/getpubchemlist",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    server = server,
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "page_size"
  )

  # Additional post-processing can be added here

  return(result)
}
