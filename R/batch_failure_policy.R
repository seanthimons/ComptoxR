.ct_legacy_list_chunks <- function(response, context, decode) {
    observe_api_responses(list(response))
    body <- unwrap_collection_envelope(decode())
    input <- unlist(context$query, use.names = FALSE)
    if (length(input) == 1L && is.list(body)) 
        attr(body, "query") <- input[1L]
    if (is.list(body) && !is.null(names(body))) 
        body <- list(body)
    list(list(input = input, records = body))
}

format_legacy_list_result <- function(data) {
    inputs <- data$params[[1L]]
    completed <- vapply(data$result, function(chunk) chunk$input, "")
    bodies <- lapply(inputs, function(input) {
        index <- match(input, completed)
        if (!is.na(index)) 
            data$result[[index]]$records
        else NULL
    })
    if (length(bodies) > 1L) 
        names(bodies) <- as.character(seq_along(bodies))
    result <- purrr::list_flatten(bodies)
    if (length(result)) 
        result
    else list()
}

.ct_batch_http_response <- function(response, context, decode, formatter, endpoint) {
    if (context$status >= 400L && context$status != 401L) {
        observe_api_responses(list(response))
        stop(errorCondition(paste0("HTTP ", context$status, " response"), status = context$status, endpoint = endpoint, 
            class = "comptoxr_http_result_error"))
    }
    tryCatch(formatter(response, context, decode), error = function(error) .ct_response_error(error, 
        context))
}

.ct_batch_http_warning <- function(error, items) {
    if (!inherits(error, "comptoxr_http_result_error")) 
        return(NULL)
    endpoint <- error$endpoint
    status <- error$status
    label <- if (length(items)) 
        items[[1L]]
    else endpoint
    cli::format_warning("API request to {.val {endpoint}} failed for {.val {label}} with status {status}")
}

.ct_http_policy_chemi_classyfire <- function(response, context, decode) .ct_batch_http_response(response, 
    context, decode, .ct_tidy, "amos/get_classification_for_dtxsid/")

.ct_http_policy_ct_chemical_detail_search_bulk <- function(response, context, decode) .ct_batch_http_response(response, 
    context, decode, .ct_tidy, "chemical/detail/search/by-dtxsid/")

.ct_http_policy_ct_chemical_detail_search_by_dtxcid <- function(response, context, decode) .ct_batch_http_response(response, 
    context, decode, .ct_tidy, "chemical/detail/search/by-dtxcid/")

.ct_http_policy_ct_chemical_detail_search_by_dtxcid_bulk <- function(response, context, decode) .ct_batch_http_response(response, 
    context, decode, .ct_tidy, "chemical/detail/search/by-dtxcid/")

.ct_http_policy_chemi_amos_get_info_by_id <- function(response, context, decode) .ct_batch_http_response(response, 
    context, decode, .ct_legacy_list_chunks, "amos/get_info_by_id/")

.ct_http_policy_chemi_alerts_groups_by_id <- function(response, context, decode) .ct_batch_http_response(response, 
    context, decode, .ct_legacy_list_chunks, "alerts/groups/")

.ct_http_policy_ct_chemical_search_equal_bulk <- function(response, context, decode) .ct_batch_http_response(response, 
    context, decode, .ct_tidy, "chemical/search/equal/")

