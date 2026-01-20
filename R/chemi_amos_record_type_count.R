#' Returns the number of records of the given type.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_type_count()
#' }
chemi_amos_record_type_count <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/record_type_count/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


