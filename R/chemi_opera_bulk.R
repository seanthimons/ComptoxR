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
#' chemi_opera_bulk(smiles = c("CCO", "CCCC"), cache_only = TRUE)
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
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/opera",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list("format" = params[["format"]], "standardize" = params[["standardize"]]),
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
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = ".ct_prediction"
  )
  result
}
