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
