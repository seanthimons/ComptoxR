#' Purrr map_df with progress bar
#'
#' @param .x List to map over
#' @param .f Function to apply
#' @param ... Passes along other function arguments
#' @param .id ID column to be created
#'
#' @return A list

map_df_progress <- function(.x, .f, ..., .id = NULL) {
  .f <- purrr::as_mapper(.f, ...)
  pb <- progress::progress_bar$new(total = length(.x), force = TRUE)

  f <- function(...) {
    pb$tick()
    .f(...)
  }
  purrr::map_df(.x, f, ..., .id = .id)
}


#' Creates a new minimum function that ignores NAs and suppresses warning
#'
#' @param x Vector
#'
#' @return A vector
#' @export

min2 <- function(x){
  y <- suppressWarnings(min(x, na.rm = T)) #suppress the warnings; ignore NAs
  if (y==Inf){
    y <- NA #replace Inf with NA
  }
  return(y)
}

#' Geometric mean function
#'
#' @param x Vector
#' @param na.rm Flag
#'
#' @return A vector
#' @export

geometric.mean <- function(x,na.rm=TRUE)  {
    exp(mean(log(x[x > 0]),na.rm=na.rm)) }

