#' Get all assay annotations
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param projection Optional parameter (default: assay-all)
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay(projection = "assay-all")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay <- function(projection = "assay-all") {
  params <- base::list("projection" = projection)
  result <- generic_request(
    "endpoint" = "bioactivity/assay/",
    "method" = "GET",
    "batch_limit" = 0,
    "projection" = params[["projection"]]
  )
  result
}
