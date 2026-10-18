# Run from the package root after generate.R and verify.R. No real HTTP.
options(chet.replay.matrix = FALSE)
source('dev/specmill-rebuild/released-facades-v42/verify.R')
find <- function(name, args, status) {
  hit <- Filter(function(x) identical(x$name, name) && identical(x$args, args) &&
    identical(x$status, status) && is.null(x$payload), results)
  stopifnot(length(hit) == 1L)
  hit[[1L]]
}
counts <- names[[1L]]; page <- names[[2L]]
for (name in names) {
  for (input in list('one', 1L, c('one', 'one', NA, ''))) {
    for (status in list(200L, 404L, 500L, 'transport')) {
      stopifnot(find(name, list(input, NULL), status)$equal)
    }
  }
  for (input in list(c('one', 'two'), c(1L, 2L), list('one', 'two'))) {
    for (tail in list('chemical', '', c('a', 'b'), 'a/b', 'a b')) {
      x <- find(name, list(input, tail), 200L)
      stopifnot(x$equal, 'rlang_error' %in% x$candidate$error$class,
        startsWith(x$candidate$error$message, 'Cannot use path_params with batching.'),
        is.null(x$candidate$error$parent), !length(x$old_wire), !length(x$candidate_wire))
    }
    for (status in list(200L, 404L, 500L, 'transport')) {
      x <- find(name, list(input, NULL), status)
      stopifnot(x$equal, is.null(names(x$candidate$value)), identical(x$old$value, x$candidate$value),
        identical(x$old$error, x$candidate$error), identical(x$old$warnings, x$candidate$warnings),
        identical(x$old_wire, x$candidate_wire), length(x$candidate_wire) == 2L)
      if (status %in% c(404L, 500L)) stopifnot(length(x$candidate$warnings) == 2L)
    }
  }
  for (trailing in list('', 'a b')) {
    for (status in list(200L, 404L, 500L, 401L, 'transport')) {
      x <- find(name, list('one', trailing), status)
      if (identical(trailing, 'a b')) {
        stopifnot(x$equal, !length(x$old_wire), !length(x$candidate_wire),
          identical(x$candidate$error$location, 1L),
          'purrr_error_indexed' %in% x$candidate$error$class,
          'simpleError' %in% x$candidate$error$parent$class)
      } else if (!identical(status, 401L)) {
        stopifnot(x$equal, length(x$candidate_wire) == 1L,
          !endsWith(x$candidate_wire[[1L]]$url, '/'))
      }
    }
  }
  for (input in list(NULL, character())) {
    x <- find(name, list(input, NULL), 200L)
    stopifnot(x$equal, !length(x$candidate_wire),
      identical(x$candidate$error$message, 'Query must be a character vector.'))
  }
  for (input in list('one', c('one', 'two'))) {
    x <- find(name, list(input, NULL), 401L)
    stopifnot('specmill_call_error' %in% x$candidate$error$class,
      length(x$candidate_wire) == 1L)
  }
}

# Observe only the client validator. The helper, executor and hooks stay real.
preflight_checks <- function() {
  calls <- list(); requests <- 0L; statuses <- list(200L)
  validator <- runtime$.chet_validate_inputs
  on.exit(assign('.chet_validate_inputs', validator, runtime))
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests <<- requests + 1L
    status <- statuses[[min(requests, length(statuses))]]
    if (identical(status, 'transport')) stop(structure(list(message = 'transport sentinel', call = NULL, resp = NULL),
      class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition')))
    response <- httr2::response(status_code = status, headers = list(`Content-Type` = 'application/json'),
      body = charToRaw('{"data":[{"value":1}]}'))
    predicate <- req$policies$error_is_error
    if (is.null(predicate) || isTRUE(predicate(response))) httr2::resp_check_status(response)
    response
  }, .package = 'httr2')
  for (name in names) {
    primary <- names(formals(candidate[[name]]))[[1L]]
    trailing <- names(formals(candidate[[name]]))[[2L]]
    runtime$.chet_validate_inputs <- function(params) {
      calls[[length(calls) + 1L]] <<- params
      validator(params)
      list(ignored = 'validator return must not replace params')
    }
    calls <- list(); requests <- 0L
    result <- capture(candidate[[name]], list(list(1, 2, 1, NA, ''), NULL))
    stopifnot(is.null(result$error), length(calls) == 1L, requests == 2L,
      identical(calls[[1L]], setNames(list(c('1', '2'), NULL), c(primary, trailing))))
    calls <- list(); requests <- 0L
    result <- capture(candidate[[name]], list(c('one', 'one', NA, ''), 'suffix'))
    stopifnot(is.null(result$error), length(calls) == 1L, requests == 1L,
      identical(calls[[1L]], setNames(list('one', 'suffix'), c(primary, trailing))))
    calls <- list(); requests <- 0L
    result <- capture(candidate[[name]], list(c('one', 'two'), 'suffix'))
    stopifnot(!is.null(result$error), length(calls) == 1L, requests == 0L,
      identical(calls[[1L]], setNames(list(c('one', 'two'), 'suffix'), c(primary, trailing))))
    parent <- errorCondition('parent sentinel', class = 'preflight_parent')
    original <- errorCondition('preflight sentinel', class = 'preflight_sentinel', parent = parent)
    runtime$.chet_validate_inputs <- function(params) stop(original)
    actual <- tryCatch(candidate[[name]](c('one', 'two')), error = identity)
    stopifnot(identical(actual, original), requests == 0L)
    runtime$.chet_validate_inputs <- function(params) warning('preflight warning', call. = FALSE)
    result <- capture(candidate[[name]], list(c('one', 'two')))
    stopifnot(is.null(result$error), identical(result$warnings, 'preflight warning'), requests == 2L)
    runtime$.chet_validate_inputs <- validator
    for (middle in list(500L, 'transport')) {
      statuses <- list(200L, middle, 200L)
      requests <- 0L
      old <- capture(legacy[[name]], list(c('one', 'bad', 'two')))
      stopifnot(requests == 3L)
      requests <- 0L
      actual <- capture(candidate[[name]], list(c('one', 'bad', 'two')))
      stopifnot(requests == 3L, identical(actual$value, old$value),
        identical(actual$error, old$error), identical(actual$warnings, old$warnings),
        is.null(actual$error), length(actual$value) == 3L, is.null(actual$value[[2L]]),
        length(actual$warnings) == if (identical(middle, 500L)) 1L else 0L)
    }
    statuses <- list(200L)
    requests <- 0L
    withr::with_options(list(comptoxr_native.request = list(timeout = -1)), {
      error <- tryCatch(candidate[[name]](c('one', 'two')), error = identity)
      stopifnot(inherits(error, 'specmill_call_error'), grepl('timeout must be', conditionMessage(error)), requests == 0L)
    })
  }
}
preflight_checks()
cat('PASS: exact scalar/blank-suffix/malformed-space/preflight parity; exact multi-result values and attributes; typed single failures, zero-HTTP preflight, normalized full params, original validator conditions, ignored return, multiple drop/count/warnings, hard 401/config.\n')
