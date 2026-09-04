#' Returns a list of substances in the database which match the specified top four levels of a ClassyFire classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param kingdom Kingdom-level (highest) classification of a substance.
#' @param klass Class-level (third-highest) classification of a substance.
#' @param subklass Subclass-level (fourth-highest) classification of a substance.
#' @param superklass Superclass-level (second-highest) classification of a substance.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_classification_staging(kingdom = "DTXSID1024122")
#' }
chemi_amos_substances_for_classification_staging <- function(kingdom = NULL, klass = NULL, subklass = NULL, superklass = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_substances_for_classification_staging", "pre_request", list(params = list(`kingdom` = kingdom, `klass` = klass, `subklass` = subklass, `superklass` = superklass, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("kingdom" %in% names(req_data$params)) {
    kingdom <- req_data$params[["kingdom"]]
  }
  if ("klass" %in% names(req_data$params)) {
    klass <- req_data$params[["klass"]]
  }
  if ("subklass" %in% names(req_data$params)) {
    subklass <- req_data$params[["subklass"]]
  }
  if ("superklass" %in% names(req_data$params)) {
    superklass <- req_data$params[["superklass"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(klass)) options$klass <- klass
  if (!is.null(subklass)) options$subklass <- subklass
  if (!is.null(superklass)) options$superklass <- superklass
  result <- generic_chemi_request(
    query = kingdom,
    endpoint = "amos/substances_for_classification/",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
