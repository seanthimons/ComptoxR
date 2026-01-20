#' Toxprints Toxprints Categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints_categories()
#' }
chemi_toxprints_toxprints_categories <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "toxprints/toxprints_categories",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


