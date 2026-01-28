#' Get assay annotations for a batch of AEIDs
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
#' ct_bioactivity_assay_by_aeid(query = c("DTXSID5064889", "DTXSID3033511", "DTXSID60570416"))
#' }
ct_bioactivity_assay_by_aeid <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/assay/search/by-aeid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


