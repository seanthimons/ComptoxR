#' chemi amos safety data sheet keyset pagination
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param limit limit
#' @param cursor cursor
#' @param all_pages TRUE (the default) requests page after page, starting at cursor, until a page comes back empty or the client says it was the last or max_pages is reached, and returns the pages combined. FALSE requests only the page given in cursor.
#' @param max_pages Maximum number of pages requested when all_pages is TRUE. Reaching it stops paging with a warning.
#' @return A list of records when all_pages is TRUE, otherwise the original response envelope.
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_safety_data_sheet_keyset_pagination(limit = 1L, all_pages = FALSE, max_pages = 2L)
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_safety_data_sheet_keyset_pagination <- function(limit, cursor = NULL, all_pages = TRUE, max_pages = 100L) {
  params <- base::list("limit" = limit, "cursor" = cursor)
  if (!base::is.logical(all_pages) || base::length(all_pages) != 1L || base::is.na(all_pages)) {
    base::stop("all_pages must be TRUE or FALSE", call. = FALSE)
  }
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/api/amos/safety_data_sheet_keyset_pagination/{limit}",
      "path_params" = base::list("limit" = params[["limit"]]),
      "query" = base::list("cursor" = params[["cursor"]]),
      "body" = NULL,
      "headers" = list(Accept = "application/json"),
      "server" = list(diagnostic = "Reviewed AMOS production origin."),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        context$endpoint <- "amos/safety_data_sheet_keyset_pagination/"
        context$query <- params[["limit"]]
        if (all_pages) {
          return(.ct_keyset_page(response, context, decode))
        }
        .ct_keyset_manual(response, context, decode)
      }
    )
    result
  }
  if (!base::isTRUE(all_pages)) {
    result <- send(params)
    if (base::inherits(result, "httr2_request")) {
      base::return(result)
    }
    base::return(base::get(
      ".ct_keyset_items",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    )(result))
  }
  result <- .ct_request_pages(
    function(page) {
      params[base::names(page)] <- page
      send(params)
    },
    "cursor",
    params[["cursor"]],
    max_pages,
    completed = base::get(
      ".ct_keyset_done",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    mode = "cursor",
    next_cursor = base::get(
      ".ct_keyset_next",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    items = base::get(
      ".ct_keyset_items",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    error_policy = "partial",
    warn_limits = TRUE,
    warn_errors = FALSE,
    stop_on_empty = FALSE,
    on_limit = base::get(
      ".ct_keyset_limit_warning",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    )
  )
  if (!base::inherits(result, "httr2_request") && !base::is.null(result)) {
    base::attr(result, "pagination") <- NULL
  }
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  kept <- base::attr(result, "pagination", exact = TRUE)
  result <- run_hook(
    "chemi_amos_safety_data_sheet_keyset_pagination",
    "post_combine",
    base::list(result = result, params = params)
  )
  if (!base::is.null(kept) && !base::is.null(result) && base::is.null(base::attr(result, "pagination", exact = TRUE))) {
    base::attr(result, "pagination") <- kept
  }
  result
}

#' chemi amos safety data sheet keyset pagination bulk
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param limit limit
#' @param cursor cursor
#' @param document_text document_text
#' @param dtxsid dtxsid
#' @param filterModel filterModel
#' @param filters filters
#' @param full_table full_table
#' @param include_total include_total
#' @param quickFilter quickFilter
#' @param sortModel sortModel
#' @param all_pages TRUE (the default) requests page after page, starting at cursor, until a page comes back empty or the client says it was the last or max_pages is reached, and returns the pages combined. FALSE requests only the page given in cursor.
#' @param max_pages Maximum number of pages requested when all_pages is TRUE. Reaching it stops paging with a warning.
#' @return A list of records when all_pages is TRUE, otherwise the original response envelope.
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_safety_data_sheet_keyset_pagination_bulk(limit = 1L, all_pages = FALSE, max_pages = 2L)
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_safety_data_sheet_keyset_pagination_bulk <- function(
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
  max_pages = 100L
) {
  params <- base::list(
    "limit" = limit,
    "cursor" = cursor,
    "document_text" = document_text,
    "dtxsid" = dtxsid,
    "filterModel" = filterModel,
    "filters" = filters,
    "full_table" = full_table,
    "include_total" = include_total,
    "quickFilter" = quickFilter,
    "sortModel" = sortModel
  )
  if (!base::is.logical(all_pages) || base::length(all_pages) != 1L || base::is.na(all_pages)) {
    base::stop("all_pages must be TRUE or FALSE", call. = FALSE)
  }
  send <- function(params) {
    result <- .ct_request(
      "method" = "POST",
      "path" = "/api/amos/safety_data_sheet_keyset_pagination/{limit}",
      "path_params" = base::list("limit" = params[["limit"]]),
      "query" = structure(list(), names = character(0)),
      "body" = base::Filter(base::Negate(base::is.null), params[base::setdiff(base::names(params), "limit")]),
      "headers" = list(Accept = "application/json"),
      "server" = list(diagnostic = "Reviewed AMOS production origin."),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        context$endpoint <- "amos/safety_data_sheet_keyset_pagination/"
        context$query <- NULL
        if (all_pages) {
          return(.ct_keyset_page(response, context, decode))
        }
        .ct_keyset_manual(response, context, decode)
      }
    )
    result
  }
  if (!base::isTRUE(all_pages)) {
    result <- send(params)
    if (base::inherits(result, "httr2_request")) {
      base::return(result)
    }
    base::return(base::get(
      ".ct_keyset_items",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    )(result))
  }
  result <- .ct_request_pages(
    function(page) {
      params[base::names(page)] <- page
      send(params)
    },
    "cursor",
    params[["cursor"]],
    max_pages,
    completed = base::get(
      ".ct_keyset_done",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    mode = "cursor",
    next_cursor = base::get(
      ".ct_keyset_next",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    items = base::get(
      ".ct_keyset_items",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    error_policy = "partial",
    warn_limits = TRUE,
    warn_errors = FALSE,
    stop_on_empty = FALSE,
    on_limit = base::get(
      ".ct_keyset_limit_warning",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    )
  )
  if (!base::inherits(result, "httr2_request") && !base::is.null(result)) {
    base::attr(result, "pagination") <- NULL
  }
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  kept <- base::attr(result, "pagination", exact = TRUE)
  result <- run_hook(
    "chemi_amos_safety_data_sheet_keyset_pagination_bulk",
    "post_combine",
    base::list(result = result, params = params)
  )
  if (!base::is.null(kept) && !base::is.null(result) && base::is.null(base::attr(result, "pagination", exact = TRUE))) {
    base::attr(result, "pagination") <- kept
  }
  result
}
