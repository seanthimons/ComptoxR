# Reproduce the old mock artifact without touching either client executor.
executor_check <- function() {
  requests <- 0L
  sequential <- httr2::req_perform_sequential
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests <<- requests + 1L
    httr2::response(status_code = 200L, body = charToRaw('{}'))
  }, .package = 'httr2')
  reqs <- setNames(rep(list(httr2::request('https://executor.invalid')), 2L), c('1', '2'))
  actual <- httr2::req_perform_sequential(reqs, on_error = 'continue', progress = FALSE)
  bad_mock <- lapply(reqs, httr2::req_perform)
  stopifnot(is.null(names(actual)), identical(names(bad_mock), c('1', '2')),
    requests == 4L, identical(sequential, httr2::req_perform_sequential))
  cat('PASS: real sequential responses are unnamed; prior lapply mock preserves names.\n')
}
executor_check()
