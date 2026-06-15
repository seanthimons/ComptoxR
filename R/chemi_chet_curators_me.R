#' Return current curator session
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_curators_me()
#' }
chemi_chet_curators_me <- function() {
  result <- generic_request(
    endpoint = "curators/me",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


