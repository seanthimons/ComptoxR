#' Safety Rqcodes
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_rqcodes()
#' }
chemi_safety_rqcodes <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "safety/rqcodes",
    tidy = FALSE
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
