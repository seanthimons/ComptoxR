#' Get data for a batch of DTXCIDs
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
#' ct_chemical_detail_by_dtxcid(query = "DTXSID7020182")
#' }
ct_chemical_detail_by_dtxcid <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxcid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


