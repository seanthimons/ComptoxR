# Request bodies now follow their declared schema; native_resolved_payloads asserts those fields.
test_that("similarity map preserves private pre state, partial updates and public post state", {
  ns <- asNamespace('ComptoxR')
  legacy <- eval(readRDS(test_path('fixtures/native-similaritymap-state.rds'))$legacy[[3L]], ns)
  variants <- list(
    identity = function(data) data,
    partial = function(data) {
      data$params <- list(section = 'reviewed')
      data
    },
    private = function(data) {
      data$params$chemicals <- list(list(sid = 'flat-one'), list(sid = 'flat-two'))
      data
    },
    skip = function(data) list(skip_request = TRUE, result = list(skipped = TRUE)),
    nullquery = function(data) {
      data$params$query <- NULL
      data$params$chemicals <- list(list(sid = 'resolved'))
      data
    },
    nullparams = function(data) {
      data$params <- NULL
      data
    },
    unknown = function(data) {
      data$params$unknown <- 'ignored'
      data
    }
  )
  results <- list()
  for (v in names(variants)) {
    for (args in list(
      list(query = 'CCO'),
      list(query = c('one', 'one', NA, ''), sort = TRUE, format = 'raw'),
      list(query = 'CCO', section = NULL, sort = NULL),
      list(query = 'CCO', section = 'x', sort = 'TRUE'),
      list(query = NULL),
      list(query = character())
    )) {
      local({
        trace <- list()
        wire <- list()
        testthat::local_mocked_bindings(
          run_hook = function(name, stage, data) {
            trace[[length(trace) + 1L]] <<- list(name = name, stage = stage, data = data)
            if (stage == 'pre_request') variants[[v]](data) else list(post_result = data$result)
          },
          .package = 'ComptoxR'
        )
        testthat::local_mocked_bindings(
          req_perform = function(req, ...) {
            wire[[length(wire) + 1L]] <<- list(url = req$url, accept = req$headers$Accept, body = NULL)
            httr2::response(
              status_code = 200L,
              headers = list(`Content-Type` = 'application/json'),
              body = charToRaw('{"order":[],"similarity":[]}')
            )
          },
          .package = 'httr2'
        )
        invoke <- function(fn) {
          trace <<- wire <<- list()
          warnings <- character()
          value <- withCallingHandlers(
            tryCatch(suppressMessages(do.call(fn, args)), error = identity),
            warning = function(w) {
              warnings <<- c(warnings, conditionMessage(w))
              invokeRestart('muffleWarning')
            }
          )
          list(
            value = if (inherits(value, 'error')) NULL else value,
            error = if (inherits(value, 'error')) list(class = class(value), message = conditionMessage(value)),
            warnings = warnings,
            trace = trace,
            wire = wire
          )
        }
        a <- invoke(legacy)
        b <- invoke(chemi_resolver_getsimilaritymap)
        results[[length(results) + 1L]] <<- list(variant = v, args = args, old = a, new = b, equal = identical(a, b))
        expect_identical(a, b, info = paste(v, paste(args, collapse = "|")))
      })
    }
  }
  expect_identical(formals(legacy), formals(chemi_resolver_getsimilaritymap))
})

test_that("similarity map keeps real resolution and format hooks around native HTTP", {
  ns <- asNamespace('ComptoxR')
  legacy <- eval(readRDS(test_path('fixtures/native-similaritymap-state.rds'))$legacy[[3L]], ns)
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(
        list(result = 'FOUND', chemical = list(chemId = 'ONE', canonicalSmiles = 'C')),
        list(result = 'FOUND', chemical = list(chemId = 'TWO', canonicalSmiles = 'CC'))
      )
    },
    .package = 'ComptoxR'
  )
  json <- '{"order":[{"chemical":{"sid":"ONE","name":"A"}},{"chemical":{"sid":"TWO","name":"B"}}],"similarity":[[{"sim":0},{"sim":0.25}],[{"sim":0.25},{"sim":0}]]}'
  requests <- list()
  local_mocked_bindings(
    req_perform = function(req, ...) {
      requests[[length(requests) + 1L]] <<- list(url = req$url, body = NULL)
      httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'), body = charToRaw(json))
    },
    .package = 'httr2'
  )
  for (format in c('cluster', 'long', 'raw', 'invalid')) {
    invoke <- function(fn) {
      requests <<- list()
      value <- tryCatch(fn(c('one', 'two'), format = format), error = identity)
      list(
        result = if (inherits(value, 'error')) NULL else value,
        error = if (inherits(value, 'error')) list(class = class(value), message = conditionMessage(value)),
        requests = requests
      )
    }
    expect_identical(invoke(chemi_resolver_getsimilaritymap), invoke(legacy), info = format)
  }
})
