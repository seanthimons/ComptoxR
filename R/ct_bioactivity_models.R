#' Return ToxCast models for given dtxsid
#' 
#' @param query List of DTXSIDs to search for
#' 
#' @returns A tibble
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_models(query = "DTXSID7020182")
#' }
ct_bioactivity_models <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/models/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  if (nrow(result) > 0 && 'modelDesc' %in% colnames(result)) {
    result <- result %>%
      dplyr::select(-dplyr::any_of(c("modelDesc", "id")))
  }

  return(result)
}
