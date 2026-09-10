#' Batch search reactions and chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsids Required parameter
#' @param search_level Required parameter. Options: chemical, reaction
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_batchsearch(dtxsids = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_batchsearch <- function(dtxsids, search_level) {
  params <- list("dtxsids" = dtxsids, "search_level" = search_level)
  result <- generic_chemi_request(
    "query" = params[["dtxsids"]],
    "endpoint" = "reaction/batchsearch",
    "options" = local({
      .body <- Filter(Negate(is.null), list("search_level" = params[["search_level"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
