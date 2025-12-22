#' Reportable quantity limits
#'
#' Returns the RQs for compounds with their hazard class and numeric limits in pounds and kilograms.
#'
#' @param query A list of DTXSIDs to search by.
#'
#' @return A tibble of results.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_rq(query = "DTXSID7020182")
#' }
chemi_rq <- function(query) {
  result <- generic_chemi_request(
    query = query,
    endpoint = "rq",
    server = 'chemi_burl',
    wrap = FALSE
  )

  if (nrow(result) > 0 && "rqCode" %in% colnames(result)) {
    result <- result %>%
      tidyr::unnest_wider(rqCode) %>%
      dplyr::filter(!is.na(rq)) %>%
      tidyr::separate_wider_delim(rq, ' ', names = c('rq_lbs', 'rq_kgs')) %>%
      dplyr::mutate(
        rq_lbs = as.numeric(stringr::str_remove_all(rq_lbs, '\\(|\\)|\\,')),
        rq_kgs = as.numeric(stringr::str_remove_all(rq_kgs, '\\(|\\)|\\,'))
      )
  }

  return(result)
}
