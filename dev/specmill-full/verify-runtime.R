# Reuse the pilot's real localhost server and request/object assertions.
args <- commandArgs(TRUE)
stopifnot(length(args) %in% 3:4)
results_file <- if (length(args) == 4L) args[[4]] else 'dev/specmill-full/runtime-results.json'
libs <- normalizePath(args[1:2])
out <- args[[3]]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
expressions <- parse('dev/specmill-pilot/verify-runtime.R')
for (expr in expressions) {
  if (
    is.call(expr) &&
      identical(expr[[1]], as.name('<-')) &&
      is.symbol(expr[[2]]) &&
      as.character(expr[[2]]) %in% c('lookup_cases', 'verify_client')
  ) {
    eval(expr)
  }
}
full_cases <- readRDS('dev/specmill-full/runtime-cases.rds')
# Later rebuild waves add their frozen cases alongside the original tranche.
if (file.exists('dev/specmill-rebuild/runtime-cases.rds')) {
  full_cases <- c(full_cases, readRDS('dev/specmill-rebuild/runtime-cases.rds'))
}
formals(verify_client) <- c(formals(verify_client), alist(full_cases = ))
code <- as.list(body(verify_client))
position <- which(vapply(
  code,
  function(x) is.call(x) && identical(x[[1]], as.name('<-')) && identical(x[[2]], as.name('exports')),
  FALSE
))
code <- append(code, as.list(parse('dev/specmill-full/runtime-cases.R')), after = position - 1L)
position <- which(vapply(code, function(x) is.call(x) && identical(x[[1]], as.name('saveRDS')), FALSE))
code <- append(code, list(quote(snapshot$full_failures <- full_failures)), after = position - 1L)
body(verify_client) <- as.call(code)
before <- callr::r(
  verify_client,
  list(libs[[1]], file.path(out, 'before'), lookup_cases, full_cases),
  libpath = c(libs[[1]], .libPaths())
)
after <- callr::r(
  verify_client,
  list(libs[[2]], file.path(out, 'after'), lookup_cases, full_cases),
  libpath = c(libs[[2]], .libPaths())
)
# Failure diagnostics contain output directory names; compare successful cases directly.
stopifnot(
  identical(before$interfaces, after$interfaces),
  identical(before$cases, after$cases),
  identical(names(before$full_failures), names(after$full_failures))
)
report <- list(
  scope = 'Installed original and migrated client, localhost only; synthetic responses',
  baseline_commit = '4fd720b97fb2f7f2abf131925e9270b0c11b057a',
  toolkit = jsonlite::read_json('dev/specmill-lock.json'),
  exact_requests_and_objects_equal = TRUE,
  passed_cases = length(before$cases),
  exported_signatures = length(before$interfaces),
  failures = before$full_failures,
  operations = lapply(full_cases, function(x) x[c('schema', 'key')]),
  cases = lapply(before$cases, function(x) {
    failed <- is.list(x$value) && 'error_class' %in% names(x$value)
    list(
      requests = length(x$requests),
      classes = class(x$value),
      warnings = x$warnings,
      error_classes = if (failed) x$value$error_class else NULL,
      error_message = if (failed) x$value$message else NULL
    )
  })
)
jsonlite::write_json(report, results_file, pretty = TRUE, auto_unbox = TRUE, null = 'null')
cat('Compared', length(before$cases), 'cases;', length(before$full_failures), 'candidate failures\n')
print(before$full_failures)
stopifnot(length(before$full_failures) == 0L, length(after$full_failures) == 0L)
