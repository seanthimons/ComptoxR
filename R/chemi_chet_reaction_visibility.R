#' Update curator-editable reaction visibility
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param reaction_id Required parameter
#' @param internal_only Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_visibility(reaction_id = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_chet_reaction_visibility <- function(reaction_id, internal_only) {
  # Build options list for additional parameters
  options <- list()
  options$internal_only <- internal_only
  result <- generic_chemi_request(
    query = reaction_id,
    endpoint = "reaction/visibility",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
