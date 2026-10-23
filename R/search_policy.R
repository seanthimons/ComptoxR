# Pure client response and body projections. No transport or pager implementation.
.ct_search_page_response <- function(response, context, decode) {
  observe_api_responses(list(response))
  if (context$status >= 400L) return(decode())
  response
}
.ct_search_page_items <- function(response) list(response)
.ct_search_page_done <- function(response, state) {
  body <- .ct_response_json(response)
  count <- body$recordsCount %||% length(body$records %||% list())
  count == 0 || (body$offset %||% 0) + count >= (body$totalRecordsCount %||% 0)
}
.ct_search_page_advance <- function(response, position, page_size) {
  body <- .ct_response_json(response)
  (body$offset %||% 0) + (body$recordsCount %||% length(body$records %||% list()))
}
.ct_search_result <- function(state) {
  if (!state$params$all_pages()) return(.ct_response_json(state$result))
  purrr::list_flatten(purrr::map(state$result, function(response) .ct_response_json(response)$records %||% list()))
}
