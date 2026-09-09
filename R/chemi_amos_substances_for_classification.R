#' Returns a list of substances in the database which match the specified top four levels of a ClassyFire classification.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param kingdom Kingdom-level (highest) classification of a substance.
#' @param klass Class-level (third-highest) classification of a substance.
#' @param subklass Subclass-level (fourth-highest) classification of a substance.
#' @param superklass Superclass-level (second-highest) classification of a substance.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_classification(kingdom = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_substances_for_classification <- function(kingdom = NULL, klass = NULL, subklass = NULL, superklass = NULL) {
  params <- list("kingdom" = kingdom, "klass" = klass, "subklass" = subklass, "superklass" = superklass)
  result <- generic_chemi_request(
    "query" = params[["kingdom"]],
    "endpoint" = "amos/substances_for_classification/",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("klass" = params[["klass"]], "subklass" = params[["subklass"]], "superklass" = params[["superklass"]])
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
