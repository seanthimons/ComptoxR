# Pure preflight on complete normalized parameters, before hooks and fan-out.
.chet_validate_inputs <- function(params) {
  trailing <- c(params[[2L]])
  if (length(trailing) && length(params[[1L]]) > 1L)
    cli::cli_abort('Cannot use path_params with batching. Path parameter endpoints do not support batch queries.')
  endpoint <- if (identical(names(params)[[1L]], 'search_input'))
    'chet/reaction/searchcounts/' else 'chet/reaction/database-old/'
  # Legacy URL parsing happens during request construction, outside the drop handler.
  purrr::map(as.list(params[[1L]]), function(query_part) {
    req <- httr2::req_url_path_append(httr2::request(.endpoint_url('chemi_burl')), endpoint)
    req <- httr2::req_url_path_append(req, curl::curl_escape(as.character(query_part)))
    for (pp in trailing) req <- httr2::req_url_path_append(req, as.character(pp))
    curl::curl_parse_url(req$url)
    invisible(NULL)
  })
  invisible(NULL)
}
