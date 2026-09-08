#' Returns information on a batch of fact sheets specified by internal ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_ids List of fact sheet IDs to return information on.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_retrieve_fact_sheets(internal_ids = "DTXSID7020182")
#' }
chemi_amos_retrieve_fact_sheets <- function(internal_ids = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(internal_ids)) {
    options[['internal_ids']] <- internal_ids
  }
  result <- generic_chemi_request(
    endpoint = "amos/retrieve_fact_sheets/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
