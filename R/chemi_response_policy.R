.ct_toxprint_query <- function(query) {
  query <- unique(as.vector(query))
  query <- query[!is.na(query) & query != ""]
  if (!length(query)) cli::cli_abort("Either query or chemicals parameter must be provided.")
  query
}
.ct_chemi_tidy <- function(response, context, decode) {
  observe_api_responses(list(response))
  body <- decode()
  if (!length(body)) return(tibble::tibble())
  if (!is.null(names(body)) && !is.data.frame(body)) return(safe_tidy_bind(body, names_to = "query_id"))
  result <- safe_tidy_bind(body)
  query <- context$query
  if (!is.null(query) && length(query) > 0 && nrow(result) == length(query) && !"dtxsid" %in% names(result)) result <- dplyr::bind_cols(dtxsid = query, result)
  result
}

 .ct_chemi_result <- function(response, context, decode, tidy = TRUE) {
    observe_api_responses(list(response))
    if (context$status < 200L || context$status >= 300L) {
        if (context$status == 401L)
            decode()
        cli::cli_abort("Chemi API request to {.val {context$endpoint}} failed with status {context$status}")
    }
    body <- .ct_response_json(response)
    if (!length(body))
        return(if (tidy) tibble::tibble() else list())
    if (!tidy)
        return(body)
    if (!is.null(names(body)) && !is.data.frame(body)) {
        return(safe_tidy_bind(body, names_to = "query_id"))
    }
    result <- safe_tidy_bind(body)
    if (length(context$query) && nrow(result) == length(context$query) && !"dtxsid" %in% names(result)) {
        result <- dplyr::bind_cols(dtxsid = context$query, result)
    }
    result
}
