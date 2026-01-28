#' Get MS-ready chemicals for a batch of mass ranges
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param masses Required parameter
#' @param error Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_by_mass(masses = c("DTXSID90873482", "DTXSID2021731", "DTXSID90937533"))
#' }
ct_chemical_msready_by_mass <- function(masses, error) {
  # Build request body
  body <- list()
  body$masses <- masses
  body$error <- error

  result <- generic_request(
    query = NULL,
    endpoint = "chemical/msready/search/by-mass/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000")),
    body = body
  )

  # Additional post-processing can be added here

  return(result)
}


