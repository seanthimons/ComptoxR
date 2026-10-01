# Offline inventory and native fixture audit. Run from the ComptoxR root.
source('dev/install_specmill.R')
verify_specmill()
files <- list.files('schema', pattern = '[-_]prod[.]json$', full.names = TRUE)
prior <- jsonlite::read_json('dev/specmill-pilot/schema-results.json')
escape <- function(x) gsub('/', '~1', gsub('~', '~0', x, fixed = TRUE), fixed = TRUE)
lookup <- function(document, pointer) {
  value <- document
  for (part in strsplit(sub('^#/', '', pointer), '/', fixed = TRUE)[[1L]]) {
    part <- gsub('~0', '~', gsub('~1', '/', part, fixed = TRUE), fixed = TRUE)
    value <- if (is.null(names(value))) value[[as.integer(part) + 1L]] else value[[part]]
  }
  value
}
json_type <- function(value) {
  if (is.null(value)) {
    'null'
  } else if (is.list(value)) {
    if (is.null(names(value))) 'array' else 'object'
  } else if (is.character(value)) {
    'string'
  } else if (is.logical(value)) {
    'boolean'
  } else {
    'number'
  }
}
# Follow local references without rewriting them; evidence points to the actual source value.
evidence <- function(node, pointer, document, fields = c('example', 'default', 'enum'), seen = character()) {
  if (!is.list(node)) {
    return(list())
  }
  output <- list()
  if (!is.null(node[['$ref']]) && startsWith(node[['$ref']], '#/') && !node[['$ref']] %in% seen) {
    ref <- node[['$ref']]
    output <- evidence(lookup(document, ref), ref, document, fields, c(seen, ref))
  }
  for (i in seq_along(node)) {
    key <- if (is.null(names(node))) as.character(i - 1L) else names(node)[[i]]
    at <- paste0(pointer, '/', escape(key))
    if (key %in% fields) {
      output[[length(output) + 1L]] <- list(
        pointer = at,
        field = key,
        source_value = node[[i]],
        source_json_type = json_type(node[[i]])
      )
    }
    if (key != '$ref') output <- c(output, evidence(node[[i]], at, document, fields, seen))
  }
  output
}
methods <- c('get', 'post', 'put', 'patch', 'delete', 'head', 'options', 'trace')
issues <- c(
  body_media_type = 26L,
  invalid_type = 27L,
  missing_path_parameter = 27L,
  unmatched_path_parameter = 27L,
  binary_parameter = 28L,
  nested_parameter = 31L,
  request_body_method = 29L
)
schemas <- operations <- blockers <- failures <- declarations <- list()
for (file in files) {
  schema <- basename(file)
  hash <- digest::digest(file = file, algo = 'sha256')
  stopifnot(identical(prior$schemas[[schema]]$sha256, hash))
  document <- jsonlite::read_json(file)
  declared <- list()
  for (path in names(document$paths)) {
    for (method in intersect(names(document$paths[[path]]), methods)) {
      raw <- document$paths[[path]][[method]]
      declared[[length(declared) + 1L]] <- list(
        schema = schema,
        key = paste(toupper(method), path),
        operation_id = raw$operationId,
        pointer = paste0('#/paths/', escape(path), '/', method)
      )
    }
  }
  declarations <- c(declarations, declared)
  parsed <- tryCatch(specmill::read_operations(file), error = identity)
  if (inherits(parsed, 'error')) {
    ids <- vapply(declared, function(x) if (is.null(x$operation_id)) '' else x$operation_id, '')
    duplicates <- unique(ids[nzchar(ids) & (duplicated(ids) | duplicated(ids, fromLast = TRUE))])
    schemas[[schema]] <- list(
      schema = schema,
      sha256 = hash,
      declared = length(declared),
      status = 'schema_error',
      reason = conditionMessage(parsed),
      affected_routes = declared,
      duplicate_operation_ids = as.list(duplicates),
      duplicate_routes = Filter(function(x) !is.null(x$operation_id) && x$operation_id %in% duplicates, declared)
    )
    # A whole-service naming failure must not conceal each route's source diagnostics.
    parsed <- list(operations = list(), diagnostics = list(), fixture_diagnostics = list(), server_diagnostics = list())
    for (route in declared) {
      single <- specmill::read_operations(file, policy = list(include = route$key))
      parsed$operations <- c(parsed$operations, single$operations)
      parsed$diagnostics <- c(parsed$diagnostics, single$diagnostics)
      parsed$fixture_diagnostics <- c(parsed$fixture_diagnostics, single$fixture_diagnostics)
      parsed$server_diagnostics <- c(parsed$server_diagnostics, single$server_diagnostics)
    }
    schemas[[schema]]$individually_supported <- length(parsed$operations)
    schemas[[schema]]$individually_blocked <- length(parsed$diagnostics)
  } else {
    schemas[[schema]] <- list(
      schema = schema,
      sha256 = hash,
      declared = length(declared),
      status = 'parsed',
      supported = length(parsed$operations),
      blocked = length(parsed$diagnostics)
    )
  }
  schemas[[schema]]$origin_context <- list(
    affected_operations = length(parsed$server_diagnostics),
    reasons = as.list(unique(vapply(parsed$server_diagnostics, `[[`, '', 'reason'))),
    source_host = document$host,
    source_schemes = document$schemes,
    source_servers = document$servers,
    disposition = 'Origin context only; existing client helpers retain their configured base URLs. No host guessed.'
  )
  supported <- vapply(parsed$operations, `[[`, '', 'key')
  for (diagnostic in parsed$diagnostics) {
    stopifnot(!diagnostic$key %in% supported)
    node <- lookup(document, diagnostic$source_location)
    blockers[[length(blockers) + 1L]] <- list(
      schema = schema,
      key = diagnostic$key,
      issue = unname(issues[diagnostic$code]),
      code = diagnostic$code,
      reason = diagnostic$reason,
      pointer = diagnostic$source_location,
      source_value = node,
      source_json_type = json_type(node)
    )
  }
  for (op in parsed$operations) {
    outcomes <- list()
    for (mode in c('default', 'minimal')) {
      result <- tryCatch(specmill::operation_fixtures(list(op), mode = mode)[[1L]], error = identity)
      if (!inherits(result, 'error')) {
        outcomes[[mode]] <- list(
          status = 'passed',
          supplied_inputs = as.list(names(result)),
          omitted_inputs = as.list(attr(result, 'omitted_inputs'))
        )
        next
      }
      detail <- list(
        schema = schema,
        key = op$key,
        mode = mode,
        status = 'failed',
        code = result$code,
        classification = result$classification,
        reason = conditionMessage(result),
        toolkit_pointer = result$source_location
      )
      parameter <- Filter(function(p) identical(p$source_location, result$source_location), op$parameters)
      if (length(parameter) == 1L) {
        parameter <- parameter[[1L]]
        pointer <- sub('/schema$', '', parameter$source_location)
        selected <- parameter$example$example
        candidates <- evidence(lookup(document, pointer), pointer, document)
        detail$input <- list(
          name = parameter$name,
          location = parameter$location,
          required = parameter$required,
          declared_type = parameter$schema$type
        )
        detail$evidence <- candidates
        detail$category <- if (identical(result$code, 'type_enum_contradiction')) {
          'type_enum_contradiction'
        } else if (!is.null(selected) && !specmill:::fixture_type_matches(selected, parameter$schema)) {
          'invalid_selected_example'
        } else {
          'fixture_review_required'
        }
      } else if (grepl('body', conditionMessage(result), fixed = TRUE)) {
        pointer <- paste0('#/paths/', escape(op$path), '/', tolower(op$method), '/requestBody')
        body <- op$source_operation$requestBody
        if (is.null(body)) {
          pointer <- paste0('#/paths/', escape(op$path), '/', tolower(op$method), '/parameters')
          body <- op$source_operation$parameters
        }
        detail$input <- list(
          name = 'body',
          location = 'body',
          required = isTRUE(op$body_required),
          declared_type = op$body$type
        )
        candidates <- evidence(body, pointer, document)
        selected <- op$body_example$example
        if (!is.null(selected)) {
          selected_evidence <- Filter(function(x) identical(x$source_value, selected), candidates)
          if (length(selected_evidence)) candidates <- selected_evidence
        }
        detail$evidence <- candidates
        detail$category <- if (!is.null(selected) && !specmill:::fixture_type_matches(selected, op$body)) {
          'invalid_selected_example'
        } else {
          'fixture_review_required'
        }
        if (grepl('Empty multipart forms', conditionMessage(result), fixed = TRUE)) {
          detail$category <- 'empty_multipart_minimal_fixture'
          detail$evidence <- list(list(pointer = pointer, source_value = body, source_json_type = json_type(body)))
          detail$body_property_requiredness <- list(
            required_body = isTRUE(op$body_required),
            required_properties = as.list(op$body$required),
            property_names = as.list(names(op$body$properties))
          )
        }
      } else {
        detail$category <- 'fixture_review_required'
        detail$evidence <- list()
      }
      # Each quoted source value must be recoverable from its recorded JSON pointer.
      for (item in detail$evidence) {
        stopifnot(identical(lookup(document, item$pointer), item$source_value))
      }
      outcomes[[mode]] <- detail
      failures[[length(failures) + 1L]] <- detail
    }
    operations[[length(operations) + 1L]] <- list(
      schema = schema,
      key = op$key,
      audit_level = if (schemas[[schema]]$status == 'schema_error') {
        'individual route; whole-service naming still blocked'
      } else {
        'whole-service parse'
      },
      schema_status = 'supported',
      fixture_outcomes = outcomes,
      declaration_diagnostics = Filter(function(x) identical(x$key, op$key), parsed$fixture_diagnostics)
    )
  }
}
# Previous audit inspected masked defects independently. Reuse only with matching schema bytes.
independent <- lapply(prior$independent_defects, function(row) {
  stopifnot(identical(schemas[[row$schema]]$sha256, prior$schemas[[row$schema]]$sha256))
  document <- jsonlite::read_json(file.path('schema', row$schema))
  method <- tolower(sub(' .*', '', row$key))
  path <- sub('^[A-Z]+ ', '', row$key)
  parameters <- document$paths[[path]][[method]]$parameters
  index <- which(vapply(parameters, function(x) identical(x$name, row$parameter), FALSE))
  stopifnot(length(index) == 1L)
  pointer <- paste0('#/paths/', escape(path), '/', method, '/parameters/', index - 1L)
  parameter <- parameters[[index]]
  row$input <- list(name = parameter$name, location = parameter[['in']], required = isTRUE(parameter$required))
  row$evidence <- if (row$code == 'invalid_type') {
    Filter(function(x) identical(x$source_value, 'file'), evidence(parameter, pointer, document, fields = 'type'))
  } else {
    list(list(pointer = pointer, source_value = parameter, source_json_type = 'object'))
  }
  for (item in row$evidence) {
    stopifnot(identical(lookup(document, item$pointer), item$source_value))
  }
  row
})
failed_keys <- unique(vapply(failures, function(x) paste(x$schema, x$key), ''))
summary <- list(
  schemas = length(schemas),
  declared_operations = length(declarations),
  parsed_supported_operations = length(operations),
  parser_blockers = length(blockers),
  schema_errors = sum(vapply(schemas, function(x) x$status == 'schema_error', FALSE)),
  fixture_failed_operation_keys = length(failed_keys),
  fixture_modes = list()
)
source_group <- function(schema) if (grepl('_prod[.]json$', schema)) 'legacy_snapshot' else 'canonical_production'
summary$source_groups <- lapply(c('canonical_production', 'legacy_snapshot'), function(group) {
  group_ops <- Filter(function(x) source_group(x$schema) == group, operations)
  group_failures <- Filter(function(x) source_group(x$schema) == group, failures)
  list(
    group = group,
    schemas = sum(vapply(names(schemas), function(x) source_group(x) == group, FALSE)),
    declared = sum(vapply(declarations, function(x) source_group(x$schema) == group, FALSE)),
    individually_supported = length(group_ops),
    parser_blockers = sum(vapply(blockers, function(x) source_group(x$schema) == group, FALSE)),
    default_fixture_failures = sum(vapply(group_failures, function(x) x$mode == 'default', FALSE)),
    minimal_fixture_failures = sum(vapply(group_failures, function(x) x$mode == 'minimal', FALSE))
  )
})
for (mode in c('default', 'minimal')) {
  statuses <- vapply(operations, function(x) x$fixture_outcomes[[mode]]$status, '')
  summary$fixture_modes[[mode]] <- list(passed = sum(statuses == 'passed'), failed = sum(statuses == 'failed'))
}
report <- list(
  toolkit = jsonlite::read_json('dev/specmill-lock.json'),
  summary = summary,
  scope = 'All current production schema filenames, including underscore snapshots. Native fixtures only; no public mappings, explicit overrides, request construction or live calls.',
  schemas = schemas,
  operations = operations,
  parser_blockers = blockers,
  independently_verified_defects = independent,
  fixture_failures = failures
)
report$legacy_snapshot_comparisons <- lapply(
  Filter(function(x) source_group(x) == 'legacy_snapshot', names(schemas)),
  function(name) {
    canonical <- gsub('_', '-', name, fixed = TRUE)
    list(
      legacy = name,
      canonical = canonical,
      byte_identical = identical(schemas[[name]]$sha256, schemas[[canonical]]$sha256)
    )
  }
)
jsonlite::write_json(
  report,
  'dev/specmill-pilot/all-schema-diagnostics.json',
  auto_unbox = TRUE,
  pretty = TRUE,
  null = 'null',
  digits = NA
)

# Keep the human report reproducible from the same evidence as the JSON inventory.
cell <- function(x) gsub('|', '\\|', gsub('[\r\n]', ' ', x), fixed = TRUE)
inline <- function(x) paste0('`', cell(x), '`')
canonical_summary <- summary$source_groups[[1L]]
lines <- c(
  '# Migration blockers and source corrections',
  '',
  sprintf(
    'The %s canonical production files declare %s operations: %s parse individually and %s remain contract-blocked or unsupported. %s whole-service parse is also blocked by a duplicated operation ID. Of the individually parsed canonical routes, %s have invalid default examples; minimal mode fails for %s, including two empty-multipart fixture limitations. The four legacy snapshots are counted separately below.',
    canonical_summary$schemas,
    canonical_summary$declared,
    canonical_summary$individually_supported,
    canonical_summary$parser_blockers,
    summary$schema_errors,
    canonical_summary$default_fixture_failures,
    canonical_summary$minimal_fixture_failures
  ),
  '',
  'The legacy generator selects the 27 canonical hyphenated production files. Four underscore-named CTX files are legacy snapshots and are audited separately, not additional production services. These results describe source bytes and offline native fixtures, not production behavior or compatibility of existing ComptoxR wrappers. Only declared source types and values determine invalid-example findings; domain plausibility and generated client documentation examples are not evaluated.',
  '',
  '| Source group | Files | Declared routes | Individually parsed | Parser blockers | Default failures | Minimal failures |',
  '| --- | ---: | ---: | ---: | ---: | ---: | ---: |',
  vapply(
    summary$source_groups,
    function(x) {
      sprintf(
        '| %s | %s | %s | %s | %s | %s | %s |',
        x$group,
        x$schemas,
        x$declared,
        x$individually_supported,
        x$parser_blockers,
        x$default_fixture_failures,
        x$minimal_fixture_failures
      )
    },
    ''
  ),
  '',
  '## What to fix next',
  '',
  '- Service contracts block #26, #27, #28 and #31. Confirm media, corrected parameter names/types, file representation and nested-query serialization for each affected route before generation. Do not infer wire formats from schema names or development observations. #29 GET-body handling remains unsupported; OAuth #4 is outside this work.',
  '- Invalid examples need source-example corrections, not endpoint or serialization changes. Most failures provide JSON-looking text where the declared body is an array; publish an actual JSON array example. The image GSID path example is numeric while its parameter type is string; confirm the contract and publish a matching example. Both default and minimal failures remain visible. No substitute fixtures were selected.',
  '- CHET repeats an operationId across two OPTIONS routes. Upstream should assign unique operation IDs. A reviewed client naming override could resolve naming locally, but this audit did not invent one. Each declared route was parsed independently with an exact include key to reveal its fixture diagnostics; whole-service parsing remains blocked.',
  '- A mixed generation selection containing a parser-blocked route fails atomically. Record diagnostics first and explicitly scope generation to independently supported routes. This audit makes no fallback requests.',
  '- Two CHET uploads pass default fixtures but fail minimal fixtures because all fields are optional while the multipart body is required. Omitting all fields creates an unencodable empty form. This is a minimal-fixture limitation, not an invalid selected example or parser rejection. Ask the service owner whether a field is required; keep tested explicit inputs separately if using these routes.',
  '',
  '## Fixture modes',
  '',
  '| Mode | Pass | Fail |',
  '| --- | ---: | ---: |',
  sprintf(
    '| %s | %s | %s |',
    c('default', 'minimal'),
    vapply(summary$fixture_modes, `[[`, 0L, 'passed'),
    vapply(summary$fixture_modes, `[[`, 0L, 'failed')
  ),
  '',
  'Minimal mode omits optional inputs and reduces coverage. It cannot repair an invalid required example. Explicit overrides were not used. No type/enum contradiction was observed in this corpus; the JSON inventory keeps parser fixture diagnostics separately if future schemas introduce them.',
  '',
  '## Contract blockers by stable route',
  '',
  '| Schema | Method and path | Issue | Diagnostic / upstream action | Source pointer |',
  '| --- | --- | --- | --- | --- |'
)
remedy <- c(
  body_media_type = 'Declare service-owned consumes/media and body representation.',
  invalid_type = 'Correct invalid declared types; nested files need a supported upload contract.',
  missing_path_parameter = 'Declare the actual path placeholder and its type/allowed values.',
  unmatched_path_parameter = 'Make parameter names match actual path placeholders.',
  binary_parameter = 'Specify file location, representation, media and relation to metadata.',
  nested_parameter = 'Specify nested-query field names and exact serialization, including arrays.',
  request_body_method = 'GET-body route remains unsupported (#29); upstream must clarify its supported contract.'
)
for (row in blockers) {
  lines <- c(
    lines,
    sprintf(
      '| %s | %s | #%s | %s %s | %s |',
      inline(row$schema),
      inline(row$key),
      row$issue,
      cell(row$reason),
      remedy[[row$code]],
      inline(row$pointer)
    )
  )
}
lines <- c(
  lines,
  '',
  '## Independent defects masked by the first parser error',
  '',
  'Correcting a primary blocker alone does not resolve these additional defects. Source bytes were hash-matched to the independent inspection in `schema-results.json`.',
  '',
  '| Schema | Method and path | Issue | Input | Additional defect | Source pointer |',
  '| --- | --- | --- | --- | --- | --- |'
)
for (row in independent) {
  lines <- c(
    lines,
    sprintf(
      '| %s | %s | #%s | %s | %s | %s |',
      inline(row$schema),
      inline(row$key),
      row$issue,
      inline(row$parameter),
      cell(row$reason),
      paste(vapply(row$evidence, function(x) inline(x$pointer), ''), collapse = '; ')
    )
  )
}
lines <- c(
  lines,
  '',
  '## Invalid fixture examples by stable route',
  '',
  'Each row below fails in both default and minimal mode. Canonical production and legacy snapshot rows are labeled separately; legacy repetitions are not new production defects. The machine-readable report contains individual mode results, JSON values, JSON types, declared types and exact pointers. Required inputs remain required.',
  '',
  '| Schema | Method and path | Input | Source value and type | Declared type | Source pointer |',
  '| --- | --- | --- | --- | --- | --- |'
)
default_failures <- Filter(function(x) x$mode == 'default', failures)
default_failures <- default_failures[order(vapply(default_failures, function(x) source_group(x$schema), ''))]
for (row in default_failures) {
  for (item in row$evidence) {
    lines <- c(
      lines,
      sprintf(
        '| %s | %s | %s | %s (%s) | %s | %s |',
        paste(inline(row$schema), source_group(row$schema)),
        inline(row$key),
        paste(row$input$name, if (row$input$required) 'required' else 'optional'),
        inline(as.character(jsonlite::toJSON(item$source_value, auto_unbox = TRUE))),
        item$source_json_type,
        inline(paste(row$input$declared_type, collapse = ', ')),
        inline(item$pointer)
      )
    )
  }
}
lines <- c(
  lines,
  '',
  '## Minimal multipart fixture limitation',
  '',
  'These routes pass native default fixtures. Minimal mode omits every optional property, leaving a required multipart body empty. Confirm whether the service requires a particular field and correct source requiredness only if confirmed. Do not invent fields to make minimal mode pass.',
  '',
  '| Schema | Method and path | Mode | Diagnostic | Source pointer |',
  '| --- | --- | --- | --- | --- |'
)
for (row in Filter(function(x) x$category == 'empty_multipart_minimal_fixture', failures)) {
  lines <- c(
    lines,
    sprintf(
      '| %s | %s | %s | %s | %s |',
      inline(row$schema),
      inline(row$key),
      row$mode,
      cell(row$reason),
      inline(row$evidence[[1L]]$pointer)
    )
  )
}
for (schema in Filter(function(x) x$status == 'schema_error', schemas)) {
  lines <- c(
    lines,
    '',
    paste('## Unparsed schema:', schema$schema),
    '',
    schema$reason,
    '',
    'Duplicate IDs block whole-service parsing. All routes below were also parsed and fixture-tested independently using their exact method/path include key, without naming overrides. Individual success does not remove the whole-service naming conflict.',
    '',
    '| Colliding method and path | operationId | Source pointer |',
    '| --- | --- | --- |'
  )
  for (row in schema$duplicate_routes) {
    lines <- c(
      lines,
      sprintf(
        '| %s | %s | %s |',
        inline(row$key),
        inline(row$operation_id),
        inline(paste0(row$pointer, '/operationId'))
      )
    )
  }
  lines <- c(lines, '', 'All affected routes:', '', '| Method and path |', '| --- |')
  for (row in schema$affected_routes) {
    lines <- c(lines, paste0('| ', inline(row$key), ' |'))
  }
}
lines <- c(
  lines,
  '',
  '## Origin metadata, separate from request-contract blockers',
  '',
  'Relative servers and absent Swagger host/scheme need an origin context. Existing ComptoxR helpers retain their configured service base URLs. These warnings do not make a route parser-unsupported, and this audit supplies no guessed hosts. Counts below cover parsed operations only.',
  '',
  '| Source file | Affected parsed operations | Origin diagnostic |',
  '| --- | ---: | --- |'
)
for (schema in schemas) {
  if (schema$origin_context$affected_operations > 0L) {
    lines <- c(
      lines,
      sprintf(
        '| %s | %s | %s |',
        inline(schema$schema),
        schema$origin_context$affected_operations,
        paste(unlist(schema$origin_context$reasons), collapse = '; ')
      )
    )
  }
}
lines <- c(
  lines,
  '',
  '## Legacy snapshots are separate evidence',
  '',
  'Do not file their repeated failures as extra canonical-production defects. Byte comparison also prevents treating a differently named historical snapshot as the same source.',
  '',
  '| Legacy snapshot | Canonical production file | Byte-identical |',
  '| --- | --- | --- |'
)
for (row in report$legacy_snapshot_comparisons) {
  lines <- c(lines, sprintf('| %s | %s | %s |', inline(row$legacy), inline(row$canonical), row$byte_identical))
}
lines <- c(
  lines,
  '',
  '## Reproduce',
  '',
  'Run `Rscript dev/specmill-pilot/audit-all-schemas.R` after installing the isolated toolkit with `Rscript dev/install_specmill.R`.',
  '',
  paste0(
    'Toolkit commit: `',
    report$toolkit$source_commit,
    '`. Source hashes, stable keys and complete per-mode outcomes are in `all-schema-diagnostics.json`. No schemas, client policies or production endpoints are changed.'
  )
)
writeLines(lines, 'dev/specmill-pilot/UPSTREAM-ISSUES.md')
print(summary)
