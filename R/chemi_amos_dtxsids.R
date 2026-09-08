#' Returns substance information and record counts for a list of DTXSIDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids Array of DTXSIDs as strings.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids(dtxsids = "DTXSID1024122")
#' }
chemi_amos_dtxsids <- function(dtxsids = NULL) {
  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "amos/dtxsids/",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
