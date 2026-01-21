#' Returns the top four levels of a ClassyFire classification of a given substance.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_classification_for_dtxsid()
#' }
chemi_amos_get_classification_for_dtxsid <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_classification_for_dtxsid/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


