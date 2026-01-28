#' Get total assay count
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_count()
#' }
ct_bioactivity_assay_count <- function() {
  result <- generic_request(
    endpoint = "bioactivity/assay/count",
    method = "GET",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


