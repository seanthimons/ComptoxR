#' Get detailed data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_genetox_details(query = c("DTXSID901336271", "DTXSID10161156", "DTXSID5029683"))
#' }
ct_hazard_genetox_details <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/genetox/details/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


