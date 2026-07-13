#' Return details attached to a library through detail sets for ChemReg reaction editor
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lib_id Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_editor_library_details(lib_id = "DTXSID7020182")
#' }
chemi_chet_reaction_editor_library_details <- function(lib_id) {
  # Collect optional parameters
  options <- list()
  if (!is.null(lib_id)) options[['lib_id']] <- lib_id
    result <- generic_request(
    endpoint = "reaction/editor/library-details",
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


