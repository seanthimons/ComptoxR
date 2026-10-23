# Explicit read-only calculation probes. No identifiers requiring CTX resolution.
probe_calculation_facades <- function() {
  pkgload::load_all('.', quiet = TRUE)
  withr::local_options(list(ComptoxR.chemi_burl = 'https://hcd.rtpnc.epa.gov/api',
    comptoxr_native.request = list(max_retries = 0L, timeout = 30)))
  ns <- asNamespace('ComptoxR'); responses <- list()
  observer <- ns$observe_api_responses
  testthat::local_mocked_bindings(observe_api_responses = function(x) {
    responses <<- c(responses, lapply(x, function(response) list(
      status = httr2::resp_status(response), url = response$url,
      media = httr2::resp_header(response, 'content-type'), body = httr2::resp_body_raw(response))))
    observer(x)
  }, .package = 'ComptoxR')
  names <- c('chemi_padel', 'chemi_padel_bulk', 'chemi_rdkit', 'chemi_rdkit_bulk',
    'chemi_webtest', 'chemi_webtest_bulk')
  results <- list()
  for (name in names) {
    fn <- get(name, ns)
    stopifnot(any(grepl('.ct_request', deparse(body(fn)), fixed = TRUE)))
    args <- list('CCO')
    responses <- list(); warnings <- character()
    value <- withCallingHandlers(tryCatch(do.call(fn, args), error = identity),
      warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning') })
    results[[name]] <- list(args = args, responses = responses, warnings = warnings,
      value = if (!inherits(value, 'error')) value,
      error = if (inherits(value, 'error')) list(class = class(value), message = conditionMessage(value)))
    cat(name, ': ', if (inherits(value, 'error')) class(value)[1L] else paste(nrow(value), 'rows'),
      '; HTTP ', paste(vapply(responses, `[[`, 0L, 'status'), collapse = ','), '\n', sep = '')
  }
  saveRDS(list(time = format(Sys.time(), tz = 'UTC'), baseline = system2('git', c('rev-parse', 'HEAD'), stdout = TRUE),
    results = results), 'dev/specmill-rebuild/calculation-facades/live-six.rds', version = 2)
  stopifnot(all(vapply(results, function(x) is.null(x$error) && nrow(x$value) == 1L &&
    identical(x$value$status, 'ok') && all(is.na(x$value$error)) && ncol(x$value) > 10L &&
    length(x$responses) == 1L && x$responses[[1L]]$status == 200L, FALSE)))
}
probe_calculation_facades()
