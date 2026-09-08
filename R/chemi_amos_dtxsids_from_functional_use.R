#' Returns all substances associated with the specified functional use classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param functional_use Functional use classification to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids_from_functional_use(functional_use = "DTXSID7020182")
#' }
chemi_amos_dtxsids_from_functional_use <- function(functional_use) {
  result <- generic_request(
    query = functional_use,
    endpoint = "amos/dtxsids_from_functional_use/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
