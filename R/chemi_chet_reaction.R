#' Search reactions and chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Optional parameter
#' @param searchType Optional parameter
#' @param substringTF Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction(query = "DTXSID7020182")
#' }
chemi_chet_reaction <- function(query = NULL, searchType = NULL, substringTF = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(searchType)) options[['searchType']] <- searchType
  if (!is.null(substringTF)) options[['substringTF']] <- substringTF
    result <- generic_request(
    endpoint = "reaction/search",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


