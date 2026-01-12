#' Safety Hcodes
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_hcodes()
#' }
chemi_safety_hcodes <- function() {
  generic_request(
    query = NULL,
    endpoint = "safety/hcodes",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


