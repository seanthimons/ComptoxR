#' Get httk data for a batch of DTXSIDs
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
#' ct_exposure_httk(query = c("DTXSID9064922", "DTXSID00330354", "DTXSID30203567"))
#' }
ct_exposure_httk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "exposure/httk/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


