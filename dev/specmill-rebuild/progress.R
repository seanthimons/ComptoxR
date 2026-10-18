# Reproduce the PR progress ledger from canonical schemas and owned outputs.
manifest <- jsonlite::read_json('.specmill/manifest.json')$files
hooks <- yaml::read_yaml('inst/hook_config.yml')
config <- yaml::read_yaml('specmill.yml')
methods <- c('get', 'post', 'put', 'patch', 'delete', 'head', 'options', 'trace')
schemas <- list.files('schema', pattern = '-prod[.]json$', full.names = TRUE)
keys <- lapply(schemas, function(path) {
  schema <- jsonlite::read_json(path)
  unlist(lapply(names(schema$paths), function(route) {
    paste(toupper(intersect(names(schema$paths[[route]]), methods)), route)
  }), use.names = FALSE)
})
names(keys) <- schemas
owned <- function(path) {
  record <- manifest[[path]]
  !is.null(record) && file.exists(path) && identical(record$hash,
    digest::digest(enc2utf8(gsub('\r\n?', '\n', paste(readLines(path, warn = FALSE), collapse = '\n'))),
      algo = 'sha256', serialize = FALSE))
}
review_file <- 'dev/specmill-rebuild/amos-reviewed-source.json'
review <- if (file.exists(review_file)) jsonlite::read_json(review_file) else NULL
completed <- stats::setNames(rep(list(character()), length(schemas)), schemas)
records <- list()
for (file in config$services) {
  service <- yaml::read_yaml(file)
  for (key in names(service$operations)) {
    operation <- service$operations[[key]]
    helper <- if (is.null(operation$helper)) service$helper else operation$helper
    if (!identical(operation$implementation, 'generated') || !identical(helper, '.ct_request')) next
    path <- if (is.null(operation$file)) paste0('R/', operation$name, '.R') else operation$file
    if (!owned(path) || !paste(service$id, key) %in% manifest[[path]]$operations) next
    suite <- hooks[[operation$name]]$bespoke_test
    fixed <- paste0('tests/testthat/test-contract-', operation$name, '.R')
    if (is.null(suite)) suite <- if (owned(fixed)) fixed else NULL
    stopifnot(!is.null(suite), file.exists(suite),
      any(grepl(operation$name, readLines(suite, warn = FALSE), fixed = TRUE)))
    for (schema in service$schemas$files) {
      binding_schema <- schema
      if (!is.null(review) && identical(schema, review$output)) {
        stopifnot(identical(digest::digest(file = schema, algo = 'sha256'), review$output_sha256),
          identical(digest::digest(file = review$canonical, algo = 'sha256'), review$canonical_sha256),
          key %in% unlist(review$derivation$operations))
        schema <- review$canonical
      }
      if (!schema %in% schemas || !key %in% keys[[schema]]) next
      completed[[schema]] <- union(completed[[schema]], key)
      records[[length(records) + 1L]] <- list(schema = schema, binding_schema = binding_schema, operation = key,
        wrapper = operation$name, file = path, suite = suite)
    }
  }
}
# A generated binding does not complete an endpoint that still has a legacy caller.
legacy <- list()
normalize_route <- function(path) sub("/$", "", sub("^/?api/", "", sub("^/", "", gsub("/[{][^}]+[}]", "", path))))
walk <- function(expression, wrapper) {
  if (!is.call(expression)) return(invisible(NULL))
  helper <- if (is.symbol(expression[[1L]])) as.character(expression[[1L]]) else ""
  if (helper %in% c("generic_request", "generic_chemi_request")) {
    args <- as.list(expression)[-1L]
    endpoint <- args$endpoint
    method <- args$method
    if (is.character(endpoint) && length(endpoint) == 1L) {
      if (is.null(method)) method <- if (helper == "generic_chemi_request") "POST" else "GET"
      if (is.character(method) && length(method) == 1L) {
        legacy[[length(legacy) + 1L]] <<- list(wrapper = wrapper, method = toupper(method), route = normalize_route(endpoint))
      }
    }
  }
  parts <- as.list(expression)[-1L]
  for (i in seq_along(parts)) if (!identical(parts[i], list(quote(expr = )))) walk(parts[[i]], wrapper)
}
for (path in list.files("R", pattern = "[.]R$", full.names = TRUE)) for (expression in parse(path)) {
  if (is.call(expression) && identical(expression[[1L]], as.name("<-")) && is.symbol(expression[[2L]]) &&
    grepl("^(chemi_|ct_|epi_|pubchem_)", as.character(expression[[2L]]))) {
    walk(expression[[3L]], as.character(expression[[2L]]))
  }
}
for (schema in schemas) for (key in completed[[schema]]) {
  method <- sub(" .*", "", key)
  route <- normalize_route(sub("^[^ ]+ ", "", key))
  if (any(vapply(legacy, function(call) identical(call$method, method) && identical(call$route, route), logical(1)))) {
    completed[[schema]] <- setdiff(completed[[schema]], key)
  }
}
records <- lapply(records, function(record) {
  record$migrated <- record$operation %in% completed[[record$schema]]
  record
})
rows <- lapply(schemas, function(schema) list(schema = sub('[.]json$', '', basename(schema)),
  migrated = length(completed[[schema]]), total = length(unique(keys[[schema]])),
  remaining = length(setdiff(keys[[schema]], completed[[schema]]))))
jsonlite::write_json(list(commit = system2('git', c('rev-parse', 'HEAD'), stdout = TRUE),
  legacy_callers = legacy, toolkit = jsonlite::read_json('dev/specmill-lock.json'), schemas = rows, endpoints = records),
  'dev/specmill-rebuild/progress.json', pretty = TRUE, auto_unbox = TRUE)
lines <- c('Endpoints migrated to Specmill — iteration checkpoint', '',
  'Counted: root-adopted native wrappers with matching Specmill ownership hashes and committed offline behavior suites. Fresh generation checks pass. Held private candidates and endpoints with literal legacy request callers are excluded; live validation remains incomplete.', '',
  'Denominator: all HTTP operations in each canonical `schema/*-prod.json`, including routes not yet exposed by this client. Archived underscore-named CTX copies and coverage metadata are excluded. There are no staging schema files in this checkout.', '',
  '```', 'Endpoints migrated (adopted / source schema total):',
  vapply(rows, function(row) paste0(row$schema, ': ', row$migrated, '/', row$total), ''), '```', '',
  paste0('Total: ', sum(vapply(rows, `[[`, 0L, 'migrated')), '/',
    sum(vapply(rows, `[[`, 0L, 'total')), '. This is endpoint ownership/test coverage, not a claim that every live server behavior has been validated.'))
writeLines(lines, 'dev/specmill-rebuild/progress.md')
cat(paste(lines, collapse = '\n'), '\n')
