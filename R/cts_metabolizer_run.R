#' Run metabolizer calculator for p-chem data.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param structure Chemical for metabolizer in smiles format. (default: CCCC)
#' @param generationLimit Number of generations for structure's transformation products. (default: 1)
#' @param transformationLibraries Optional parameter (default: hydrolysis)
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' cts_metabolizer_run(structure = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
cts_metabolizer_run <- function(structure = "CCCC", generationLimit = 1, transformationLibraries = list("hydrolysis")) {
  # Build request body
  body <- list()
  if (!is.null(structure)) {
    body$structure <- structure
  }
  if (!is.null(generationLimit)) {
    body$generationLimit <- generationLimit
  }
  if (!is.null(transformationLibraries)) {
    body$transformationLibraries <- transformationLibraries
  }

  result <- generic_cts_request(
    endpoint = "metabolizer/run",
    body = body,
    method = "POST",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
