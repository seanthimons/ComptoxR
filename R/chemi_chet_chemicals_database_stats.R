#' Chemical stats and library names
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param total Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database_stats(total = "DTXSID7020182")
#' }
chemi_chet_chemicals_database_stats <- function(total = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(total)) options[['total']] <- total
    result <- generic_request(
    endpoint = "chemicals/database/stats",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


