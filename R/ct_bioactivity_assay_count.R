#' Get total assay count
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_count()
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_count <- function() {
  params <- base::list()
  result <- generic_request("endpoint" = "bioactivity/assay/count", "method" = "GET", "batch_limit" = 0)
  result
}
