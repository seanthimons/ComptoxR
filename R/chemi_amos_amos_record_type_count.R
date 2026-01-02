#' Returns the number of records of the given type.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_amos_record_type_count(query = "DTXSID7020182")
#' }
chemi_amos_amos_record_type_count <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/record_type_count/",
    server = "chemi_burl",
    auth = FALSE
  )
}

