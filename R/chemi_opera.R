#' Opera
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @param format Format to return predictions in (json, csv, xlsx) (default: json)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_opera(smiles = "DTXSID7020182")
#' }
chemi_opera <- function(smiles, format = "json") {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(format)) options[['format']] <- format
    result <- generic_request(
    endpoint = "opera",
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




#' Generate predictions for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_opera_bulk(smiles = "DTXSID7020182")
#' }
chemi_opera_bulk <- function(smiles) {

  result <- generic_chemi_request(
    query = smiles,
    endpoint = "opera",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


