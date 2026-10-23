# Standalone adoption check for Specmill #145; intentionally fails until released support is adopted.
suppressMessages(devtools::load_all('.', quiet = TRUE))
namespace <- asNamespace('ComptoxR')
legacy_expression <- readRDS('dev/specmill-rebuild/legacy-classyfire-transport.rds')
legacy <- eval(legacy_expression[[3L]], namespace)
local({
  testthat::local_mocked_bindings(
    req_perform = function(...) stop('transport sentinel'), .package = 'httr2'
  )
  capture <- function(fn) {
    tryCatch(suppressWarnings(suppressMessages(fn('one'))), error = identity)
  }
  old <- capture(legacy)
  current <- capture(chemi_classyfire)
  stopifnot(inherits(old, 'error'))
  if (!inherits(current, 'error')) {
    stop('Specmill #145: a single Classyfire transport failure returned an ordinary result instead of aborting.')
  }
})
cat('PASS single-request transport failures remain hard errors.\n')
