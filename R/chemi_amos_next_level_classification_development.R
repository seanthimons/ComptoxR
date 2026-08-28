#' Returns a list of categories for the specified level of ClassyFire classification, given the higher levels of classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param kingdom Kingdom-level (highest) classification of a substance.  Always required.
#' @param klass Class-level (third-highest) classification of a substance.  Required if requesting a list of subclasses.
#' @param superklass Superclass-level (second-highest) classification of a substance.  Required if requesting a list of classes or subclasses.
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_next_level_classification_development(kingdom = "DTXSID1024122")
#' }
chemi_amos_next_level_classification_development <- function(kingdom = NULL, klass = NULL, superklass = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_next_level_classification_development", "pre_request", list(params = list(`kingdom` = kingdom, `klass` = klass, `superklass` = superklass, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("kingdom" %in% names(req_data$params)) {
    kingdom <- req_data$params[["kingdom"]]
  }
  if ("klass" %in% names(req_data$params)) {
    klass <- req_data$params[["klass"]]
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
  if (!is.null(superklass)) options$superklass <- superklass
  result <- generic_chemi_request(
    query = kingdom,
    endpoint = "amos/next_level_classification/",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
