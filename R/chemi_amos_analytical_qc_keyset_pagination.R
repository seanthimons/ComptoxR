#' Returns information on a batch of Analytical QC documents using keyset pagination.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param cursor Optional keyset cursor returned by a previous response.
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_keyset_pagination(limit = "DTXSID7020182")
#' }
chemi_amos_analytical_qc_keyset_pagination <- function(
  limit,
  cursor = NULL,
  all_pages = TRUE,
  max_pages = 100
) {
  # Collect optional parameters
  options <- list()
  if (!is.null(cursor)) {
    options[['cursor']] <- cursor
  }
  result <- generic_request(
    query = limit,
    endpoint = "amos/analytical_qc_keyset_pagination/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options,
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "cursor",
    pagination_cursor_location = "query"
  )

  # Additional post-processing can be added here

  return(result)
}

#' Returns filtered Analytical QC records using keyset pagination.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param cursor Optional keyset cursor returned by a previous response. (default: )
#' @param dtxsid Optional DTXSID substance filter. (default: )
#' @param filterModel Alias for filters. (default: {})
#' @param filters AG Grid filter model keyed by table field name. (default: {})
#' @param full_table Text to match across searchable table columns. (default: )
#' @param include_total If true, include total filtered record count in pagination. (default: FALSE)
#' @param quickFilter Alias for full_table. (default: )
#' @param sortModel Optional AG Grid sort model. The first entry is used; internal_id is always used as a stable tie-breaker. Send the same sortModel with each cursor request. (default: [])
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_keyset_pagination_bulk(limit = "DTXSID7020182")
#' }
chemi_amos_analytical_qc_keyset_pagination_bulk <- function(
  limit,
  cursor = "",
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
  # Build request body
  request_body <- list()
  if (!is.null(cursor)) {
    request_body$cursor <- cursor
  }
  if (!is.null(dtxsid)) {
    request_body$dtxsid <- dtxsid
  }
  if (!is.null(filterModel)) {
    request_body$filterModel <- filterModel
  }
  if (!is.null(filters)) {
    request_body$filters <- filters
  }
  if (!is.null(full_table)) {
    request_body$full_table <- full_table
  }
  if (!is.null(include_total)) {
    request_body$include_total <- include_total
  }
  if (!is.null(quickFilter)) {
    request_body$quickFilter <- quickFilter
  }
  if (!is.null(sortModel)) {
    request_body$sortModel <- sortModel
  }
  result <- generic_request(
    query = NULL,
    endpoint = "amos/analytical_qc_keyset_pagination/",
    method = "POST",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(limit = limit),
    body = request_body,
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "cursor",
    pagination_cursor_location = "body"
  )

  # Additional post-processing can be added here

  return(result)
}
