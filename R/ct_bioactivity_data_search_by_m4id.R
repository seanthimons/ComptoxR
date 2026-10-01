#' Get data for a batch of M4IDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_m4id_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/data/search/by-m4id/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get data by M4ID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param m4id M4ID. Type: integer
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id(m4id = "7826737")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_m4id <- function(m4id) {
  params <- base::list("m4id" = m4id)
  result <- generic_request(
    "query" = params[["m4id"]],
    "endpoint" = "bioactivity/data/search/by-m4id/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
