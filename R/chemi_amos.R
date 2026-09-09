#' Retrieves a list of records from the database that contain a searched DTXSID.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos(dtxsid = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "amos/search/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
