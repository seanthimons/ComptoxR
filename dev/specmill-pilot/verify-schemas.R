# Offline native-schema audit. These fixtures are not mapped ComptoxR arguments.
source('dev/install_specmill.R')
verify_specmill()
files <- list.files('schema', pattern = '[-_]prod[.]json$', full.names = TRUE)
parsed <- schemas <- blockers <- latent <- list()
issue_for <- c(
  body_media_type = 26L,
  invalid_type = 27L,
  missing_path_parameter = 27L,
  unmatched_path_parameter = 27L,
  binary_parameter = 28L,
  nested_parameter = 31L,
  request_body_method = 29L
)
for (file in files) {
  schema <- basename(file)
  result <- tryCatch(specmill::read_operations(file), error = identity)
  row <- list(schema = schema, sha256 = digest::digest(file = file, algo = 'sha256'))
  if (inherits(result, 'error')) {
    schemas[[schema]] <- c(row, list(status = 'schema_error', reason = conditionMessage(result)))
    next
  }
  parsed[[schema]] <- result
  keys <- vapply(result$operations, `[[`, '', 'key')
  schemas[[schema]] <- c(
    row,
    list(
      status = 'parsed',
      supported_keys = unname(keys),
      supported = length(keys),
      blocked = length(result$diagnostics)
    )
  )
  for (diagnostic in result$diagnostics) {
    stopifnot(!diagnostic$key %in% keys, diagnostic$code %in% names(issue_for))
    blockers[[length(blockers) + 1L]] <- list(
      schema = schema,
      key = diagnostic$key,
      issue = unname(issue_for[[diagnostic$code]]),
      code = diagnostic$code,
      reason = diagnostic$reason,
      source_location = diagnostic$source_location,
      disposition = if (diagnostic$code == 'request_body_method') {
        'unsupported (#29)'
      } else {
        'blocked pending upstream contract'
      }
    )
  }
  # Inspect each query/body independently, so the first diagnostic cannot mask overlaps.
  document <- jsonlite::read_json(file)
  for (diagnostic in result$diagnostics) {
    method <- tolower(sub(' .*', '', diagnostic$key))
    path <- sub('^[A-Z]+ ', '', diagnostic$key)
    operation <- document$paths[[path]][[method]]
    for (parameter in operation$parameters) {
      problem <- NULL
      if (identical(parameter[['in']], 'query') && !is.null(parameter$schema)) {
        shape <- specmill:::input_schema(parameter$schema, document)
        problem <- tryCatch(
          specmill:::parameter_shape(parameter, shape, document$openapi, diagnostic$source_location),
          error = identity
        )
      }
      if (schema == 'chemi-amos-prod.json' && identical(parameter[['in']], 'body')) {
        problem <- tryCatch(specmill:::input_schema(parameter$schema, document), error = identity)
      }
      if (inherits(problem, 'error') && isTRUE(problem$code %in% c('nested_parameter', 'invalid_type'))) {
        latent[[length(latent) + 1L]] <- list(
          schema = schema,
          key = diagnostic$key,
          parameter = parameter$name,
          issue = unname(issue_for[[problem$code]]),
          code = problem$code,
          reason = conditionMessage(problem),
          primary_code = diagnostic$code,
          rejected = !diagnostic$key %in% keys
        )
      }
    }
  }
}
pilot <- list(
  'epi-suite-prod.json' = 'GET /api/search',
  'chemi-alerts-prod.json' = 'GET /api/alerts/groups/{id}',
  'ctx-chemical-prod.json' = c(
    'GET /chemical/detail/search/by-dtxsid/{dtxsid}',
    'POST /chemical/detail/search/by-dtxsid/',
    'GET /chemical/list/all'
  ),
  'chemi-search-prod.json' = 'POST /api/search'
)
fixtures <- list()
for (schema in names(pilot)) {
  for (key in pilot[[schema]]) {
    operations <- Filter(function(x) identical(x$key, key), parsed[[schema]]$operations)
    stopifnot(length(operations) == 1L)
    operation <- operations[[1L]]
    for (mode in c('default', 'minimal', 'explicit_override')) {
      row <- list(
        schema = schema,
        key = key,
        mode = mode,
        scope = 'native schema fixtures only; not mapped public API or received wire'
      )
      overrides <- list()
      if (mode == 'explicit_override') {
        if (key != 'POST /chemical/detail/search/by-dtxsid/') {
          fixtures[[length(fixtures) + 1L]] <- c(row, list(status = 'not_requested'))
          next
        }
        overrides <- setNames(list(list(body = list('DTXSID7020182', 'DTXSID7020005'))), operation$name)
        row$explicit_inputs <- overrides[[1L]]
        row$rationale <- 'Explicit array replaces incompatible scalar example only for this separately recorded mode.'
      }
      value <- tryCatch(
        specmill::operation_fixtures(
          list(operation),
          overrides,
          mode = if (mode == 'minimal') 'minimal' else 'default'
        )[[1L]],
        error = identity
      )
      fixtures[[length(fixtures) + 1L]] <- if (inherits(value, 'error')) {
        c(row, list(status = 'failed', reason = conditionMessage(value)))
      } else {
        c(row, list(status = 'passed', inputs = value, omitted_inputs = as.list(attr(value, 'omitted_inputs'))))
      }
    }
  }
}
counts <- table(vapply(blockers, function(x) as.character(x$issue), ''))
stopifnot(
  length(blockers) == 53L,
  identical(as.integer(counts[c('26', '27', '28', '29', '31')]), c(26L, 6L, 18L, 1L, 2L)),
  sum(vapply(latent, function(x) x$code == 'invalid_type', FALSE)) == 5L,
  sum(vapply(latent, function(x) x$code == 'nested_parameter', FALSE)) == 13L
)
failed <- Filter(function(x) identical(x$status, 'failed'), fixtures)
stopifnot(
  length(failed) == 2L,
  all(vapply(
    failed,
    function(x) {
      x$key == 'POST /chemical/detail/search/by-dtxsid/' && x$mode %in% c('default', 'minimal')
    },
    FALSE
  ))
)
report <- list(
  toolkit = jsonlite::read_json('dev/specmill-lock.json'),
  scope = 'Offline current production schema files. No schema repairs, policy overrides, live calls, or request construction.',
  schemas = schemas,
  primary_blockers = blockers,
  independent_defects = latent,
  native_pilot_fixtures = fixtures
)
jsonlite::write_json(
  report,
  'dev/specmill-pilot/schema-results.json',
  pretty = TRUE,
  auto_unbox = TRUE,
  null = 'null',
  digits = NA
)
cat(
  length(files),
  'schemas;',
  length(blockers),
  'primary blockers; five masked AMOS file defects;',
  '13 nested query defects; six pilot keys; two native fixture failures retained.\n'
)
