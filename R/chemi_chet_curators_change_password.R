#' Change the logged-in curator password
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param current_password Required parameter
#' @param new_password Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_curators_change_password(current_password = "old-password")
#' }
chemi_chet_curators_change_password <- function(current_password, new_password) {
  # Build options list for additional parameters
  options <- list()
  options$new_password <- new_password
  result <- generic_chemi_request(
    query = current_password,
    endpoint = "curators/change-password",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
