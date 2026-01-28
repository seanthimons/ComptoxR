#' Returns a list of major data sources in AMOS with some supplemental information.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_data_source_info()
#' }
chemi_amos_get_data_source_info <- function() {
  result <- generic_request(
    endpoint = "amos/get_data_source_info/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


