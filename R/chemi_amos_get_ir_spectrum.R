#' Returns an IR spectrum by database ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_ir_spectrum()
#' }
chemi_amos_get_ir_spectrum <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_ir_spectrum/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


