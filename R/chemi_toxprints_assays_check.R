#' Toxprints Assays Check
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_check(name = "DTXSID7020182")
#' }
chemi_toxprints_assays_check <- function(name) {
  generic_request(
    endpoint = "toxprints/assays/check",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    name = name
  )
}


