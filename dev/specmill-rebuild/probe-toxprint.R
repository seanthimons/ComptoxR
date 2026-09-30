# Replay the reviewed retained mapping against the pinned renderer and original.
source('dev/install_specmill.R')
verify_specmill()
pkgload::load_all(quiet = TRUE)
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
stopifnot(identical(digest::digest(file = 'R/chemi_toxprint.R', algo = 'sha256'),
  '957f17fcfcd470b83ee911a728c3bb31d3bf6f3a6175da7750f9b2746b47be24'))
service_file <- 'apis/chemi-toxprint-prod-rebuild.yml'
project <- specmill::load_project('.', callbacks = callbacks)
service <- Filter(function(x) x$id == 'chemi-toxprint-prod-rebuild', project$services)[[1L]]
native <- specmill::read_operations(service$files, policy = service$policy)
stopifnot(length(native$diagnostics) == 1L)
reviewed <- specmill:::read_service_operations(service)
stopifnot(length(reviewed$diagnostics) == 0L, length(reviewed$retained_diagnostics) == 1L)
mapped <- specmill:::configure_operation(reviewed$operations[[1L]], service)
code <- specmill::render_operation(mapped$operation, mapped$spec)
env <- new.env(parent = asNamespace('ComptoxR'))
eval(parse(text = code), env)
original <- ComptoxR::chemi_toxprint
candidate <- env$chemi_toxprint
stopifnot(identical(formals(original), formals(candidate)))
error <- function(fun, expr) tryCatch(eval(substitute(expr), list(fun = fun)), error = conditionMessage)
old_error <- error(original, fun(NULL, odds_ratio = stop('option evaluated')))
new_error <- error(candidate, fun(NULL, odds_ratio = stop('option evaluated')))
stopifnot(identical(old_error, 'Either query or chemicals parameter must be provided.'),
  identical(new_error, 'option evaluated'))
# The same result object does not preserve an invisible helper return.
response <- structure(list(score = 0, flag = FALSE), class = 'toxprint_probe')
env$generic_chemi_request <- function(...) invisible(response)
original_env <- new.env(parent = asNamespace('ComptoxR'))
original_env$generic_chemi_request <- env$generic_chemi_request
environment(original) <- original_env
old_visible <- withVisible(original('one'))
new_visible <- withVisible(candidate('one'))
stopifnot(identical(old_visible$value, new_visible$value), !old_visible$visible, new_visible$visible)
# Existing object/from bindings faithfully describe successful helper calls.
variants <- list(defaults = list(query = 'one'),
  null = list(query = 'one', odds_ratio = NULL, p_val = NULL, true_pos = NULL),
  falsy = list(query = FALSE, odds_ratio = FALSE, p_val = 0, true_pos = 0),
  mixed = list(query = c('one', 'two'), odds_ratio = NULL, p_val = FALSE, true_pos = 0),
  nested = list(query = 'one', odds_ratio = list(absent = NULL, flag = FALSE, count = 0)))
capture <- function(fun, target, inputs) {
  arguments <- NULL
  target$generic_chemi_request <- function(...) { arguments <<- list(...); response }
  value <- do.call(fun, inputs)
  list(arguments = arguments, value = value)
}
for (inputs in variants) {
  stopifnot(identical(capture(original, original_env, inputs), capture(candidate, env, inputs)))
}
# Capture the fixed contract from the unchanged original, not the rendered proposal.
inputs <- list(query = c('one', 'two'))
calls <- list()
original_env$generic_chemi_request <- function(...) {
  calls[[length(calls) + 1L]] <<- list(helper = 'generic_chemi_request', arguments = list(...), response = response)
  response
}
result <- do.call(original, inputs)
contracts <- readRDS('tests/testthat/fixtures/specmill-rebuild-contracts.rds')
contracts$chemi_toxprint <- list(inputs = inputs, calls = calls, result = result,
  environment = list(chemi_burl = 'http://127.0.0.1:9999/chemi', run_debug = 'FALSE'))
saveRDS(contracts[sort(names(contracts))], 'tests/testthat/fixtures/specmill-rebuild-contracts.rds', version = 3)
normalize <- function(d) { d$source <- 'schema/chemi-toxprints-prod.json'; d }
files <- c(service_file, 'schema/chemi-toxprints-prod.json', 'R/chemi_toxprint.R', 'R/z_generic_request.R')
w <- list(wave = 'toxprint', base_commit = 'cef28d1d5caeb87c521fa07713aa00dfde8df165',
  toolkit = jsonlite::read_json('dev/specmill-lock.json'), operations = 1L,
  generated_operations = 0L, retained_operations = 1L, blocked_operations = 0L,
  files = list(chemi_toxprint = 'R/chemi_toxprint.R'),
  reviewed_routes = list(chemi_toxprint = 'chemi-toxprints-prod.json POST /api/toxprints/calculate'),
  dispositions = list(chemi_toxprint = 'retained_mapped'),
  reviewed_contract_sha256 = as.list(setNames(vapply(files, digest::digest, '', file = TRUE, algo = 'sha256'), files)),
  reviewed_retained_diagnostics = lapply(reviewed$retained_diagnostics, normalize),
  native_diagnostics = lapply(native$diagnostics, normalize),
  compatibility_probe = list(formals_equal = TRUE, generated_compatible = FALSE,
    original_lazy_option_error = old_error, generated_lazy_option_error = new_error,
    original_visibility = old_visible$visible, generated_visibility = new_visible$visible,
    successful_helper_contract_variants_equal = length(variants)),
  schema_corrections = list(), behavior_corrections = list(),
  issue_337_entries_remaining = 5L, upstream_blocked_amos_entries = 5L)
jsonlite::write_json(w, 'dev/specmill-rebuild/wave-toxprint.json', pretty = TRUE, auto_unbox = TRUE)
