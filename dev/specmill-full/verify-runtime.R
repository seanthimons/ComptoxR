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
baseline_snapshot <- Sys.getenv('COMPTOXR_BASELINE_SNAPSHOT')
before <- if (nzchar(baseline_snapshot)) {
  readRDS(baseline_snapshot)
} else {
  callr::r(
    verify_client,
    list(libs[[1]], file.path(out, 'before'), lookup_cases, full_cases),
    libpath = c(libs[[1]], .libPaths())
  )
}
candidate_snapshot <- Sys.getenv('COMPTOXR_CANDIDATE_SNAPSHOT')
after <- if (nzchar(candidate_snapshot)) {
  readRDS(candidate_snapshot)
} else {
  callr::r(
    verify_client,
    list(libs[[2]], file.path(out, 'after'), lookup_cases, full_cases),
    libpath = c(libs[[2]], .libPaths())
  )
}
# #337: these exports deliberately reject queries the original sent or failed in httr2.
corrected_exports <- c('chemi_resolver_lookup', 'chemi_resolver_lookupCASRN')
corrected_cases <- grep(
  paste0('^corrected-(', paste(corrected_exports, collapse = '|'), ')-'),
  names(after$cases),
  value = TRUE
)
stopifnot(length(corrected_cases) == 6L * length(corrected_exports))
for (name in corrected_cases) {
  case <- after$cases[[name]]
  stopifnot(
    length(case$requests) == 0L,
    'error_class' %in% names(case$value),
    grepl('query', case$value$message, fixed = TRUE)
  )
}
# #337: only payload$options$options changes; all other wire fields and results stay equal.
options_exports <- c('chemi_stdizer_records', 'chemi_toxprints_assays_bulk')
options_cases <- grep(
  paste0('^corrected-options-(', paste(options_exports, collapse = '|'), ')-'),
  names(after$cases),
  value = TRUE
)
stopifnot(length(options_cases) == 7L * length(options_exports))
for (name in options_cases) {
  old <- before$cases[[name]]
  new <- after$cases[[name]]
  stopifnot(length(old$requests) == 1L, length(new$requests) == 1L)
  payload <- jsonlite::fromJSON(rawToChar(new$requests[[1L]]$body), simplifyVector = FALSE)
  variant <- sub('^.*-', '', name)
  wanted <- switch(
    variant,
    nested = ,
    `400` = list(flag = FALSE, count = 0L, nested = list(label = 'caf\u00e9 +/&')),
    empty = list(),
    false = FALSE,
    zero = 0L,
    NULL
  )
  stopifnot(
    identical(payload$options$options, wanted),
    identical('options' %in% names(payload$options), !variant %in% c('omitted', 'null'))
  )
  strip_options <- function(case) {
    body <- jsonlite::fromJSON(rawToChar(case$requests[[1L]]$body), simplifyVector = FALSE)
    body$options$options <- NULL
    case$requests[[1L]]$body <- body
    case
  }
  stopifnot(identical(strip_options(old), strip_options(new)))
}
unchanged_cases <- setdiff(names(before$cases), c(corrected_cases, options_cases))
# #331: ChET's old zero-based Spring strategy never returned records.
chet_exports <- c('chemi_chet_chemicals_counts', 'chemi_chet_chemicals_database', 'chemi_chet_reaction_database')
chet_cases <- grep(paste0('^(', paste(chet_exports, collapse = '|'), ')-'), names(after$cases), value = TRUE)
stopifnot(length(chet_cases) == 3L * length(chet_exports))
before_interfaces <- before$interfaces
for (name in chet_exports) {
  stopifnot(identical(before$interfaces[[name]]$page, 0), identical(after$interfaces[[name]]$page, 1))
  before_interfaces[[name]]$page <- 1
}
for (name in chet_cases) {
  old <- before$cases[[name]]
  new <- after$cases[[name]]
  if (endsWith(name, '-pagination')) {
    stopifnot(
      length(new$requests) == 2L,
      identical(new$value, rep(list(list(id = 'pilot-response')), 2L)),
      length(new$warnings) == 1L,
      grepl('max_pages', new$warnings[[1L]], fixed = TRUE)
    )
    for (i in 1:2) {
      request <- old$requests[[i]]
      request$query <- sub(paste0('page=', i - 1L), paste0('page=', i), request$query, fixed = TRUE)
      stopifnot(identical(request, new$requests[[i]]))
    }
    next
  }
  stopifnot(
    length(new$requests) == 1L,
    identical(old$value, new$value),
    length(new$warnings) == 1L,
    grepl('No results found', new$warnings[[1L]], fixed = TRUE)
  )
  first <- old$requests[[1L]]
  if (endsWith(name, '-minimal')) {
    first$query <- sub('page=0', 'page=1', first$query, fixed = TRUE)
  }
  stopifnot(identical(first, new$requests[[1L]]))
}
unchanged_cases <- setdiff(unchanged_cases, chet_cases)
# Failure diagnostics contain output directory names; compare successful cases directly.
stopifnot(
  identical(before_interfaces, after$interfaces),
  identical(before$helper_interfaces, after$helper_interfaces),
  identical(before$cases[unchanged_cases], after$cases[unchanged_cases]),
  identical(names(before$full_failures), names(after$full_failures))
)
report <- list(
  scope = 'Installed original and migrated client, localhost only; synthetic responses',
  baseline_commit = '4fd720b97fb2f7f2abf131925e9270b0c11b057a',
  toolkit = jsonlite::read_json('dev/specmill-lock.json'),
  exact_requests_and_objects_equal = identical(before$cases, after$cases),
  passed_cases = length(before$cases),
  corrected_exports = as.list(corrected_exports),
  corrected_query_cases = as.list(corrected_cases),
  corrected_options_exports = as.list(options_exports),
  corrected_options_cases = as.list(options_cases),
  corrected_chet_exports = as.list(chet_exports),
  corrected_chet_cases = as.list(chet_cases),
  baseline_snapshot_sha256 = if (nzchar(baseline_snapshot)) {
    digest::digest(file = baseline_snapshot, algo = 'sha256')
  } else {
    NULL
  },
  unchanged_request_fields_and_objects_equal = TRUE,
  exported_signatures = length(before$interfaces),
  helper_signatures_equal = TRUE,
  helper_signatures = as.list(names(before$helper_interfaces)),
  failures = before$full_failures,
  operations = lapply(full_cases, function(x) x[c('schema', 'key')]),
  cases = lapply(after$cases, function(x) {
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
