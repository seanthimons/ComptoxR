#' Opera
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param format format
#' @param standardize standardize
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_opera(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_opera <- function(smiles, format = "json", standardize = FALSE) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "format" = format, "standardize" = standardize),
    list(
      smiles = list(type = "string"),
      format = list(default = "json", type = "string"),
      standardize = list(default = FALSE, type = "boolean")
    ),
    .api_validation$body_value,
    c(smiles = "query", format = "query", standardize = "query")
  )
  params <- base::list("smiles" = smiles, "format" = format, "standardize" = standardize)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["format"]]) && base::any(!base::nzchar(params[["format"]]))) {
    base::stop("Empty query parameter: format")
  }
  if (base::is.character(params[["standardize"]]) && base::any(!base::nzchar(params[["standardize"]]))) {
    base::stop("Empty query parameter: standardize")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/opera",
    path_params = base::list(),
    query = base::list(
      "smiles" = params[["smiles"]],
      "format" = params[["format"]],
      "standardize" = params[["standardize"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}

#' Generate predictions for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param cache_only Return only predictions found in the response cache and list uncached inputs without running OPERA. If the persistent cache is unavailable, OPERA falls back to in-memory cache and reports misses. (default: FALSE)
#' @param smiles Optional parameter
#' @param chemicals Optional parameter
#' @param format Format to return predictions in (json, csv, xlsx) (default: json)
#' @param standardize Standardize chemical before calculating predictions (default: FALSE)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_opera_bulk(cache_only = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_opera_bulk <- function(
  cache_only = FALSE,
  smiles = NULL,
  chemicals = NULL,
  format = "json",
  standardize = FALSE
) {
  params <- base::list(
    "cache_only" = cache_only,
    "smiles" = smiles,
    "chemicals" = chemicals,
    "format" = format,
    "standardize" = standardize
  )
  result <- generic_chemi_request(
    "endpoint" = "opera",
    "body" = base::local({
      if (
        sum(c(
          all(!vapply(list(params[["smiles"]]), is.null, logical(1))),
          all(!vapply(list(params[["chemicals"]]), is.null, logical(1)))
        )) !=
          1L
      ) {
        cli::cli_abort("Supply exactly one supported request-body shape.")
      }
      base::Filter(
        base::Negate(base::is.null),
        base::list(cache_only = params[["cache_only"]], smiles = params[["smiles"]], chemicals = params[["chemicals"]])
      )
    }),
    "tidy" = FALSE,
    "format" = params[["format"]],
    "standardize" = params[["standardize"]]
  )
  result
}
