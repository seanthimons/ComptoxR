#' Safety Rqcodes
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_rqcodes(query = "DTXSID7020182")
#' }
chemi_safety_rqcodes <- function(query) {
  result <- generic_chemi_request(
    query = query,
    endpoint = "safety/rqcodes",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    wrap = FALSE
  )

  # Additional post-processing can be added here

  result <- result %>%
    map(., ~ pluck(.x, 'rqCode')) %>%
    compact()

  if (length(result) > 0) {
    result <- result %>%
      map(., ~ as_tibble(.x)) %>%
      list_rbind() %>%
      tidyr::separate_wider_delim(rq, ' ', names = c('rq_lbs', 'rq_kgs')) %>%
      dplyr::mutate(
        rq_lbs = as.numeric(stringr::str_remove_all(rq_lbs, '\\(|\\)|\\,')),
        rq_kgs = as.numeric(stringr::str_remove_all(rq_kgs, '\\(|\\)|\\,'))
      )
  }else{

		result <- NULL

	}

  return(result)
}
