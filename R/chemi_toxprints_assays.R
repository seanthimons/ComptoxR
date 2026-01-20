#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param category Required parameter
#' @param label Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays(category = "DTXSID7020182")
#' }
chemi_toxprints_assays <- function(category, label = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(category)) options[['category']] <- category
  if (!is.null(label)) options[['label']] <- label
    result <- generic_request(
    query = NULL,
    endpoint = "toxprints/assays",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}




#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_bulk()
#' }
chemi_toxprints_assays_bulk <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "toxprints/assays",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}




#' Toxprints Assays 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays()
#' }
chemi_toxprints_assays <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "toxprints/assays/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


