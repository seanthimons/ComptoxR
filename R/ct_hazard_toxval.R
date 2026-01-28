#' Get data for a batch of DTXSID(s).
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
#' ct_hazard_toxval(query = c("DTXSID30203567", "DTXSID30197038", "DTXSID30997772"))
#' }
ct_hazard_toxval <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/toxval/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


