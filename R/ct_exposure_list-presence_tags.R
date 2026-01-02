#' Get List Presence Tags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_list_presence_tags(query = "DTXSID7020182")
#' }
ct_exposure_list_presence_tags <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/list-presence/tags",
    method = "GET",
		batch_limit = 1
  )
}

