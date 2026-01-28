#' Get summary data for a batch of DTXSID
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
#' ct_hazard_genetox(query = c("DTXSID1024122", "DTXSID9020584", "DTXSID70963875"))
#' }
ct_hazard_genetox <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/genetox/summary/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


