#' Search reactions (legacy)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param pagenum Primary query parameter. Type: integer
#' @param searchterm Optional parameter. Type: string
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database_old_by_pagenum(pagenum = "DTXSID7020182")
#' }
chemi_chet_reaction_database_old_by_pagenum <- function(pagenum, searchterm = NULL) {
  result <- generic_request(
    query = pagenum,
    endpoint = "reaction/database-old/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(searchterm = searchterm)
  )

  # Additional post-processing can be added here

  return(result)
}
