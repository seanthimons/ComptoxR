#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param category Required parameter
#' @param label Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays(category = "DTXSID7020182")
#' }
chemi_toxprints_assays <- function(category, label = NULL) {
  generic_request(
    endpoint = "toxprints/assays",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    category = category,
    label = label
  )
}




#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Required parameter
#' @param name Optional parameter
#' @param category Optional parameter
#' @param actives Optional parameter
#' @param total Optional parameter
#' @param metrics Optional parameter
#' @param chemicals Optional parameter
#' @param labels Optional parameter
#' @param options Optional parameter
#' @param acl Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_bulk(id = "DTXSID7020182")
#' }
chemi_toxprints_assays_bulk <- function(id, name = NULL, category = NULL, actives = NULL, total = NULL, metrics = NULL, chemicals = NULL, labels = NULL, options = NULL, acl = NULL) {
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
  generic_chemi_request(
    query = id,
    endpoint = "toxprints/assays",
    options = options,
    tidy = FALSE
  )
}




#' Toxprints Assays 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Primary query parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays(name = "DTXSID7020182")
#' }
chemi_toxprints_assays <- function(name) {
  generic_request(
    query = name,
    endpoint = "toxprints/assays/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


