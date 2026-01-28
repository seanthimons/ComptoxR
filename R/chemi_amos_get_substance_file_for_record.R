#' Creates an Excel workbook listing the substances in the specified record with some additional identifiers.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the record of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_substance_file_for_record(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_substance_file_for_record <- function(internal_id) {
  result <- generic_request(
    query = internal_id,
    endpoint = "amos/get_substance_file_for_record/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


