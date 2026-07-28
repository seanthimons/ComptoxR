#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param category Optional parameter
#' @param label Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays(category = "DTXSID7020182")
#' }
chemi_toxprints_assays <- function(category = NULL, label = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(category)) {
    options[['category']] <- category
  }
  if (!is.null(label)) {
    options[['label']] <- label
  }
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
#' @param acl Optional parameter
#' @param actives Optional parameter
#' @param category Optional parameter
#' @param chemicals Optional parameter
#' @param id Optional parameter
#' @param labels Optional parameter
#' @param metrics Optional parameter
#' @param name Optional parameter
#' @param options Optional parameter
#' @param total Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_bulk(acl = "DTXSID1024122")
#' }
chemi_toxprints_assays_bulk <- function(
  acl = NULL,
  actives = NULL,
  category = NULL,
  chemicals = NULL,
  id = NULL,
  labels = NULL,
  metrics = NULL,
  name = NULL,
  options = NULL,
  total = NULL
) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(actives)) {
    options$actives <- actives
  }
  if (!is.null(category)) {
    options$category <- category
  }
  if (!is.null(chemicals)) {
    options$chemicals <- chemicals
  }
  if (!is.null(id)) {
    options$id <- id
  }
  if (!is.null(labels)) {
    options$labels <- labels
  }
  if (!is.null(metrics)) {
    options$metrics <- metrics
  }
  if (!is.null(name)) {
    options$name <- name
  }
  if (!is.null(options)) {
    options$options <- options
  }
  if (!is.null(total)) {
    options$total <- total
  }
  result <- generic_chemi_request(
    query = acl,
    endpoint = "toxprints/assays",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
