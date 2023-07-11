#' ToxPi Single Endpoint score calculation
#'
#' @param x Takes a single column for calculation a normalization score
#' @param min_fill Boolean variable for adding in 50% to lowest non-zero score. Defaults to `TRUE`
#'
#' @return A vector
#' @export

tp_single_score <- function(x, min_fill = T){

  df <- (x - min(x, na.rm = TRUE))/diff(range(x, na.rm = TRUE))
  if(min_fill == T){df[df == 0] <- min(df[df > 0], na.rm = T)*0.5}else{}
  return(df)
}

#' Title

#' @param df Data frame to analyze.
#' @param ID ID column to ignore. Must be present to continue calculation
#' @param ... Variable to pass in min_fill argument
#'
#' @return A tibble of results
#' @export

tp_combined_score <- function(df, ID = NA, bias = NA, ...){

  if(is.na(ID) == T){
    cat('\nPlease specify ID column!')

    }
  else{
    if(is.na(bias) == T){
      #TODO make generic bias table?
    }
    else{

    }
    tp_scores <- df %>% mutate(across(.cols = !contains(ID), ~ tp_single_score(.x, ... )))
    tp_scores[is.na(tp_scores)] <- 0
    tp_scores <- tp_scores %>% rowwise() %>%
    mutate(score = sum(c_across(cols = !contains(ID))))
  }
  return(tp_scores)
}




