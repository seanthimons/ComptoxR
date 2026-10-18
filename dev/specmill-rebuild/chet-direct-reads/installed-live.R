# Run after installing the final package into an isolated client library.
library(ComptoxR, lib.loc = commandArgs(TRUE)[[1L]])
options(comptoxr_native.request = list(max_retries = 0L, timeout = 20))
results <- list(metadata = chemi_chet_metadata(), version = chemi_chet_version(),
  session = chemi_chet_curators_me())
stopifnot(is.list(results$metadata), identical(results$version$name, 'pf_chemical_transformation_database'),
  identical(results$session, list(authenticated = FALSE, user = NULL)))
chemical <- tryCatch(chemi_chet_chemicals_chemtemp('dtxsid', 'DTXSID7020182'), error = identity)
if (inherits(chemical, 'error')) {
  stopifnot(inherits(chemical, 'httr2_http_500'), identical(httr2::resp_status(chemical$resp), 500L))
  results$temporary <- list(class = class(chemical), status = httr2::resp_status(chemical$resp),
    body = httr2::resp_body_string(chemical$resp))
} else results$temporary <- chemical
saveRDS(list(time = format(Sys.time(), tz = 'UTC'), results = results),
  'dev/specmill-rebuild/chet-direct-reads/installed-live.rds')
print(results)
