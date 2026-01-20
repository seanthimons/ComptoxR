#' Retrieves a list of methods that contain the MS-Ready forms of a given substance but not the substance itself.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_ms_ready_methods()
#' }
chemi_amos_get_ms_ready_methods <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_ms_ready_methods/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


