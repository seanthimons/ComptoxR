#' Hazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param full Optional parameter (default: TRUE)
#' @param format Output format. One of "compact", "tidy", or "raw".
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard(query = "DTXSID7020182")
#' }
chemi_hazard <- function(query, full = TRUE, format = c("compact", "tidy", "raw")) {
  format <- match.arg(format)

  # Collect optional parameters
  options <- list()
  if (!is.null(query)) {
    options[['query']] <- query
  }
  if (!is.null(full)) {
    options[['full']] <- full
  }
  result <- generic_request(
    endpoint = "hazard",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  result <- run_hook(
    "chemi_hazard",
    "post_response",
    list(result = result, params = list(query = query, full = full, format = format))
  )
  # Additional post-processing can be added here

  return(result)
}


#' Hazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param options Optional parameter
#' @param empty Optional parameter
#' @param format Output format. One of "compact", "tidy", or "raw".
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_hazard_bulk <- function(
  query,
  idType = "AnyId",
  options = NULL,
  empty = NULL,
  format = c("compact", "tidy", "raw")
) {
  format <- match.arg(format)

  chemicals <- NULL
  req_data <- run_hook(
    "chemi_hazard_bulk",
    "pre_request",
    list(
      params = list(
        query = query,
        idType = idType,
        options = options,
        empty = empty,
        format = format,
        chemicals = chemicals
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
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("empty" %in% names(req_data$params)) {
    empty <- req_data$params[["empty"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(options)) {
    extra_options$options <- options
  }
  if (!is.null(empty)) {
    extra_options$empty <- empty
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "hazard",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  result <- run_hook(
    "chemi_hazard_bulk",
    "post_response",
    list(
      result = result,
      params = list(query = query, idType = idType, options = options, empty = empty, format = format)
    )
  )
  # Additional post-processing can be added here

  return(result)
}
