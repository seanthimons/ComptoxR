#' Creates an Excel workbook listing the substances in the specified record with some additional identifiers.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_substance_file_for_record()
#' }
chemi_amos_get_substance_file_for_record <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_substance_file_for_record/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


