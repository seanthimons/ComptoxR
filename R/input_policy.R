# Match the input cleanup of the retained generic_request facade before validation.
.ct_legacy_query <- function(query) {
  if (purrr::is_list(query) && !is.data.frame(query)) {
    query <- as.character(unlist(query, use.names = FALSE))
  }
  query <- unique(as.vector(query))
  query <- query[!is.na(query) & query != ""]
  if (!length(query)) cli::cli_abort("Query must be a character vector.")
  query
}

 .ct_lookup_ids <- function(ids) {
    if (is.null(ids) || !length(ids))
        cli::cli_abort("ids must be a non-empty character vector")
    as.character(ids)
}

 prepare_lookup_request <- function(data) {
    ids <- unique(as.vector(data$params$ids))
    ids <- ids[!is.na(ids) & ids != ""]
    data$params$ids <- ids
    data
}

 .ct_lookup_body <- function(params) {
    if (!length(params$ids))
        cli::cli_abort("Either query or chemicals parameter must be provided.")
    c(list(ids = as.list(params$ids)), params[c("idsType", "fuzzy", "mol")], Filter(Negate(is.null),
        params[c("filters", "format")]))
}
