#' Title
#'
#' @param .x
#' @param .f
#' @param ...
#' @param .id
#'
#' @return

map_df_progress <- function(.x, .f, ..., .id = NULL) {
  .f <- purrr::as_mapper(.f, ...)
  pb <- progress::progress_bar$new(total = length(.x), force = TRUE)

  f <- function(...) {
    pb$tick()
    .f(...)
  }
  purrr::map_df(.x, f, ..., .id = .id)
}


#Creates a new minimum function that ignores NAs and suppresses warning
#' Title
#'
#' @param x
#'
#' @return
#' @export

min2 <- function(x){
  y <- suppressWarnings(min(x, na.rm = T)) #suppress the warnings; ignore NAs
  if (y==Inf){
    y <- NA #replace Inf with NA
  }
  return(y)
}

#' Title
#'
#' @param x
#' @param na.rm
#'
#' @return
#' @export

geometric.mean <- function(x,na.rm=TRUE)  {
    exp(mean(log(x[x > 0]),na.rm=na.rm)) }


#' Title
#'
#' @param x
#'
#' @return
#' @export

tp_single_score <- function(x){

  (x - min(x, na.rm = TRUE))/diff(range(x, na.rm = TRUE))

}

#' Title
#'
#' @param hc_table
#'
#' @return
#' @export

tp_combined_score <- function(hc_table){

  tp_scores <- hc_table %>% mutate(across(.cols = !contains('compound'), ~ tp_single_score(.x)))
  tp_scores[is.na(tp_scores)] <- 0
  tp_scores <- tp_scores %>%
    rowwise() %>%
    mutate(toxpi_score = sum(c_across(cols = !contains('compound'))))
  return(tp_scores)
}

timestamp <- paste(Sys.Date(),as.integer(Sys.time()), sep = '_')

`%ni%` <- Negate(`%in%`)
