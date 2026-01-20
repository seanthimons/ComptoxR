#' Returns a list of functional use classifications for a substance.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_functional_uses_for_dtxsid()
#' }
chemi_amos_functional_uses_for_dtxsid <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/functional_uses_for_dtxsid/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


