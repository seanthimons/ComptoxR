#' Get MS-ready chemicals for a batch of mass ranges
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param error Required parameter
#' @param masses Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass_bulk(error = "DTXSID1024122")
#' }
ct_chemical_msready_search_by_mass_bulk <- function(error, masses) {

  # Build request body
  request_body <- list()
  request_body$error <- error
  request_body$masses <- masses
  result <- generic_request(
    query = NULL,
    endpoint = "chemical/msready/search/by-mass/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000")),
    body = request_body
  )

  # Additional post-processing can be added here

  return(result)
}
