# Read-only deployed GET protocol retrievals; IDs from recorded service listing.
work <- path.expand('~/.cache/comptoxr-specmill-finish/protocol-get-candidate')
reference <- 'dev/specmill-rebuild/canonical-holds-audit/protocol-paging-recheck'
env <- new.env(parent=globalenv())
for(file in c('api_validation.R','z_specmill_request.R','service_endpoints.R','api_auth.R','stdizer_protocol_policy.R','chemi_stdizer_protocols_by_id_get.R')) sys.source(file.path(work,'R',file),env)
fn <- env$chemi_stdizer_protocols_by_id_get
options(comptoxr_native.request = list(timeout = 25, max_retries = 0L))
results <- list()
for (stage in c('production', 'staging')) {
  initial <- jsonlite::read_json(file.path(reference, paste0(stage, '-GET-absent.json')))
  protocol <- sub('^.*/protocols/([^?]+).*$', '\\1', initial$url)
  origin <- sub('/api/.*$', '', initial$url)
  options(ComptoxR.chemi_burl = paste0(origin, '/api'))
  for (case in c('page0', 'page1', 'descending', 'multiple', 'empty-sort', 'absent')) {
    args <- switch(case,
      page0 = list(page = 0L, size = 1L), page1 = list(page = 1L, size = 1L),
      descending = list(page = 0L, size = 10L, sort = 'id,desc'),
      multiple = list(page = 0L, size = 10L, sort = c('type,asc', 'id,desc')),
      `empty-sort` = list(page = 0L, size = 10L, sort = ''), absent = list(sort = character()))
    value <- do.call(fn, c(list(id = protocol), args))
    expected <- jsonlite::read_json(file.path(reference, paste0(stage, '-GET-', case, '.json')))
    ids <- vapply(value$records, `[[`, '', 'id')
    stopifnot(identical(ids, vapply(expected$records, `[[`, '', 'id')),
      identical(value$id, protocol), identical(value$filteredNumber, 4L))
    results[[paste(stage, case, sep = '-')]] <- list(origin = origin, protocol = protocol,
      case = case, parameters = args, ids = as.list(ids), time_utc = format(Sys.time(), tz = 'UTC', usetz = TRUE))
  }
}
jsonlite::write_json(list(mode = 'isolated-official45-GET', calls = length(results), results = results),
  file.path(work, 'evidence/live.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS:', length(results), 'generated-wrapper deployed reads match recorded page/sort expectations.\n')
