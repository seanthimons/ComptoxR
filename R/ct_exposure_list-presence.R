#' Get List Presence data for a batch of DTXSIDs
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
#' ct_exposure_list_presence(query = c("DTXSID8023638", "DTXSID1049641", "DTXSID9024938"))
#' }
ct_exposure_list_presence <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "exposure/list-presence/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


