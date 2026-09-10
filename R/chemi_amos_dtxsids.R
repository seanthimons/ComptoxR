#' Returns substance information and record counts for a list of DTXSIDs.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsids Array of DTXSIDs as strings.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids(dtxsids = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_dtxsids <- function(dtxsids = NULL) {
  params <- list("dtxsids" = dtxsids)
  result <- generic_chemi_request(
    "query" = params[["dtxsids"]],
    "endpoint" = "amos/dtxsids/",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
