# Disposition ledger for the 248 checklist exports in #310-#314. Run from the package root
# after inventory.R and a screening pass of wave.R. Read-only except its two outputs.
`%||%` <- function(a, b) if (is.null(a)) b else a
out <- 'dev/specmill-rebuild'
checklist <- read.delim(file.path(out, 'issue-checklists.tsv'), header = FALSE, col.names = c('issue', 'name'))
inventory <- jsonlite::read_json(file.path(out, 'inventory.json'))$definitions
names(inventory) <- vapply(inventory, `[[`, '', 'name')
screen <- jsonlite::read_json(file.path(out, 'screen-results.json'))
audit <- jsonlite::read_json('dev/specmill-pilot/all-schema-diagnostics.json')
hooks <- yaml::read_yaml('inst/hook_config.yml')
# Evidence matching is looser than wave.R: repeated and trailing slashes left by removed
# placeholders are collapsed, so multi-parameter routes are reported (never adopted) here.
short_path <- function(key) sub('/$', '', gsub('/+', '/', sub('^/(api/)?', '', gsub('\\{[^}]+\\}', '', sub('^[A-Z]+ ', '', key)))))

# Generated operations and the wave (or original tranche) that adopted each file.
waves <- list()
for (path in Sys.glob(file.path(out, 'wave-*.json'))) {
  w <- jsonlite::read_json(path)
  for (f in unlist(w$files)) waves[[f]] <- w$wave
}
generated <- list()
retained <- list()
for (path in yaml::read_yaml('specmill.yml')$services) {
  service <- yaml::read_yaml(path)
  for (key in names(service$operations)) {
    op <- service$operations[[key]]
    if (identical(op$implementation, 'existing') && op$name %in% c('chemi_resolver_lookup_bulk', 'chemi_resolver_getsimilaritymap', 'chemi_classyfire', 'chemi_safety_rqcodes', 'chemi_toxprint')) {
      retained[[op$name]] <- list(service = service$id, key = key, file = op$file,
        wave = waves[[op$file]], policy = op$specialization, contracts_file = service$contracts_file)
    }
    if (identical(op$implementation, 'generated')) {
      generated[[op$name]] <- list(service = service$id, key = key, file = op$file, wave = waves[[op$file]] %||% 'initial tranche')
      if (op$name %in% c('chemi_stdizer_records', 'chemi_toxprints_assays_bulk')) {
        generated[[op$name]]$policy <- list(
          behavior_correction = 'Preserve caller options in helper options$options; omit only NULL. Other request behavior is unchanged.',
          request = op$request
        )
      }
      if (op$name %in% c('chemi_opera_bulk', 'chemi_predictor_models_predict_bulk')) {
        generated[[op$name]]$policy <- list(
          body_shape_policy = 'Exactly one schema oneOf required-field set must be non-NULL; preserve the original error and omit only NULL body fields.',
          request = op$request
        )
      }
      if (op$name %in% c('ct_chemical_msready_search_by_mass_bulk', 'epi_submit_batch')) {
        generated[[op$name]]$policy <- list(
          body_policy = 'Preserve the original explicit object in public field order, omitting only NULL; retain helper defaults and the 1000-fallback batch-limit callback.',
          request = op$request
        )
        if (op$name == 'epi_submit_batch') {
          generated[[op$name]]$policy$schema_discrepancy <- 'POST /api/submit/batch declares an array of BatchEstimateRequest (1-100 items); the public wrapper builds one object. Generate the existing object unchanged. Array wrapping, batching, schema validation, server and authentication corrections require separate public API review; retain current default ctx_burl and auth=TRUE.'
        }
      }
      if (op$name == 'ct_chemical_msready_search_by_mass') {
        generated[[op$name]]$policy <- list(
          path_policy = 'Schema requires end; preserve the public end=NULL default and c(end=end) path_params without adding required-end validation.',
          request = op$request
        )
      }
      if (identical(op$post_state, 'hook_state')) {
        generated[[op$name]]$policy <- list(
          request_owner = 'pre_request_hooks', hooks = service$hooks[[op$name]],
          request = op$request, post_state = op$post_state, post_on_skip = op$post_on_skip
        )
      }
    }
  }
}

# Direct httr2 helpers are imported, so the pinned toolkit cannot own their contracts.
for (entry in screen) {
  if (!is.null(entry$mapping) && identical(entry$mapping$mode, 'retained_direct')) {
    retained[[entry$name]] <- entry$mapping
  }
}

# Hook functions and the client file that defines each.
hook_files <- list()
for (f in Sys.glob('R/hooks_*.R')) {
  for (e in parse(f)) if (is.call(e) && identical(e[[1]], as.name('<-'))) hook_files[[as.character(e[[2]])]] <- f
}

# Helper route written in the original wrapper and every audit record on that route.
route <- function(name, file) {
  env <- new.env()
  sys.source(file, env, keep.source = FALSE)
  calls <- list()
  visit <- function(x) {
    if (is.call(x)) {
      head <- if (is.symbol(x[[1]])) as.character(x[[1]]) else ''
      if (grepl('^generic_', head)) calls[[length(calls) + 1L]] <<- x
      lapply(as.list(x)[-1L], visit)
    }
  }
  visit(body(env[[name]]))
  if (!length(calls)) {
    return(NULL)
  }
  call <- as.list(calls[[1]])
  helper <- as.character(call[[1]])
  endpoint <- call$endpoint
  method <- call$method %||% if (helper == 'generic_chemi_request') 'POST' else 'GET'
  if (!is.character(endpoint) || !is.character(method)) {
    return(list(helper = helper, helper_calls = length(calls), endpoint = 'computed'))
  }
  prefix <- if (startsWith(name, 'ct_')) 'ctx-' else if (startsWith(name, 'epi_')) 'epi-' else 'chemi-'
  on_route <- function(x) {
    startsWith(x$key, paste0(method, ' ')) && identical(short_path(x$key), sub('/$', '', endpoint)) &&
      startsWith(x$schema, prefix) && !grepl('_prod[.]json$', x$schema)
  }
  list(
    helper = helper, helper_calls = length(calls), method = method, endpoint = endpoint,
    supported = lapply(Filter(on_route, audit$operations), function(x) paste(x$schema, x$key)),
    blocked = lapply(Filter(on_route, audit$parser_blockers), function(x) x[c('schema', 'key', 'code', 'reason', 'pointer', 'issue')])
  )
}

hook_evidence <- function(name, d) {
  if (!is.null(hooks[[name]])) {
    chain <- hooks[[name]]
    evidence <- list(
      pre_request = as.list(chain$pre_request), post_response = as.list(chain$post_response),
      extra_params = as.list(names(chain$extra_params)),
      defined_in = lapply(c(chain$pre_request, chain$post_response), function(h) hook_files[[h]] %||% 'missing')
    )
    # Which declared stages the wrapper actually executes; undeclared calls are inert at runtime.
    env <- new.env()
    sys.source(d$file, env, keep.source = FALSE)
    text <- paste(deparse(body(env[[name]])), collapse = '\n')
    evidence$invokes_pre_request <- grepl('run_hook("', text, fixed = TRUE) && grepl('"pre_request"', text, fixed = TRUE)
    evidence$invokes_post_response <- grepl('"post_response"', text, fixed = TRUE)
    evidence$handles_skip_request <- grepl('skip_request', text, fixed = TRUE)
    return(evidence)
  }
  NULL
}

# Maintainer-approved retention closes #336/#341 without guessing upstream contracts.
retention_groups <- list(
  `26` = paste0('chemi_amos_', c(
    'all_similarities', 'analytical_qc_batch', 'batch', 'count_substances_in_ids',
    'dtxsids', 'entropy_similarity', 'mass_range', 'mass_spectra_for_substances',
    'mass_spectrum_similarity', 'max_similarity', 'next_level_classification',
    'record_counts', 'spectral_entropy', 'spectrum_count_for_methodology',
    'substances_for_classification', 'substances_for_ids'
  )),
  `27` = paste0('chemi_amos_', c(
    'for_document_ids', 'retrieve_fact_sheets', 'retrieve_product_declarations',
    'retrieve_safety_data_sheets', 'get_similar_structures', 'list_sources_by_record_type'
  )),
  `28` = 'chemi_stdizer_bulk',
  `29` = 'chemi_resolver_ghs_list_count'
)
retention_policy <- list()
for (upstream in names(retention_groups)) {
  for (name in retention_groups[[upstream]]) {
    retention_policy[[name]] <- paste0(
      'Policy retention approved in #336; preserve the hand-written contract until ',
      'https://github.com/seanthimons/specmill/issues/', upstream,
      ' is resolved and a reviewed generation wave verifies compatibility.'
    )
  }
}
for (name in c('chemi_descriptors', 'chemi_descriptors_bulk')) {
  retention_policy[[name]] <- paste0(
    'Policy retention approved in #341; preserve apply_aggregate_rdkit_fallback ',
    'and its cross-schema GET/POST /api/rdkit route until ',
    'https://github.com/seanthimons/specmill/issues/61 supports declared additional routes, ',
    'or a verified service repair removes the fallback; adoption requires a reviewed wave.'
  )
}

ledger <- lapply(seq_len(nrow(checklist)), function(i) {
  name <- checklist$name[[i]]
  d <- inventory[[name]]
  siblings <- setdiff(vapply(Filter(function(x) x$file == d$file, inventory), `[[`, '', 'name'), name)
  entry <- list(
    issue = checklist$issue[[i]], name = name, file = d$file, lifecycle = d$lifecycle, formals = d$formals,
    siblings = as.list(siblings)
  )
  if (!is.null(generated[[name]])) {
    entry$disposition <- 'generated'
    entry$mapping <- generated[[name]]
    return(entry)
  }
  if (!is.null(retained[[name]])) {
    entry$disposition <- 'retained_mapped'
    entry$reason <- screen[[name]]$reason
    entry$mapping <- retained[[name]]
    entry$route <- route(name, d$file)
    if (identical(entry$mapping$mode, 'retained_direct')) {
      key <- entry$mapping$key
      schema <- sub('^schema/', '', entry$mapping$schema)
      entry$route <- list(helper = entry$mapping$helper, method = sub(' .*', '', key), endpoint = sub('^[A-Z]+ /api/', '', key),
        supported = list(paste(schema, key)), blocked = list(),
        request_builder = 'Direct httr2 request/path/query calls traced in source; fixed contract freezes request-builder calls.')
    }
    entry$hooks <- hook_evidence(name, d)
    return(entry)
  }
  if (identical(screen[[name]]$status, 'blocked')) {
    entry$disposition <- 'blocked'
    entry$reason <- screen[[name]]$reason
    entry$route <- list(helper = 'generic_chemi_request', method = 'POST', endpoint = 'toxprints/calculate',
      schema = screen[[name]]$schema, key = screen[[name]]$key, supported = list(),
      blocked = screen[[name]]$schema_blocker)
    return(entry)
  }
  if (identical(screen[[name]]$status, 'retained_excluded')) {
    entry$disposition <- 'retained_excluded'
    entry$reason <- screen[[name]]$reason
    entry$request_scope <- screen[[name]]$request_scope
    return(entry)
  }
  if (identical(d$category, 'runtime') || name == 'ct_api_key') {
    entry$disposition <- 'retained_client_utility'
    entry$reason <- if (identical(screen[[name]]$status, 'retained_client_utility')) screen[[name]]$reason else 'Client configuration utility, not a schema endpoint wrapper; stays outside schema generation.'
    return(entry)
  }
  entry$disposition <- 'retained'
  entry$reason <- screen[[name]]$reason
  if (!is.null(retention_policy[[name]])) {
    entry$reason <- paste(entry$reason, retention_policy[[name]])
  }
  entry$route <- route(name, d$file)
  entry$hooks <- hook_evidence(name, d)
  entry
})
names(ledger) <- checklist$name
jsonlite::write_json(ledger, file.path(out, 'dispositions.json'), pretty = TRUE, auto_unbox = TRUE, null = 'null')

# Markdown summary: one table per issue.
cell <- function(x) gsub('|', '\\|', x, fixed = TRUE)
lines <- c('# Export dispositions (#310-#314)', '', 'Generated by `dev/specmill-rebuild/dispositions.R`; details in [dispositions.json](dispositions.json).', '')
for (issue in unique(checklist$issue)) {
  rows <- Filter(function(x) x$issue == issue, ledger)
  counts <- table(vapply(rows, `[[`, '', 'disposition'))
  lines <- c(lines, sprintf('## #%s (%d exports: %s)', issue, length(rows), paste(names(counts), counts, sep = ' ', collapse = ', ')), '',
    '| Export | Lifecycle | Disposition | Evidence |', '| --- | --- | --- | --- |')
  for (x in rows) {
    evidence <- if (x$disposition == 'generated') {
      sprintf('`%s` %s (%s)', x$mapping$service, x$mapping$key, x$mapping$wave)
    } else if (x$disposition == 'retained_mapped') {
      paste(x$reason, sprintf('`%s` %s (%s); fixed contract `%s`',
        x$mapping$service, x$mapping$key, x$mapping$wave, x$mapping$contracts_file), sep = '; ')
    } else {
      r <- x$route
      blocked <- vapply(r$blocked %||% list(), function(b) sprintf('%s: %s', b$code, b$reason), '')
      paste(c(
        x$reason,
        if (!is.null(r$method)) sprintf('route `%s %s` (%d supported, %d blocked)', r$method, r$endpoint, length(r$supported), length(r$blocked)),
        blocked,
        if (!is.null(x$hooks)) {
          sprintf(
            'hooks: pre `%s` (%s); post `%s` (%s)%s',
            paste(unlist(x$hooks$pre_request), collapse = ', '), if (x$hooks$invokes_pre_request) 'invoked' else 'not invoked',
            paste(unlist(x$hooks$post_response), collapse = ', '), if (x$hooks$invokes_post_response) 'invoked' else 'not invoked',
            if (x$hooks$handles_skip_request) '; honors skip_request' else ''
          )
        },
        if (length(x$siblings)) sprintf('shares file with `%s`', paste(unlist(x$siblings), collapse = '`, `'))
      ), collapse = '; ')
    }
    lines <- c(lines, sprintf('| `%s` | %s | %s | %s |', x$name, x$lifecycle %||% 'none', x$disposition, cell(evidence)))
  }
  lines <- c(lines, '')
}
writeLines(lines, file.path(out, 'DISPOSITIONS.md'))
print(table(checklist$issue, vapply(ledger, `[[`, '', 'disposition')))
