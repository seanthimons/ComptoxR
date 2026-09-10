#' Returns a list of substances whose monoisotopic mass falls within the specified range.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param lower_mass_limit Lower limit of the mass range to search for.
#' @param upper_mass_limit Upper limit of the mass range to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_mass_range(lower_mass_limit = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_mass_range <- function(lower_mass_limit = NULL, upper_mass_limit = NULL) {
  params <- list("lower_mass_limit" = lower_mass_limit, "upper_mass_limit" = upper_mass_limit)
  result <- generic_chemi_request(
    "query" = params[["lower_mass_limit"]],
    "endpoint" = "amos/mass_range_search/",
    "options" = local({
      .body <- Filter(Negate(is.null), list("upper_mass_limit" = params[["upper_mass_limit"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
