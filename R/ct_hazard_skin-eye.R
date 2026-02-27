#' Get data for a batch of DTXSID(s)
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
#' ct_hazard_skin_eye(query = "DTXSID7020182")
#' }
ct_hazard_skin_eye <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/skin-eye/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


