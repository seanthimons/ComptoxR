#' Returns information on a batch of safety data sheets using keyset pagination.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param limit Limit of records to return.
#' @param cursor Optional keyset cursor returned by a previous response.
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_safety_data_sheet_keyset_pagination(limit = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_safety_data_sheet_keyset_pagination <- function(limit, cursor = NULL, all_pages = TRUE, max_pages = 100) {
  params <- base::list("limit" = limit, "cursor" = cursor, "all_pages" = all_pages, "max_pages" = max_pages)
  result <- generic_request(
    "query" = params[["limit"]],
    "endpoint" = "amos/safety_data_sheet_keyset_pagination/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("cursor" = params[["cursor"]]))
      if (base::length(.body)) .body else base::list()
    }),
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "cursor",
    "pagination_cursor_location" = "query"
  )
  result
}
