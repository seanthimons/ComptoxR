#' Get all assay annotations
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param projection Optional parameter (default: assay-all)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay(projection = "assay-all")
#' }
ct_bioactivity_assay <- function(projection = "assay-all") {
  result <- generic_request(
    endpoint = "bioactivity/assay/",
    method = "GET",
    batch_limit = 0,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


