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

#' Not-in operator
#'
#' @param x Vector of values to match.
#' @param table Vector or list to match against.
#'
#' @usage x \%ni\% table
#'
#' @return Logical vector indicating values in `x` that are not in `table`.
#' @export
`%ni%` <- function(x, table) {
  !(x %in% table)
}
