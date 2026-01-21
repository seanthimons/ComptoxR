#' Returns a list of substances whose monoisotopic mass falls within the specified range.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_range()
#' }
chemi_amos_mass_range <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "amos/mass_range_search/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


