#' Returns information on a batch of methods using keyset pagination.
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
#' chemi_amos_method_keyset_pagination(limit = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_method_keyset_pagination <- function(limit, cursor = NULL, all_pages = TRUE, max_pages = 100) {
  params <- list("limit" = limit, "cursor" = cursor, "all_pages" = all_pages, "max_pages" = max_pages)
  result <- generic_request(
    "query" = params[["limit"]],
    "endpoint" = "amos/method_keyset_pagination/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("cursor" = params[["cursor"]]))
      if (length(.body)) .body else list()
    }),
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "cursor",
    "pagination_cursor_location" = "query"
  )
  result
}

#' Returns filtered methods using keyset pagination.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param limit Limit of records to return.
#' @param cursor Optional keyset cursor returned by a previous response. (default: )
#' @param document_text Optional full-text document search. (default: )
#' @param dtxsid Optional DTXSID substance filter. (default: )
#' @param filterModel Alias for filters. (default: \{\})
#' @param filters AG Grid filter model keyed by table field name. (default: \{\})
#' @param full_table Text to match across searchable table columns. (default: )
#' @param include_total If true, include total filtered record count in pagination. (default: FALSE)
#' @param quickFilter Alias for full_table. (default: )
#' @param sortModel Optional AG Grid sort model. The first entry is used; internal_id is always used as a stable tie-breaker. Send the same sortModel with each cursor request. (default: \[\])
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_method_keyset_pagination_bulk(limit = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_method_keyset_pagination_bulk <- function(
  limit,
  cursor = "",
  document_text = "",
  dtxsid = "",
  filterModel = structure(list(), names = character(0)),
  filters = structure(list(), names = character(0)),
  full_table = "",
  include_total = FALSE,
  quickFilter = "",
  sortModel = list(),
  all_pages = TRUE,
  max_pages = 100
) {
  params <- list(
    "limit" = limit,
    "cursor" = cursor,
    "document_text" = document_text,
    "dtxsid" = dtxsid,
    "filterModel" = filterModel,
    "filters" = filters,
    "full_table" = full_table,
    "include_total" = include_total,
    "quickFilter" = quickFilter,
    "sortModel" = sortModel,
    "all_pages" = all_pages,
    "max_pages" = max_pages
  )
  result <- generic_request(
    "query" = NULL,
    "endpoint" = "amos/method_keyset_pagination/",
    "method" = "POST",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "path_params" = c("limit" = params[["limit"]]),
    "body" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "cursor" = params[["cursor"]],
          "document_text" = params[["document_text"]],
          "dtxsid" = params[["dtxsid"]],
          "filterModel" = params[["filterModel"]],
          "filters" = params[["filters"]],
          "full_table" = params[["full_table"]],
          "include_total" = params[["include_total"]],
          "quickFilter" = params[["quickFilter"]],
          "sortModel" = params[["sortModel"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "cursor",
    "pagination_cursor_location" = "body"
  )
  result
}
