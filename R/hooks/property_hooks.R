# Property Hook Primitives
# Hooks for property search operations

#' Coerce property results by propertyId
#'
#' Post-response hook that splits property search results by propertyId
#' when coerce=TRUE, returning a named list of data frames.
#'
#' @param data Hook data structure with list(result = ..., params = list(coerce = ...))
#' @return Original tibble or named list split by propertyId
#' @noRd
coerce_by_property_id <- function(data) {
  if (!isTRUE(data$params$coerce)) {
    return(data$result)
  }

  # Handle empty results
  if (nrow(data$result) == 0) {
    return(data$result)
  }

  # Split by propertyId column
  result <- data$result %>%
    split(.$propertyId)

  cli::cli_alert_success("Coerced {length(result)} property groups!")

  return(result)
}
