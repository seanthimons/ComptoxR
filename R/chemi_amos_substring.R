#' Returns information on substances where the specified substring is in or equal to a name.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param substring A name substring to search by.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substring(substring = "DTXSID7020182")
#' }
chemi_amos_substring <- function(substring) {
  result <- generic_request(
    query = substring,
    endpoint = "amos/substring_search/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


