# Explicit production GET verification; excluded from the offline suite.
options(ComptoxR.run_verbose = FALSE)
pkgload::load_all('.', quiet = TRUE)
perform <- httr2::req_perform
wrappers <- list(
  chemi_chet_chemicals_counts = chemi_chet_chemicals_counts,
  chemi_chet_chemicals_database = chemi_chet_chemicals_database,
  chemi_chet_reaction_database = chemi_chet_reaction_database
)
report <- list(checked_at = format(Sys.time(), tz = 'UTC', usetz = TRUE), results = list())
for (name in names(wrappers)) {
  responses <- list()
  urls <- character()
  testthat::with_mocked_bindings(
    result <- wrappers[[name]](size = 1000L),
    req_perform = function(req, ...) {
      response <- perform(httr2::req_timeout(req, 60), ...)
      responses[[length(responses) + 1L]] <<- response
      urls <<- c(urls, req$url)
      response
    },
    .package = 'httr2'
  )
  bodies <- lapply(responses, httr2::resp_body_json, simplifyVector = FALSE)
  rows <- lapply(bodies, function(body) body[['data']] %||% body)
  pages <- vapply(urls, function(url) as.integer(httr2::url_parse(url)$query$page), integer(1), USE.NAMES = FALSE)
  expected <- lapply(unlist(rows, recursive = FALSE), function(row) {
    row[vapply(row, is.null, logical(1))] <- NA
    row
  })
  stopifnot(
    all(vapply(responses, httr2::resp_status, integer(1)) == 200L),
    all(grepl('/api/chet/', urls, fixed = TRUE)),
    identical(pages, seq_along(responses)),
    length(tail(rows, 1L)[[1L]]) == 0L,
    identical(result, expected)
  )
  total <- bodies[[1L]][['totallength']]
  if (!is.null(total)) stopifnot(length(result) == total)
  id_key <- intersect(c('chemical_ID', 'reaction_ID', 'lib_ID'), names(result[[1L]]))
  if (length(id_key)) {
    ids <- vapply(result, function(row) paste(unlist(row[id_key]), collapse = '/'), character(1))
    stopifnot(!anyDuplicated(ids))
  }
  report$results[[name]] <- list(
    urls = as.list(urls),
    statuses = as.list(vapply(responses, httr2::resp_status, integer(1))),
    pages = as.list(pages),
    page_rows = as.list(lengths(rows)),
    returned_rows = length(result),
    advertised_total = total,
    final_page_empty = TRUE,
    returned_rows_match_responses = TRUE,
    unique_id_field = if (length(id_key)) paste(id_key, collapse = '/') else NULL
  )
  jsonlite::write_json(report, 'dev/specmill-342/pagination-results.json', pretty = TRUE, auto_unbox = TRUE, null = 'null')
  message(name, ': ', length(result), ' rows; ', length(responses), ' requests; final page empty')
}
