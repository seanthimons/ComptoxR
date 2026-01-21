#' Services Smirks2rxn
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smirks Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_smirks2rxn(smirks = "DTXSID7020182")
#' }
chemi_services_smirks2rxn <- function(smirks) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smirks)) options[['smirks']] <- smirks
    result <- generic_request(
    query = NULL,
    endpoint = "services/smirks2rxn",
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


