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

min2 <- function(x) {
  y <- suppressWarnings(min(x, na.rm = T)) #suppress the warnings; ignore NAs
  if (y == Inf) {
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

geometric.mean <- function(x, na.rm = TRUE) {
  exp(mean(log(x[x > 0]), na.rm = na.rm))
}


#' Pretty list
#'
#' @param x list
#'
#' @return list
#' @export

pretty_list <- function(x) {
  #x <- colnames(x)
  message(paste0('"', x, '",', "\n"))
}

#' Pretty print list
#'
#' @param x list
#'
#' @return list
#' @export

pretty_print <- function(x) {
  message(paste(x, "\n"))
}

#' Pretty re-name
#'
#' @param x list
#'
#' @return list
#' @export

pretty_rename <- function(x) {
  #x <- colnames(x)
  message(paste0("'' = '", x, "',", "\n"))
}

#' Pretty Case When
#'
#' @param var Variable
#' @param x Case
#'
#' @return list
#' @export

pretty_casewhen <- function(var, x) {
  message(paste0(var, " == ", x, " ~ '',\n"))
}

#' Not-in
#'
#' @return Opposite of %in%
#' @export
`%ni%` <- Negate(`%in%`)
