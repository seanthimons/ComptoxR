#' Generates an Excel workbook which lists all records in the database that contain a given set of DTXSIDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_batch()
#' }
chemi_amos_batch <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/batch_search",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


