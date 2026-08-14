#' Returns information on a batch of product declarations using keyset pagination.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param cursor Optional keyset cursor returned by a previous response.
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_product_declaration_keyset_pagination(limit = "DTXSID7020182")
#' }
chemi_amos_product_declaration_keyset_pagination <- function(limit, cursor = NULL, all_pages = TRUE, max_pages = 100) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_product_declaration_keyset_pagination",
    "pre_request",
    list(
      params = list(
        `limit` = limit,
        `cursor` = cursor,
        `all_pages` = all_pages,
        `max_pages` = max_pages,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("limit" %in% names(req_data$params)) {
    limit <- req_data$params[["limit"]]
  }
  if ("cursor" %in% names(req_data$params)) {
    cursor <- req_data$params[["cursor"]]
  }
  if ("all_pages" %in% names(req_data$params)) {
    all_pages <- req_data$params[["all_pages"]]
  }
  if ("max_pages" %in% names(req_data$params)) {
    max_pages <- req_data$params[["max_pages"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(cursor)) {
    options[['cursor']] <- cursor
  }
  result <- generic_request(
    query = limit,
    endpoint = "amos/product_declaration_keyset_pagination/",
    method = "GET",
    batch_limit = 1,
    server = server,
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

#' Returns filtered product declarations using keyset pagination.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param cursor Optional keyset cursor returned by a previous response. (default: )
#' @param document_text Optional full-text document search. (default: )
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
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_product_declaration_keyset_pagination_bulk(limit = "DTXSID7020182")
#' }
chemi_amos_product_declaration_keyset_pagination_bulk <- function(
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
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_product_declaration_keyset_pagination_bulk",
    "pre_request",
    list(
      params = list(
        `limit` = limit,
        `cursor` = cursor,
        `document_text` = document_text,
        `dtxsid` = dtxsid,
        `filterModel` = filterModel,
        `filters` = filters,
        `full_table` = full_table,
        `include_total` = include_total,
        `quickFilter` = quickFilter,
        `sortModel` = sortModel,
        `all_pages` = all_pages,
        `max_pages` = max_pages,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("limit" %in% names(req_data$params)) {
    limit <- req_data$params[["limit"]]
  }
  if ("cursor" %in% names(req_data$params)) {
    cursor <- req_data$params[["cursor"]]
  }
  if ("document_text" %in% names(req_data$params)) {
    document_text <- req_data$params[["document_text"]]
  }
  if ("dtxsid" %in% names(req_data$params)) {
    dtxsid <- req_data$params[["dtxsid"]]
  }
  if ("filterModel" %in% names(req_data$params)) {
    filterModel <- req_data$params[["filterModel"]]
  }
  if ("filters" %in% names(req_data$params)) {
    filters <- req_data$params[["filters"]]
  }
  if ("full_table" %in% names(req_data$params)) {
    full_table <- req_data$params[["full_table"]]
  }
  if ("include_total" %in% names(req_data$params)) {
    include_total <- req_data$params[["include_total"]]
  }
  if ("quickFilter" %in% names(req_data$params)) {
    quickFilter <- req_data$params[["quickFilter"]]
  }
  if ("sortModel" %in% names(req_data$params)) {
    sortModel <- req_data$params[["sortModel"]]
  }
  if ("all_pages" %in% names(req_data$params)) {
    all_pages <- req_data$params[["all_pages"]]
  }
  if ("max_pages" %in% names(req_data$params)) {
    max_pages <- req_data$params[["max_pages"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build request body
  request_body <- list()
  if (!is.null(cursor)) {
    request_body$cursor <- cursor
  }
  if (!is.null(document_text)) {
    request_body$document_text <- document_text
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
    endpoint = "amos/product_declaration_keyset_pagination/",
    method = "POST",
    batch_limit = 0,
    server = server,
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
