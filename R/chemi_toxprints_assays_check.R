#' Toxprints Assays Check
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_check(name = "DTXSID7020182")
#' }
chemi_toxprints_assays_check <- function(name) {
  # Collect optional parameters
  options <- list()
  if (!is.null(name)) options[['name']] <- name
    result <- generic_request(
    query = NULL,
    endpoint = "toxprints/assays/check",
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


