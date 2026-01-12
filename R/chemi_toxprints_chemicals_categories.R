#' Toxprints Chemicals Categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_chemicals_categories(chemicals = "DTXSID7020182")
#' }
chemi_toxprints_chemicals_categories <- function(chemicals) {

  generic_chemi_request(
    query = chemicals,
    endpoint = "toxprints/chemicals_categories",
    wrap = FALSE,
    tidy = FALSE
  )
}


