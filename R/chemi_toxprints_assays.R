#' Toxprints Assays
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
#' chemi_toxprints_assays(category = "DTXSID7020182")
#' }
chemi_toxprints_assays <- function(category = NULL, label = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(category)) options[['category']] <- category
  if (!is.null(label)) options[['label']] <- label
    result <- generic_request(
    endpoint = "toxprints/assays",
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




#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Optional parameter
#' @param name Optional parameter
#' @param category Optional parameter
#' @param actives Optional parameter
#' @param total Optional parameter
#' @param metrics Optional parameter
#' @param chemicals Optional parameter
#' @param labels Optional parameter
#' @param options Optional parameter
#' @param acl Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_bulk(id = c("DTXSID2044397", "DTXSID8047004", "DTXSID301054196"))
#' }
chemi_toxprints_assays_bulk <- function(id = NULL, name = NULL, category = NULL, actives = NULL, total = NULL, metrics = NULL, chemicals = NULL, labels = NULL, options = NULL, acl = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(name)) options$name <- name
  if (!is.null(category)) options$category <- category
  if (!is.null(actives)) options$actives <- actives
  if (!is.null(total)) options$total <- total
  if (!is.null(metrics)) options$metrics <- metrics
  if (!is.null(chemicals)) options$chemicals <- chemicals
  if (!is.null(labels)) options$labels <- labels
  if (!is.null(options)) options$options <- options
  if (!is.null(acl)) options$acl <- acl
  result <- generic_chemi_request(
    query = id,
    endpoint = "toxprints/assays",
    options = options,
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
#' @param name Primary query parameter. Type: string
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays(name = "DTXSID7020182")
#' }
chemi_toxprints_assays <- function(name) {
  result <- generic_request(
    query = name,
    endpoint = "toxprints/assays/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


