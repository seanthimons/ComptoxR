#' Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints <- function(smiles, headers = FALSE, profile = NULL) {
  params <- base::list("smiles" = smiles, "headers" = headers, "profile" = profile)
  result <- generic_request(
    "endpoint" = "toxprints",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list("smiles" = params[["smiles"]], "headers" = params[["headers"]], "profile" = params[["profile"]])
      )
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}

#' Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of strings to send in request body
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "toxprints",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}
