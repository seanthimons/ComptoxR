.ct_keyset_page <- function(response, context, decode) {
    observe_api_responses(list(response))
    tryCatch(decode(), error = function(error) .ct_response_error(error, context))
}

.ct_keyset_manual <- function(response, context, decode) {
    body <- decode()
    records <- unwrap_collection_envelope(body)
    if (is.list(records) && is.null(names(records)) && !length(records)) {
        endpoint <- context$endpoint
        cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
    }
    if (is.null(context$query)) {
        body <- unwrap_collection_envelope(body)
        if (is.null(body))
            return(list(NULL))
        if (is.list(body) && !length(body) && !is.null(names(body)))
            return(list(body))
        return(.ct_request_records(body, null_to_na = TRUE))
    }
    .ct_list(response, context, function() body)
}

.ct_keyset_items <- function(page) {
    if (is.null(page))
        return(list(NULL))
    if (is.list(page) && !is.null(names(page))) {
        page <- if (!is.null(page$results))
            page$results
        else if (!is.null(page$records))
            page$records
        else list(page)
    }
    .ct_request_records(page, null_to_na = TRUE)
}

.ct_keyset_next <- function(page) page$pagination$nextCursor

.ct_keyset_done <- function(page, state) identical(page$pagination$hasNext, FALSE)

.ct_keyset_limit_warning <- function(paged, limit) {
    cli::cli_warn(c("Pagination stopped at {.val {limit}} page{?s} (the {.arg max_pages} limit).", i = "More data may be available. Increase {.arg max_pages} to fetch additional pages."))
}

format_legacy_pager_result <- function(data) {
    if (!length(data$result)) {
        endpoint <- switch(data$fn_name, chemi_chet_chemicals_counts = "chet/chemicals/counts", chemi_chet_chemicals_database = "chet/chemicals/database",
            chemi_chet_reaction_database = "chet/reaction/database", chemi_resolver_classyfire = "resolver/classyfire",
            paste0(sub("^chemi_amos_", "amos/", sub("_bulk$", "", data$fn_name)), "/"))
        cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
    }
    data$result
}

.ct_chemi_page <- function(response, context, decode) {
    observe_api_responses(list(response))
    tryCatch({
        body <- decode()
        spring <- identical(context$endpoint, "resolver/classyfire")
        records <- if (spring) {
            if (is.null(body$content))
                list()
            else body$content
        }
        else if (!is.null(body$data))
            body$data
        else body
        result <- .ct_request_records(records, null_to_na = TRUE)
        attr(result, "paging") <- list(spring = spring, last = body$last, totalPages = body$totalPages)
        result
    }, error = function(error) .ct_response_error(error, context))
}

.ct_chemi_done <- function(response, state) {
    metadata <- attr(response, "paging")
    if (isTRUE(metadata$spring)) {
        isTRUE(metadata$last) || (!is.null(metadata$totalPages) && state$requests >= metadata$totalPages)
    }
    else !length(response)
}

