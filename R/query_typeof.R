#' Query typeof
#'
#' Checks the type of the query object to make sure a parent function can accept it.
#'
#' @param query A list, vector, string
#' @param debug Boolean flag to set typeof output messaging. Defaults to `FALSE`
#'
#' @return A properly formatted query

query_typeof <- function(query, debug = FALSE) {
  if (typeof(query) == 'list') {
    if (debug == TRUE) {
      cat(typeof(query))
    }

    payload <- list(
      ids = vector(mode = 'list', length = length(query))
    )
  } else {
    if (typeof(query) == 'character') {
      if (debug == TRUE) {
        cat(typeof(query))
      }

      query_mod <- as.list(query)

      payload <- list(
        ids = vector(mode = 'list', length = length(query_mod))
      )
    } else {
      stop('Check query type!')
    }
  }
  return(payload)
}
