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

.ct_http_policy_ct_chemical_search_equal_bulk <- function(response, context, decode) .ct_batch_http_response(response,
    context, decode, .ct_tidy, "chemical/search/equal/")

format_legacy_list_result <- function(data) {
    inputs <- data$params[[1L]]
    completed <- vapply(data$result, function(chunk) as.character(chunk$input), "")
    parts <- purrr::map(inputs, function(input) {
        index <- match(input, completed)
        if (is.na(index))
            return(NULL)
        chunk <- data$result[[index]]
        response <- chunk$response
        status <- httr2::resp_status(response)
        if (status < 200L || status >= 300L) {
            endpoint <- chunk$endpoint
            cli::cli_warn("API request to {.val {endpoint}} failed for {.val {input}} with status {status}")
            return(NULL)
        }
        body <- unwrap_collection_envelope(.ct_response_json(response))
        if (is.list(body))
            attr(body, "query") <- input
        if (is.list(body) && !is.null(names(body)))
            body <- list(body)
        body
    })
    result <- purrr::list_flatten(parts)
    if (!length(result)) {
        endpoint <- data$result[[1L]]$endpoint
        cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
        return(list())
    }
    purrr::map(result, function(x) {
        if (is.list(x) && length(x))
            x[purrr::map_lgl(x, is.null)] <- NA
        x
    })
}

.ct_collect_response <- function(response, context, decode, count, endpoint) {
    observe_api_responses(list(response))
    if (context$status == 401L || (context$status >= 400L && count == 1L))
        decode()
    list(list(input = unlist(context$query, use.names = FALSE), response = response, endpoint = endpoint))
}

format_image_results <- function(data) {
    inputs <- data$params[[1L]]
    completed <- vapply(data$result, function(chunk) as.character(chunk$input), "")
    result <- purrr::map(inputs, function(input) {
        index <- match(input, completed)
        if (is.na(index))
            return(NULL)
        chunk <- data$result[[index]]
        response <- chunk$response
        status <- httr2::resp_status(response)
        if (status < 200L || status >= 300L) {
            endpoint <- chunk$endpoint
            cli::cli_warn("API request to {.val {endpoint}} failed for {.val {input}} with status {status}")
            return(NULL)
        }
        media <- tolower(trimws(sub(";.*$", "", httr2::resp_header(response, "content-type") %||% "")))
        fallback <- if (startsWith("image/png", media) && !httr2::resp_has_body(response))
            NULL
        else httr2::resp_body_raw(response)
        tryCatch(magick::image_read(httr2::resp_body_raw(response)), error = function(error) fallback)
    })
    if (length(result) == 1L)
        return(result[[1L]])
    result
}


.ct_static_json_result <- function(response, context, decode, endpoint, input = "_static_") {
    if (context$status >= 400L) decode()
    observe_api_responses(list(response))
    format_legacy_list_result(list(params = list(input), result = list(list(
        input = input, response = response, endpoint = endpoint))))
}

.ct_chet_image_result <- function(response, context, decode) {
    if (context$status >= 400L) return(.ct_static_json_result(response, context, decode, "chet/chemicals", context$query[[1L]]))
    if (!grepl("^(image/|text/|application/(pdf|csv))", context$media)) {
        return(format_legacy_list_result(list(params = list(context$query[[1L]]),
            result = .ct_collect_response(response, context, decode, 1L, "chet/chemicals"))))
    }
    observe_api_responses(list(response))
    value <- .ct_response_delimited(response, context, decode)
    if (startsWith(context$media, "image/")) {
        return(tryCatch(magick::image_read(httr2::resp_body_raw(response)), error = function(e) value))
    }
    value
}
