#' Returns a list of categories for the specified level of ClassyFire classification, given the higher levels of classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_amos_next_level_classification(query = "DTXSID7020182")
#' }
chemi_amos_amos_next_level_classification <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/next_level_classification/",
    server = "chemi_burl",
    auth = FALSE
  )
}

