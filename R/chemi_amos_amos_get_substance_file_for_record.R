#' Creates an Excel workbook listing the substances in the specified record with some additional identifiers.
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
#' chemi_amos_amos_get_substance_file_for_record(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_substance_file_for_record <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_substance_file_for_record/",
    server = "chemi_burl",
    auth = FALSE
  )
}

