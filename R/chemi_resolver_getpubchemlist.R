#' Resolver Getpubchemlist
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Required parameter
#' @param section Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getpubchemlist(chemicals = "DTXSID7020182")
#' }
chemi_resolver_getpubchemlist <- function(chemicals, section = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(section)) options$section <- section
  generic_chemi_request(
    query = chemicals,
    endpoint = "resolver/getpubchemlist",
    options = options,
    tidy = FALSE
  )
}


