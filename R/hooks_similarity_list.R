# Resolve the two independent inputs of the similarity-list calculation.
similarity_list_resolve <- function(ids, id_type) {
  resolved <- chemi_resolver_lookup_bulk(ids = ids, idsType = id_type, tidy = FALSE)
  found <- purrr::keep(resolved, function(item) item$result %in% c("FOUND", "CONVERTED"))
  purrr::map(found, function(item) chemical_record_from_resolver_item(item)$chemical)
}

resolve_similarity_reference <- function(data) {
  if (isTRUE(data$skip_request)) return(data)
  params <- data$params
  if (!is.character(params$main) || length(params$main) != 1L ||
      is.na(params$main) || !nzchar(trimws(params$main))) {
    cli::cli_abort("main must be one nonempty chemical identifier")
  }
  if (!is.character(params$query) || length(params$query) < 1L ||
      length(params$query) > 1000L || anyNA(params$query) ||
      any(!nzchar(trimws(params$query)))) {
    cli::cli_abort("query must contain 1 to 1000 nonempty chemical identifiers")
  }
  for (field in c("fingerprintName", "scoreName")) {
    value <- params[[field]]
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !nzchar(trimws(value)) || nchar(value) > 100L) {
      cli::cli_abort("{field} must be one nonempty string of at most 100 characters")
    }
  }
  reference <- similarity_list_resolve(params$main, params$idType)
  if (length(reference) != 1L) {
    cli::cli_abort("main must resolve to exactly one chemical")
  }
  data$params$reference_chemical <- reference[[1L]]
  data
}

resolve_similarity_candidates <- function(data) {
  if (isTRUE(data$skip_request)) return(data)
  chemicals <- similarity_list_resolve(data$params$query, data$params$idType)
  if (!length(chemicals)) {
    cli::cli_warn("No candidate chemicals could be resolved")
    data$skip_request <- TRUE
    data$result <- NULL
    return(data)
  }
  if (length(chemicals) > 1000L) {
    cli::cli_abort("query resolved to more than 1000 candidate chemicals")
  }
  data$params$candidate_chemicals <- chemicals
  data
}
