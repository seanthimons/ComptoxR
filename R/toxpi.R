tp_single_score <- function(x){

  (x - min(x, na.rm = TRUE))/diff(range(x, na.rm = TRUE))

}

tp_combined_score <- function(x){

  tp_scores <- x %>% mutate(across(.cols = !contains('compound'), ~ tp_single_score(.x)))
  tp_scores[is.na(tp_scores)] <- 0
  tp_scores <- tp_scores %>%
    rowwise() %>%
    mutate(toxpi_score = sum(c_across(cols = !contains('compound'))))
  return(tp_scores)
}


