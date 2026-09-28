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
#' @apiStage public
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
    format = format,
    standardize = standardize
  )

  # Additional post-processing can be added here

  return(result)
}
