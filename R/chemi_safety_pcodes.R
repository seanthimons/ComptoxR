#' Safety Pcodes
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_pcodes()
#' }
chemi_safety_pcodes <- function() {
  generic_request(
    query = NULL,
    endpoint = "safety/pcodes",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


