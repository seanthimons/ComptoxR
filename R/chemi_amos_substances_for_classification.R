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
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_classification(kingdom = c("DTXSID1022421", "DTXSID50220251", "DTXSID30275709"))
#' }
chemi_amos_substances_for_classification <- function(kingdom = NULL, klass = NULL, subklass = NULL, superklass = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(klass)) options$klass <- klass
  if (!is.null(subklass)) options$subklass <- subklass
  if (!is.null(superklass)) options$superklass <- superklass
  result <- generic_chemi_request(
    query = kingdom,
    endpoint = "amos/substances_for_classification/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


