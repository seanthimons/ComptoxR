#' Reaction stats and filters
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param parent_id Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database_stats(parent_id = "DTXSID7020182")
#' }
chemi_chet_reaction_database_stats <- function(parent_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(parent_id)) options[['parent_id']] <- parent_id
    result <- generic_request(
    endpoint = "reaction/database/stats",
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


