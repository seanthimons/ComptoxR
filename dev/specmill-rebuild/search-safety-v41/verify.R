output <- 'dev/specmill-pilot/artifacts/search-safety'
dir.create(output, recursive = TRUE, showWarnings = FALSE)
# Reproduce the held candidate differences without changing package source or ownership.
root <- 'dev/specmill-rebuild/search-safety-v41'
evidence <- readRDS(file.path(root, 'evidence.rds'))
source('dev/install_specmill.R')
lock <- tempfile('search-safety-v41-', fileext = '.json')
jsonlite::write_json(evidence$pin, lock, auto_unbox = TRUE)
verify_specmill(lock = lock)
unlink(lock)
callbacks <- new.env(parent = baseenv()); sys.source('dev/specmill_callbacks.R', callbacks)
for (record in evidence$schema_sha256) {
  stopifnot(identical(digest::digest(file = record$path, algo = 'sha256'), record$sha256))
}

# Inspect the actual released renderer, using the same public config loader and callbacks.
project <- specmill:::load_project(normalizePath('.'), 'specmill.yml', callbacks)
service <- Filter(function(x) identical(x$id, 'search-pilot'), project$services)[[1L]]
service$operations[[1L]]$implementation <- 'generated'
parsed <- specmill:::read_service_operations(service)
configured <- specmill:::configure_operation(parsed$operations[[1L]], service)
operation <- service$prepare(configured$operation)
code <- specmill:::render_operation(operation, configured$spec)
stopifnot(identical(parse(text = code)[[1L]], evidence$generated_search))
stopifnot(identical(formals(eval(evidence$legacy$chemi_search[[3L]], baseenv())),
  formals(eval(evidence$generated_search[[3L]], baseenv()))))

invoke <- function(expression, null_result = FALSE, lazy = FALSE, alter_paging = FALSE) {
  stages <- list(); request <- NULL
  state <- list(params = list(query = 'changed'), marker = 'keep',
    request = list(body = list(searchType = 'MASS'), options = list(limit = 1)),
    skip_request = !alter_paging, result = if (null_result) NULL else 'skip')
  if (alter_paging) state$params$all_pages <- FALSE
  env <- new.env(parent = baseenv())
  env$run_hook <- function(name, stage, data) {
    stages[[length(stages) + 1L]] <<- list(stage = stage, data = data)
    if (stage == 'pre_request') state else data
  }
  env$generic_chemi_request <- function(...) {
    request <<- list(...)
    'response'
  }
  fn <- eval(expression[[3L]], env)
  value <- tryCatch(if (lazy) fn(all_pages = stop('lazy sentinel')) else fn(all_pages = TRUE), error = identity)
  list(value = value, stages = stages, request = request)
}
old <- evidence$legacy$chemi_search
new <- evidence$generated_search
results <- list()
results$lazy <- list(old = invoke(old, lazy = TRUE), generated = invoke(new, lazy = TRUE))
stopifnot(!inherits(results$lazy$old$value, 'error'),
  inherits(results$lazy$generated$value, 'error'),
  length(results$lazy$old$stages) == 2L, !length(results$lazy$generated$stages))
results$hook_params <- list(old = invoke(old), generated = invoke(new))
stopifnot(!'all_pages' %in% names(results$hook_params$old$stages[[1L]]$data$params),
  'all_pages' %in% names(results$hook_params$generated$stages[[1L]]$data$params))
results$null_state <- list(old = invoke(old, null_result = TRUE), generated = invoke(new, null_result = TRUE))
stopifnot(!'result' %in% names(results$null_state$old$value),
  'result' %in% names(results$null_state$generated$value))
results$transport_params <- list(old = invoke(old, alter_paging = TRUE), generated = invoke(new, alter_paging = TRUE))
stopifnot(isTRUE(results$transport_params$old$request$paginate),
  identical(results$transport_params$generated$request$paginate, FALSE))

service <- Filter(function(x) identical(x$id, 'chemi-safety-prod-rebuild'), project$services)[[1L]]
service$operations[[1L]]$implementation <- 'generated'
# An existing client formatter name reaches the released renderer guard; it is never called.
service$operations[[1L]]$result_formatter <- 'format_legacy_pager_result'
parsed <- specmill:::read_service_operations(service)
configured <- specmill:::configure_operation(parsed$operations[[1L]], service)
formatter <- tryCatch(specmill:::render_operation(configured$operation, configured$spec), error = identity)
stopifnot(inherits(formatter, 'error'), grepl('result_formatter requires batch.fan_out, batch.split or pagination', conditionMessage(formatter), fixed = TRUE))
results$safety_formatter_rejection <- conditionMessage(formatter)
saveRDS(results, 'dev/specmill-pilot/artifacts/search-safety/reproduction-results.rds')
cat('PASS: four independently observed search differences and the unbatched formatter guard on exact released v41.\n')
