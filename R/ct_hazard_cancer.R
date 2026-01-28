#' Get data for a batch of DTXSIDs
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
#' ct_hazard_cancer(query = c("DTXSID50182047", "DTXSID80218080", "DTXSID80143348"))
#' }
ct_hazard_cancer <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/cancer-summary/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


