#' Toxprints Toxprints Categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemical Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints_categories(chemical = c("DTXSID90893948", "DTXSID3033511", "DTXSID20964832"))
#' }
chemi_toxprints_toxprints_categories <- function(chemical = NULL) {

  result <- generic_chemi_request(
    query = chemical,
    endpoint = "toxprints/toxprints_categories",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


