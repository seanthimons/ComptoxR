#' Hazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param full Optional parameter (default: TRUE)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard(query = "DTXSID7020182")
#' }
chemi_hazard <- function(query, full = TRUE) {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(full)) options[['full']] <- full
    result <- generic_request(
    query = NULL,
    endpoint = "hazard",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}




#' Hazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param id_type Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param options Optional parameter
#' @param empty Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_hazard_bulk <- function(query, id_type = "AnyId", options = NULL, empty = NULL) {
  # Resolve identifiers to Chemical objects
  resolved <- chemi_resolver(query = query, id_type = id_type)

  if (nrow(resolved) == 0) {
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }

  # Transform resolved tibble to Chemical object format
  # Map column names: dtxsid -> sid, etc.
  chemicals <- purrr::map(seq_len(nrow(resolved)), function(i) {
    row <- resolved[i, ]
    list(
      sid = row$dtxsid,
      smiles = row$smiles,
      casrn = row$casrn,
      inchi = row$inchi,
      inchiKey = row$inchiKey,
      name = row$name,
      mol = row$mol
    )
  })

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(options)) extra_options$options <- options
  if (!is.null(empty)) extra_options$empty <- empty

  # Build and send request
  base_url <- Sys.getenv("chemi_burl", unset = "chemi_burl")
  if (base_url == "") base_url <- "chemi_burl"

  payload <- list(chemicals = chemicals)
  if (length(extra_options) > 0) payload$options <- extra_options

  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("hazard") |>
    httr2::req_method("POST") |>
    httr2::req_body_json(payload) |>
    httr2::req_headers(Accept = "application/json")

  if (as.logical(Sys.getenv("run_debug", "FALSE"))) {
    return(httr2::req_dry_run(req))
  }

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) < 200 || httr2::resp_status(resp) >= 300) {
    cli::cli_abort("API request to {.val hazard} failed with status {httr2::resp_status(resp)}")
  }

  result <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  # Additional post-processing can be added here

  return(result)
}


