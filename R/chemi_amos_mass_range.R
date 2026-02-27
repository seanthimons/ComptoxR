#' Returns a list of substances whose monoisotopic mass falls within the specified range.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lower_mass_limit Lower limit of the mass range to search for.
#' @param upper_mass_limit Upper limit of the mass range to search for.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_range(lower_mass_limit = "DTXSID7020182")
#' }
chemi_amos_mass_range <- function(lower_mass_limit = NULL, upper_mass_limit = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(upper_mass_limit)) options$upper_mass_limit <- upper_mass_limit
  result <- generic_chemi_request(
    query = lower_mass_limit,
    endpoint = "amos/mass_range_search/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


