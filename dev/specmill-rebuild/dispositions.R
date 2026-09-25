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
for (path in yaml::read_yaml('specmill.yml')$services) {
  service <- yaml::read_yaml(path)
  for (key in names(service$operations)) {
    op <- service$operations[[key]]
    if (identical(op$implementation, 'generated')) {
      generated[[op$name]] <- list(service = service$id, key = key, file = op$file, wave = waves[[op$file]] %||% 'initial tranche')
    }
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
  if (identical(d$category, 'runtime') || name == 'ct_api_key') {
    entry$disposition <- 'retained_client_utility'
    entry$reason <- 'Client configuration utility, not a schema endpoint wrapper; stays outside schema generation.'
    return(entry)
  }
  entry$disposition <- 'retained'
  entry$reason <- screen[[name]]$reason
  entry$route <- route(name, d$file)
  if (!is.null(hooks[[name]])) {
    chain <- hooks[[name]]
    entry$hooks <- list(
      pre_request = as.list(chain$pre_request), post_response = as.list(chain$post_response),
      extra_params = as.list(names(chain$extra_params)),
      defined_in = lapply(c(chain$pre_request, chain$post_response), function(h) hook_files[[h]] %||% 'missing')
    )
    # Which declared stages the wrapper actually executes; undeclared calls are inert at runtime.
    env <- new.env()
    sys.source(d$file, env, keep.source = FALSE)
    text <- paste(deparse(body(env[[name]])), collapse = '\n')
    entry$hooks$invokes_pre_request <- grepl('run_hook("', text, fixed = TRUE) && grepl('"pre_request"', text, fixed = TRUE)
    entry$hooks$invokes_post_response <- grepl('"post_response"', text, fixed = TRUE)
    entry$hooks$handles_skip_request <- grepl('skip_request', text, fixed = TRUE)
  }
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
