#' List reusable unit definitions for curator editors
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_curators_units()
#' }
chemi_chet_curators_units <- function() {
  result <- generic_request(
    endpoint = "curators/units",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


