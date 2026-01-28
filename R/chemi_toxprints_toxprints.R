#' Toxprints Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param category Optional parameter
#' @param label Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints(category = "DTXSID7020182")
#' }
chemi_toxprints_toxprints <- function(category = NULL, label = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(category)) options[['category']] <- category
  if (!is.null(label)) options[['label']] <- label
    result <- generic_request(
    endpoint = "toxprints/toxprints",
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


