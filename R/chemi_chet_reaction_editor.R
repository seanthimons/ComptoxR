#' Fetch curator reaction editor payload
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param reaction_id Primary query parameter. Type: string
#' @param lib_id Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_editor(reaction_id = "DTXSID7020182")
#' }
chemi_chet_reaction_editor <- function(reaction_id, lib_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(lib_id)) {
    options[['lib_id']] <- lib_id
  }
  result <- generic_request(
    query = reaction_id,
    endpoint = "reaction/editor/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
