# Credential-free GET evidence only. Run from the package root.
pkgload::load_all(quiet = TRUE)
withr::local_options(list(comptoxr_native.request = list(max_retries = 0L, timeout = 20)))
cases <- list(
  metadata = list(path = '/metadata'),
  version = list(path = '/version'),
  curator_session = list(path = '/curators/me'),
  chemtemp_dtxsid = list(path = '/chemicals/chemtemp/dtxsid/DTXSID7020182'),
  chemtemp_casrn = list(path = '/chemicals/chemtemp/casrn/80-05-7'),
  download_omitted = list(path = '/chemicals/chemical_DL'),
  download_object = list(path = '/chemicals/chemical_DL', body = stats::setNames(list(), character())))
evidence <- lapply(cases, function(case) {
  request <- httr2::request(paste0('https://hcd.rtpnc.epa.gov/api/chet', case$path))
  if ('body' %in% names(case)) request <- httr2::req_body_json(request, case$body, auto_unbox = TRUE)
  request <- httr2::req_method(request, 'GET')
  response <- httr2::req_perform(httr2::req_error(httr2::req_timeout(request, 20), is_error = function(response) FALSE))
  list(method = 'GET', path = case$path, body = case$body,
    status = httr2::resp_status(response), headers = httr2::resp_headers(response),
    bytes = httr2::resp_body_raw(response))
})
saveRDS(list(time = format(Sys.time(), tz = 'UTC'), evidence = evidence),
  'dev/specmill-rebuild/chet-direct-reads/live.rds')
print(lapply(evidence, function(x) list(path = x$path, status = x$status,
  media = x$headers[['content-type']], bytes = length(x$bytes))))
