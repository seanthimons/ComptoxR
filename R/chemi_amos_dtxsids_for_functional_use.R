#' Returns a list of DTXSIDs for the given functional use.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param functional_use Functional use class.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids_for_functional_use(functional_use = "DTXSID7020182")
#' }
chemi_amos_dtxsids_for_functional_use <- function(functional_use) {
  generic_request(
    query = functional_use,
    endpoint = "amos/dtxsids_for_functional_use/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


