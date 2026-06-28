#' Batch search reactions and chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids Required parameter
#' @param search_level Required parameter. Options: chemical, reaction
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_batchsearch(dtxsids = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_chet_reaction_batchsearch <- function(dtxsids, search_level) {
  # Build options list for additional parameters
  options <- list()
  options$search_level <- search_level
  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "reaction/batchsearch",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
