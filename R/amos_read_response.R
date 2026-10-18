.ct_amos_read_json <- function(response, context, decode) {
    observe_api_responses(list(response))
    if (context$status < 200L || context$status >= 300L) {
        if (context$status == 401L)
            decode()
        cli::cli_abort("Chemi API request to {.val {context$endpoint}} failed with status {context$status}")
    }
    body <- .ct_response_json(response)
    if (length(body))
        body
    else list()
}

.ct_amos_identifier_query <- function(query) {
  if (is.list(query) && !is.data.frame(query)) query <- unlist(query, use.names = FALSE)
  query <- unique(as.vector(query))
  query <- query[!is.na(query) & query != ""]
  if (!length(query)) cli::cli_abort("Either query or chemicals parameter must be provided.")
  query
}
