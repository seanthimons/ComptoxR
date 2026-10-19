# Only read-only protocol searches; identifiers come from the service listing.
out <- 'dev/specmill-rebuild/canonical-holds-audit/protocol-paging-recheck'
mode <- commandArgs(TRUE)[[1L]]
if (mode == 'candidate') {
  env <- new.env(parent = globalenv())
  for (file in c('R/api_validation.R', 'R/z_specmill_request.R', 'R/service_endpoints.R', 'R/api_auth.R', 'R/stdizer_protocol_policy.R')) sys.source(file, env)
  sys.source(path.expand('~/.cache/comptoxr-specmill-finish/protocol-search-candidate/R/chemi_stdizer_protocols_by_id_post.R'), env)
  fn <- env$chemi_stdizer_protocols_by_id_post
} else {
  stopifnot(mode == 'root')
  pkgload::load_all('.', quiet = TRUE)
  fn <- get('chemi_stdizer_protocols_by_id_post', asNamespace('ComptoxR'))
}
options(comptoxr_native.request = list(timeout = 25, max_retries = 0L))
results <- list()
for (stage in c('production', 'staging')) {
  initial <- jsonlite::read_json(file.path(out, paste0(stage, '-POST-absent.json')))
  protocol <- sub('^.*/protocols/([^?]+).*$', '\\1', initial$url)
  origin <- sub('/api/.*$', '', initial$url)
  options(ComptoxR.chemi_burl = origin)
  for (case in c('page0', 'page1', 'descending', 'multiple', 'empty-sort', 'absent')) {
    args <- switch(case,
      page0 = list(page = 0L, size = 1L), page1 = list(page = 1L, size = 1L),
      descending = list(page = 0L, size = 10L, sort = 'id,desc'),
      multiple = list(page = 0L, size = 10L, sort = c('type,asc', 'id,desc')),
      `empty-sort` = list(page = 0L, size = 10L, sort = ''), absent = list(sort = character()))
    value <- do.call(fn, c(list(id = protocol, body = list()), args))
    expected <- jsonlite::read_json(file.path(out, paste0(stage, '-POST-', case, '.json')))
    ids <- vapply(value$records, `[[`, '', 'id')
    stopifnot(identical(ids, vapply(expected$records, `[[`, '', 'id')),
      identical(value$id, protocol), identical(value$filteredNumber, 4L))
    results[[paste(stage, case, sep = '-')]] <- list(origin = origin, protocol = protocol,
      case = case, parameters = args, ids = as.list(ids), time_utc = format(Sys.time(), tz = 'UTC', usetz = TRUE))
  }
}
jsonlite::write_json(list(mode = mode, calls = length(results), results = results),
  file.path(out, paste0(mode, '-live.json')), auto_unbox = TRUE, pretty = TRUE)
cat('PASS:', length(results), 'generated-wrapper deployed reads match recorded page/sort expectations.\n')
