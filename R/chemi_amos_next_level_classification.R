#' Returns a list of categories for the specified level of ClassyFire classification, given the higher levels of classification.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param kingdom Kingdom-level (highest) classification of a substance.  Always required.
#' @param klass Class-level (third-highest) classification of a substance.  Required if requesting a list of subclasses.
#' @param superklass Superclass-level (second-highest) classification of a substance.  Required if requesting a list of classes or subclasses.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_next_level_classification(kingdom = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_next_level_classification <- function(kingdom = NULL, klass = NULL, superklass = NULL) {
  params <- list("kingdom" = kingdom, "klass" = klass, "superklass" = superklass)
  result <- generic_chemi_request(
    "query" = params[["kingdom"]],
    "endpoint" = "amos/next_level_classification/",
    "options" = local({
      .body <- Filter(Negate(is.null), list("klass" = params[["klass"]], "superklass" = params[["superklass"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
