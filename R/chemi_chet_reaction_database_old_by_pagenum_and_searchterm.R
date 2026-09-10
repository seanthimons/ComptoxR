#' Search reactions (legacy)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param pagenum Primary query parameter. Type: integer
#' @param searchterm Optional parameter. Type: string
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database_old_by_pagenum_and_searchterm(pagenum = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_database_old_by_pagenum_and_searchterm <- function(pagenum, searchterm = NULL) {
  params <- list("pagenum" = pagenum, "searchterm" = searchterm)
  result <- generic_request(
    "query" = params[["pagenum"]],
    "endpoint" = "reaction/database-old/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "path_params" = c("searchterm" = params[["searchterm"]])
  )
  result
}
