#' List details for a library
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lib_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_details(lib_id = "DTXSID7020182")
#' }
chemi_chet_reaction_details <- function(lib_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(lib_id)) options[['lib_id']] <- lib_id
    result <- generic_request(
    endpoint = "reaction/details",
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


