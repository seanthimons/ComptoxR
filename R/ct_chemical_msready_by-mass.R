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
#' ct_chemical_msready_by_mass(masses = "DTXSID7020182")
#' }
ct_chemical_msready_by_mass <- function(masses, error) {
  result <- generic_request(
    query = NULL,
    endpoint = "chemical/msready/search/by-mass/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000")),
    masses = masses,
    error = error
  )

  # Additional post-processing can be added here

  return(result)
}


