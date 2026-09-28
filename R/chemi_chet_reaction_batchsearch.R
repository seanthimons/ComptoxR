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
  params <- base::list("dtxsids" = dtxsids, "search_level" = search_level)
  result <- generic_chemi_request(
    "query" = params[["dtxsids"]],
    "endpoint" = "chet/reaction/batchsearch",
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("search_level" = params[["search_level"]]))
      if (base::length(.body)) .body else base::list()
    }),
    "tidy" = FALSE,
    "sid_label" = "dtxsids",
    "array_payload" = TRUE
  )
  result
}
