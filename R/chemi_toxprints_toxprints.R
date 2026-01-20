#' Toxprints Toxprints
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
#' chemi_toxprints_toxprints(category = "DTXSID7020182")
#' }
chemi_toxprints_toxprints <- function(category, label = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(category)) options[['category']] <- category
  if (!is.null(label)) options[['label']] <- label
    result <- generic_request(
    query = NULL,
    endpoint = "toxprints/toxprints",
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


