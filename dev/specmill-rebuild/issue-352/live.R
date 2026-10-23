# Read/calculation requests only; compare actual resolver + generated safety calls.
devtools::load_all(quiet = TRUE)
sids <- c('DTXSID0020153', 'DTXSID0020600', 'DTXSID0022018')
results <- list()
for (environment in c('staging', 'production')) {
  url <- if (environment == 'staging') 'https://cim.sciencedataexperts.com/api' else 'https://hcd.rtpnc.epa.gov/api'
  options(ComptoxR.chemi_burl = url,
    comptoxr_native.request = list(timeout = 30, max_retries = 0L))
  value <- chemi_safety_rqcodes(sids)
  stopifnot(identical(value$sid, sids[c(1, 3)]),
    identical(value$rq_lbs, c(100, 1)), identical(value$rq_kgs, c(45.4, 0.454)))
  results[[environment]] <- list(at = format(Sys.time(), tz = 'UTC', usetz = TRUE), url = url, result = value)
  cat(environment, '\n'); print(value)
}
jsonlite::write_json(results, 'dev/specmill-rebuild/issue-352/live-results.json', auto_unbox = TRUE, pretty = TRUE)
