#' Fetch reaction detail table
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param reaction_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_table(reaction_id = "DTXSID7020182")
#' }
chemi_chet_reaction_table <- function(reaction_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(reaction_id)) options[['reaction_id']] <- reaction_id
    result <- generic_request(
    endpoint = "reaction/table",
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


