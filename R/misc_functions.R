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

