#' Returns a list of fact sheet IDs that are associated with the given DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_fact_sheets_for_substance(dtxsid = "DTXSID7020182")
#' }
chemi_amos_fact_sheets_for_substance <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "amos/fact_sheets_for_substance/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


