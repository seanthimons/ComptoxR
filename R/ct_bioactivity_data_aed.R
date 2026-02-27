#' Get AED data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_aed(query = "DTXSID7020182")
#' }
ct_bioactivity_data_aed <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/data/aed/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


