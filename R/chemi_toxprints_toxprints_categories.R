#' Toxprints Toxprints Categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemical Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints_categories(chemical = "DTXSID7020182")
#' }
chemi_toxprints_toxprints_categories <- function(chemical) {

  generic_chemi_request(
    query = chemical,
    endpoint = "toxprints/toxprints_categories",
    wrap = FALSE,
    tidy = FALSE
  )
}


