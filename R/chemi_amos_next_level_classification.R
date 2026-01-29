#' Returns a list of categories for the specified level of ClassyFire classification, given the higher levels of classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param kingdom Kingdom-level (highest) classification of a substance.  Always required.
#' @param klass Class-level (third-highest) classification of a substance.  Required if requesting a list of subclasses.
#' @param superklass Superclass-level (second-highest) classification of a substance.  Required if requesting a list of classes or subclasses.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_next_level_classification(kingdom = c("DTXSID10900961", "DTXSID401336719", "DTXSID6026296"))
#' }
chemi_amos_next_level_classification <- function(kingdom = NULL, klass = NULL, superklass = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(klass)) options$klass <- klass
  if (!is.null(superklass)) options$superklass <- superklass
  result <- generic_chemi_request(
    query = kingdom,
    endpoint = "amos/next_level_classification/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


