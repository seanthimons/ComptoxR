#' Resolver Pubchem Section
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param section Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_pubchem_section(query = "DTXSID7020182")
#' }
chemi_resolver_pubchem_section <- function(query, idType = "AnyId", section = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) {
    options[['query']] <- query
  }
  if (!is.null(idType)) {
    options[['idType']] <- idType
  }
  if (!is.null(section)) {
    options[['section']] <- section
  }
  result <- generic_request(
    endpoint = "resolver/pubchem-section",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


#' Resolver Pubchem Section
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
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_pubchem_section_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_pubchem_section_bulk <- function(query, idType = "AnyId", section = NULL) {
  chemicals <- NULL
  req_data <- run_hook(
    "chemi_resolver_pubchem_section_bulk",
    "pre_request",
    list(params = list(query = query, idType = idType, section = section, chemicals = chemicals))
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
    endpoint = "resolver/pubchem-section",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
