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
#' ct_chemical_extra_data(query = c("DTXSID3039242", "DTXSID801027235", "DTXSID2046541"))
#' }
ct_chemical_extra_data <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/extra-data/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


