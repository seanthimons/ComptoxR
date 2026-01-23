#' Get chemicals by starting value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param top Optional parameter (default: 500)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_start_with(word = "DTXSID7020182")
#' }
ct_chemical_start_with <- function(top = 500) {
  result <- generic_request(
    endpoint = "chemical/search/start-with/",
    method = "GET",
    batch_limit = 1,
    `top` = top
  )

  # Additional post-processing can be added here

  return(result)
}


