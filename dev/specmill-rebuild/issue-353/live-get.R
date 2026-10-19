# Audit the existing generated GET through live service calls; no localhost.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L)
library('ComptoxR', lib.loc = args[[1L]])
results <- list()
for (environment in c('development', 'production')) {
  origin <- if (environment == 'development') 'https://cim-dev.sciencedataexperts.com' else 'https://hcd.rtpnc.epa.gov'
  options(ComptoxR.chemi_burl = origin,
    comptoxr_native.request = list(max_retries = 0L, timeout = 30))
  for (headers in c(FALSE, TRUE)) {
    value <- chemi_toxprints('CCO', headers = headers,
      profile = if (headers) 'toxprint_V2_0_r711' else NULL)
    stopifnot(is.list(value), length(value) == 1L,
      identical(value[[1L]]$chemicals[[1L]]$smiles, 'CCO'),
      length(value[[1L]]$chemicals[[1L]]$descriptors) == 729L,
      identical(value[[1L]]$info$name, 'toxprints'))
    if (headers) stopifnot(length(value[[1L]]$headers) == 729L)
    results[[paste(environment, headers, sep = '-')]] <- list(
      at = format(Sys.time(), tz = 'UTC', usetz = TRUE), origin = origin,
      headers = headers, result = value)
  }
}
jsonlite::write_json(results, 'dev/specmill-rebuild/issue-353/installed-get-live.json',
  auto_unbox = TRUE, pretty = TRUE, null = 'null')
cat('Existing GET: live development/production, headers and explicit profile passed.\n')
