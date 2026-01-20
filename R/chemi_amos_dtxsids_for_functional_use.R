#' Returns a list of DTXSIDs for the given functional use.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids_for_functional_use()
#' }
chemi_amos_dtxsids_for_functional_use <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/dtxsids_for_functional_use/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


