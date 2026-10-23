# Frozen originals versus generated candidates through the real client executor.
# Run from the package root after generate.R. No production requests.
suppressPackageStartupMessages(pkgload::load_all('.', quiet = TRUE))
directory <- 'dev/specmill-rebuild/released-facades-v42'
names <- c('chemi_chet_reaction_searchcounts', 'chemi_chet_reaction_database_old_by_pagenum_and_searchterm')
fixture <- 'dev/specmill-rebuild/rootheldrelease/originals.rds'
stopifnot(identical(digest::digest(file = fixture, algo = 'sha256'),
  '2c6b418a13a67dbe94ad7e9de7b5466348b4f551e73455fc2c8467ab80d8f802'))
runtime <- new.env(parent = asNamespace('ComptoxR'))
# Match namespace-local lookup without writing into the real package namespace.
runtime$format_legacy_list_result <- get('format_legacy_list_result', asNamespace('ComptoxR'))
sys.source('R/chet_facade_input_policy.R', runtime)
legacy <- lapply(readRDS(fixture), function(code) eval(code[[length(code)]][[3L]], asNamespace('ComptoxR')))
candidate <- lapply(names, function(name) {
  environment <- new.env(parent = asNamespace('ComptoxR'))
  sys.source(file.path('R', paste0(name, '.R')), environment)
  fn <- environment[[name]]
  environment(fn) <- runtime
  fn
})
names(candidate) <- names
condition_signature <- function(error) {
  if (is.null(error)) return(NULL)
  list(class = class(error), message = conditionMessage(error),
    parent = condition_signature(error$parent), location = error$location)
}
capture <- function(fn, args) {
  warnings <- character()
  value <- withCallingHandlers(tryCatch(suppressMessages(do.call(fn, args)), error = identity), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
  })
  list(value = if (!inherits(value, 'error')) value,
    error = if (inherits(value, 'error')) condition_signature(value), warnings = warnings)
}
run <- function() {
  requests <- list(); status <- 200L; payload <- '{"data":[{"value":1,"missing":null}]}'
  original <- structure(list(message = 'transport sentinel', call = NULL, resp = NULL),
    class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition'))
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- list(url = req$url, method = req$method, accept = req$headers$Accept, body = req$body)
    if (identical(status, 'transport')) stop(original)
    response <- httr2::response(status_code = status, headers = list(`Content-Type` = 'application/json'), body = charToRaw(payload))
    predicate <- req$policies$error_is_error
    if (is.null(predicate) || isTRUE(predicate(response))) httr2::resp_check_status(response)
    response
  }, .package = 'httr2')
  results <- list()
  for (name in names) {
    cat('Replaying', name, '\n')
    payload <- '{"data":[{"value":1,"missing":null}]}'
    stopifnot(identical(formals(legacy[[name]]), formals(candidate[[name]])))
    for (input in list('one', c('one', 'two'), c('one', 'one', NA, ''), NULL, character(), list('one', 'two'), 1L, c(1L, 2L))) {
      for (trailing in list(NULL, 'chemical', '', c('a', 'b'), 'a/b', 'a b')) {
        for (status in list(200L, 404L, 500L, 401L, 'transport')) {
          args <- list(input, trailing)
          requests <- list(); a <- capture(legacy[[name]], args); old_wire <- requests
          requests <- list(); b <- capture(candidate[[name]], args)
          results[[length(results) + 1L]] <- list(name = name, args = args, status = status,
            equal = identical(a, b) && identical(old_wire, requests), old = a, candidate = b,
            old_wire = old_wire, candidate_wire = requests)
        }
      }
    }
    status <- 200L
    for (payload in c('[{"value":1}]', '{"value":null}', '[]', 'null', '{')) {
      requests <- list(); a <- capture(legacy[[name]], list('one')); old_wire <- requests
      requests <- list(); b <- capture(candidate[[name]], list('one'))
      results[[length(results) + 1L]] <- list(name = name, args = list('one'), status = status, payload = payload,
        equal = identical(a, b) && identical(old_wire, requests), old = a, candidate = b,
        old_wire = old_wire, candidate_wire = requests)
    }
  }
  # Extra URL edge cases keep the original 490 diagnostics intact above.
  status <- 200L
  payload <- '{"data":[{"value":1,"missing":null}]}'
  for (name in names) {
    for (input in list('a b', 'café', 'a/b', c('a b', 'café'))) {
      for (trailing in list(NULL, '\t', '\n', 'café', '/', 'a//b', c('', 'a', ''), list('a', 'b'))) {
        requests <- list(); a <- capture(legacy[[name]], list(input, trailing)); old_wire <- requests
        requests <- list(); b <- capture(candidate[[name]], list(input, trailing))
        results[[length(results) + 1L]] <- list(name = name, args = list(input, trailing), status = status,
          edge = TRUE, equal = identical(a, b) && identical(old_wire, requests), old = a, candidate = b,
          old_wire = old_wire, candidate_wire = requests)
      }
    }
  }
  saveRDS(results, file.path(directory, 'results.rds'))
  cat('Cases:', length(results), 'exact matches:', sum(vapply(results, `[[`, FALSE, 'equal')), '\n')
  mismatch <- Filter(function(x) !x$equal, results)
  for (x in head(mismatch, 3)) print(x)
  invisible(results)
}
results <- if (isTRUE(getOption('chet.replay.matrix', TRUE))) run() else
  readRDS(file.path(directory, 'results.rds'))
