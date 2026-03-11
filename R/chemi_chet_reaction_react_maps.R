#' List maps for a reaction
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param react_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_react_maps(react_id = "DTXSID7020182")
#' }
chemi_chet_reaction_react_maps <- function(react_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(react_id)) options[['react_id']] <- react_id
    result <- generic_request(
    endpoint = "reaction/react_maps",
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


