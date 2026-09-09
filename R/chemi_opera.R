#' Opera
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles SMILES to generate predictions for
#' @param format Format to return predictions in (json, csv, xlsx) (default: json)
#' @param standardize Standardize chemical before calculating predictions (default: FALSE)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_opera(smiles = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_opera <- function(smiles, format = "json", standardize = FALSE) {
  params <- list("smiles" = smiles, "format" = format, "standardize" = standardize)
  result <- generic_request(
    "endpoint" = "opera",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("smiles" = params[["smiles"]], "format" = params[["format"]], "standardize" = params[["standardize"]])
      )
      if (length(.body)) .body else list()
    })
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
# Generated with apipak; do not edit by hand.
chemi_opera_bulk <- function(
  cache_only = FALSE,
  smiles = NULL,
  chemicals = NULL,
  format = "json",
  standardize = FALSE
) {
  params <- list(
    "cache_only" = cache_only,
    "smiles" = smiles,
    "chemicals" = chemicals,
    "format" = format,
    "standardize" = standardize
  )
  result <- generic_chemi_request(
    "endpoint" = "opera",
    "body" = local({
      if (sum(c(!is.null(params$smiles), !is.null(params$chemicals))) != 1L || FALSE) {
        cli::cli_abort("Supply exactly one supported request-body shape.")
      }
      Filter(
        Negate(is.null),
        list(cache_only = params[["cache_only"]], smiles = params[["smiles"]], chemicals = params[["chemicals"]])
      )
    }),
    "tidy" = FALSE,
    "format" = params[["format"]],
    "standardize" = params[["standardize"]]
  )
  result
}
