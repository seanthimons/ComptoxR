#' Suggest CheT chemicals for look-ahead search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query User-entered chemical name, DTXSID, CASRN, or resolver-supported identifier.
#' @param limit Optional parameter (default: 8)
#' @param only_in_reactions If true, only suggest chemicals that participate in at least one reaction. (default: true)
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_suggest(query = "DTXSID7020182")
#' }
chemi_chet_chemicals_suggest <- function(query, limit = 8, only_in_reactions = "true") {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(limit)) options[['limit']] <- limit
  if (!is.null(only_in_reactions)) options[['only_in_reactions']] <- only_in_reactions
    result <- generic_request(
    endpoint = "chemicals/suggest",
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


