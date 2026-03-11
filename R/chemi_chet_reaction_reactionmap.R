#' Build reaction map
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Optional parameter
#' @param searchtype Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_reactionmap(id = "DTXSID7020182")
#' }
chemi_chet_reaction_reactionmap <- function(id = NULL, searchtype = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(id)) options[['id']] <- id
  if (!is.null(searchtype)) options[['searchtype']] <- searchtype
    result <- generic_request(
    endpoint = "reaction/reactionmap",
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


