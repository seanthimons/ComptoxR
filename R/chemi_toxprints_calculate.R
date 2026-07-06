#' Toxprints Calculate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param labels Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate(smiles = "DTXSID7020182")
#' }
chemi_toxprints_calculate <- function(smiles, labels = FALSE, profile = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(labels)) {
    options[['labels']] <- labels
  }
  if (!is.null(profile)) {
    options[['profile']] <- profile
  }
  result <- generic_request(
    endpoint = "toxprints/calculate",
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


#' Toxprints Calculate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param labels Optional parameter
#' @param options Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_toxprints_calculate_bulk <- function(query, idType = "AnyId", labels = NULL, options = NULL) {
  chemicals <- NULL
  req_data <- run_hook(
    "chemi_toxprints_calculate_bulk",
    "pre_request",
    list(params = list(query = query, idType = idType, labels = labels, options = options, chemicals = chemicals))
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
  if ("labels" %in% names(req_data$params)) {
    labels <- req_data$params[["labels"]]
  }
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(labels)) {
    extra_options$labels <- labels
  }
  if (!is.null(options)) {
    extra_options$options <- options
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "toxprints/calculate",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
