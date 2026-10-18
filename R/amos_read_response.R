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
