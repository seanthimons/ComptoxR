#' Returns information on a batch of product declarations specified by internal ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_ids List of product declaration IDs to return information on.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_retrieve_product_declarations(internal_ids = "DTXSID7020182")
#' }
chemi_amos_retrieve_product_declarations <- function(internal_ids = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(internal_ids)) {
    options[['internal_ids']] <- internal_ids
  }
  result <- generic_chemi_request(
    endpoint = "amos/retrieve_product_declarations/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
