# Run against any proposed native lookup adoption before changing the release pin.
suppressMessages(devtools::load_all('.', quiet = TRUE))
local({
  requests <- 0L
  testthat::local_mocked_bindings(req_perform = function(...) {
    requests <<- requests + 1L
    stop('HTTP must not run for these inputs')
  }, .package = 'httr2')
  capture <- function(expr) tryCatch(expr, error = identity)
  early <- capture(chemi_resolver_lookup_bulk(NULL, idsType = stop('idsType evaluated')))
  blank <- capture(chemi_resolver_lookup_bulk(c('', NA), tidy = stop('tidy evaluated')))
  option <- capture(chemi_resolver_lookup_bulk(c('', NA), idsType = stop('idsType evaluated')))
  stopifnot(
    inherits(early, 'error'),
    conditionMessage(early) == 'ids must be a non-empty character vector',
    inherits(blank, 'error'),
    conditionMessage(blank) == 'Either query or chemicals parameter must be provided.',
    inherits(option, 'error'), conditionMessage(option) == 'idsType evaluated',
    requests == 0L
  )
})
cat('PASS lookup guard and option evaluation order without HTTP.\n')
