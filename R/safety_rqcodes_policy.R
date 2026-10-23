# Reject invalid SID inputs before the resolver or safety request.
.ct_safety_sids <- function(query) {
  if (is.null(query) || !length(query)) {
    cli::cli_abort("Either query or chemicals parameter must be provided.")
  }
  if (!is.character(query) || anyNA(query) || any(!grepl("^DTXSID[0-9]+$", query))) {
    cli::cli_abort("query must be a character vector of DTXSIDs.")
  }
  unique(query)
}

format_safety_rqcodes_result <- function(data) {
  result <- data$result
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
  } else {
    result <- NULL
  }

  return(result)
}
