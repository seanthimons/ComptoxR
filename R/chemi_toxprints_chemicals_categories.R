#' Toxprints Chemicals Categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_chemicals_categories(chemicals = c("DTXSID20152651", "DTXSID5064889", "DTXSID8023638"))
#' }
chemi_toxprints_chemicals_categories <- function(chemicals = NULL) {

  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "toxprints/chemicals_categories",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


