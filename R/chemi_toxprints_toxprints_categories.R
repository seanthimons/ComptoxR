#' Toxprints Toxprints Categories
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemical Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints_categories(chemical = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_toxprints_toxprints_categories <- function(chemical = NULL) {
  params <- list("chemical" = chemical)
  result <- generic_chemi_request(
    "query" = params[["chemical"]],
    "endpoint" = "toxprints/toxprints_categories",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
