test_that('native hazard GET preserves scalar requests, formatting and hook failure stages', {
  ns <- asNamespace('ComptoxR')
  fixture <- readRDS(test_path('fixtures/native-resolved-chemical-contracts.rds'))
  legacy <- eval(fixture$legacy$chemi_hazard[[3L]], ns)
  sample <- eval(fixture$hazard_sample, ns)
  bodies <- c(
    vapply(
      list(sample(FALSE), list(value = 1L), list(), NULL),
      function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = 'null')),
      ''
    ),
    '{'
  )
  wire <- trace <- list()
  original_hook <- get('run_hook', ns)
  local_mocked_bindings(
    run_hook = function(name, stage, data) {
      trace[[length(trace) + 1L]] <<- list(name = name, stage = stage, params = data$params)
      original_hook(name, stage, data)
    },
    .package = 'ComptoxR'
  )
  status <- 200L
  body <- NULL
  local_mocked_bindings(
    req_perform = function(req, ...) {
      wire[[length(wire) + 1L]] <<- list(url = req$url, accept = req$headers$Accept)
      response <- httr2::response(
        status_code = status,
        headers = list(`Content-Type` = 'application/json'),
        body = charToRaw(body)
      )
      predicate <- req$policies$error_is_error
      if (is.null(predicate) || predicate(response)) {
        httr2::resp_check_status(response)
      }
      response
    },
    .package = 'httr2'
  )
  invoke <- function(fn, args) {
    wire <<- trace <<- list()
    warnings <- character()
    value <- withCallingHandlers(
      tryCatch(suppressMessages(do.call(fn, args)), error = identity),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart('muffleWarning')
      }
    )
    list(
      value = if (!inherits(value, 'error')) value,
      error = if (inherits(value, 'error')) {
        list(class = class(value), location = value$location, parent = class(value$parent))
      },
      warnings = warnings,
      wire = wire,
      trace = trace
    )
  }
  for (status in c(200L, 404L, 500L)) {
    for (body in bodies) {
      for (args in list(
        list('one'),
        list('one', FALSE),
        list('one', NULL),
        list(NULL),
        list('one', format = 'raw'),
        list('one', format = 'tidy'),
        list('one', format = 'compact'),
        list('one', format = 'bad')
      )) {
        expect_identical(invoke(chemi_hazard, args), invoke(legacy, args))
      }
    }
  }
  # Vector queries are invalid in httr2; the two entry points report different indices.
  for (fn in list(legacy, chemi_hazard)) {
    wire <- list()
    expect_error(fn(c('one', 'two')))
    expect_length(wire, 0L)
  }
  expect_identical(formals(chemi_hazard), formals(legacy))
})
