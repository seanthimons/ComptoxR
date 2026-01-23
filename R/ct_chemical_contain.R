#' Get chemicals by substring value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param top Optional parameter (default: 0)
#' @param projection Optional parameter (default: chemicalsearchall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_contain(word = "DTXSID7020182")
#' }
ct_chemical_contain <- function(top = 0, projection = "chemicalsearchall") {
  result <- generic_request(
    endpoint = "chemical/search/contain/",
    method = "GET",
    batch_limit = 1,
    `top` = top,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


