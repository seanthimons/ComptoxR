#' Generate descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate categories for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_cats(smiles = "DTXSID7020182")
#' }
chemi_pfas_cats <- function(smiles) {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
    result <- generic_request(
    endpoint = "pfas_cats",
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




#' Generate categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_cats_bulk(chemicals = "DTXSID7020182")
#' }
chemi_pfas_cats_bulk <- function(chemicals) {

  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "pfas_cats",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}




#' Get PFAS-CATS version information
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_cats_version()
#' }
chemi_pfas_cats_version <- function() {
  result <- generic_request(
    endpoint = "pfas_cats/version",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}




#' Get PFAS-CATS metadata
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_cats_metadata()
#' }
chemi_pfas_cats_metadata <- function() {
  result <- generic_request(
    endpoint = "pfas_cats/metadata",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


