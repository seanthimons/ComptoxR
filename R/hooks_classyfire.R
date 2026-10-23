# Select the legacy public classification columns after all inputs are combined.
format_classyfire_result <- function(data) {
  result <- data$result
  if (nrow(result) > 0) {
    result <- dplyr::select(
      result,
      dtxsid = dplyr::any_of(c("query", "value", "sid")),
      kingdom = dplyr::any_of("kingdom"),
      superclass = dplyr::any_of("superklass"),
      class = dplyr::any_of("klass"),
      subclass = dplyr::any_of("subklass")
    )
  }
  result
}
