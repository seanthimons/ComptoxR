#' List reusable detail sets with their detail definitions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_curators_detail_sets()
#' }
chemi_chet_curators_detail_sets <- function() {
  result <- generic_request(
    endpoint = "curators/detail-sets",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


