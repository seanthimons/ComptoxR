#' Generate descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate groups for
#' @param model Model to use for group prediction (default: RF)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_arn_cats(smiles = "DTXSID7020182")
#' }
chemi_arn_cats <- function(smiles, model = "RF") {
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(model)) options[['model']] <- model
    result <- generic_request(
    query = NULL,
    endpoint = "arn_cats",
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




#' Generate groups for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_arn_cats_bulk()
#' }
chemi_arn_cats_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "arn_cats",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


