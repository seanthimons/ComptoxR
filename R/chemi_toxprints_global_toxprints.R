#' Toxprints Global Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param category Optional parameter
#' @param label Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_global_toxprints(category = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_global_toxprints <- function(category = NULL, label = NULL) {
  params <- list("category" = category, "label" = label)
  result <- generic_request(
    "endpoint" = "toxprints/global_toxprints",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("category" = params[["category"]], "label" = params[["label"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
