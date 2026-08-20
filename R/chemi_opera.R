#' Opera
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @param format Format to return predictions in (json, csv, xlsx) (default: json)
#' @param standardize Standardize chemical before calculating predictions (default: FALSE)
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_opera(smiles = "DTXSID7020182")
#' }
chemi_opera <- function(smiles, format = "json", standardize = FALSE) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_opera",
    "pre_request",
    list(params = list(`smiles` = smiles, `format` = format, `standardize` = standardize, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("standardize" %in% names(req_data$params)) {
    standardize <- req_data$params[["standardize"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(format)) {
    options[['format']] <- format
  }
  if (!is.null(standardize)) {
    options[['standardize']] <- standardize
  }
  result <- generic_request(
    endpoint = "opera",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}

#' Generate predictions for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param cache_only Return only predictions found in the response cache and list uncached inputs without running OPERA. If the persistent cache is unavailable, OPERA falls back to in-memory cache and reports misses. (default: FALSE)
#' @param smiles Optional parameter
#' @param chemicals Optional parameter
#' @param format Format to return predictions in (json, csv, xlsx) (default: json)
#' @param standardize Standardize chemical before calculating predictions (default: FALSE)
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_opera_bulk(cache_only = "DTXSID1024122")
#' }
chemi_opera_bulk <- function(
  cache_only = FALSE,
  smiles = NULL,
  chemicals = NULL,
  format = "json",
  standardize = FALSE
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_opera_bulk",
    "pre_request",
    list(
      params = list(
        `cache_only` = cache_only,
        `smiles` = smiles,
        `chemicals` = chemicals,
        `format` = format,
        `standardize` = standardize,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("cache_only" %in% names(req_data$params)) {
    cache_only <- req_data$params[["cache_only"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("standardize" %in% names(req_data$params)) {
    standardize <- req_data$params[["standardize"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  if (
    sum(c(all(!vapply(list(smiles), is.null, logical(1))), all(!vapply(list(chemicals), is.null, logical(1))))) != 1L
  ) {
    cli::cli_abort("Supply exactly one supported request-body shape.")
  }
  request_body <- Filter(
    Negate(is.null),
    list(cache_only = cache_only, smiles = smiles, chemicals = chemicals)
  )
  result <- generic_chemi_request(
    endpoint = "opera",
    body = request_body,
    tidy = FALSE,
    server = server,
    format = format,
    standardize = standardize
  )

  # Additional post-processing can be added here

  return(result)
}
