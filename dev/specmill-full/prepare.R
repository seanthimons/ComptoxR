# Prepare a conservative whole-client migration proposal in ignored artifacts.
# No runtime source, schema, helper, or active configuration is changed here.
source('dev/install_specmill.R')
verify_specmill()
source('dev/remove_experimental.R')
baseline <- 'dev/specmill-pilot/artifacts/before-source'
stopifnot(dir.exists(baseline))
out <- 'dev/specmill-pilot/artifacts/full-proposal'
dir.create(out, recursive = TRUE, showWarnings = FALSE)
audit <- jsonlite::read_json('dev/specmill-pilot/all-schema-diagnostics.json')
operations <- Filter(function(x) !grepl('_prod[.]json$', x$schema), audit$operations)
owned <- c(
  names(jsonlite::read_json('dev/specmill-pilot/adoption-hashes.json')),
  names(jsonlite::read_json('dev/specmill-pilot/adoption-hashes-lookup-expansion.json'))
)
exports <- sub(
  '^export\\(([^)]+)\\)$',
  '\\1',
  grep('^export\\(', readLines(file.path(baseline, 'NAMESPACE')), value = TRUE)
)
hooks <- names(yaml::read_yaml('inst/hook_config.yml'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
records <- list()
short_path <- function(key) sub('^/(api/)?', '', gsub('\\{[^}]+\\}', '', sub('^[A-Z]+ ', '', key)))
binding <- function(x, parameters) {
  if (is.symbol(x) && as.character(x) %in% parameters) {
    return(list(from = list('params', as.character(x))))
  }
  if (identical(x, quote(as.numeric(Sys.getenv('batch_limit', '100'))))) {
    return(list(callback = 'detail_batch_limit'))
  }
  if (is.call(x) || is.symbol(x)) {
    stop('Nonliteral helper argument needs manual mapping')
  }
  list(value = x)
}
documentation <- function(lines, start, name) {
  block <- lines[seq_len(start - 1L)]
  block <- tail(block, length(block) - max(c(0L, which(!grepl("^#'|^$", block)))))
  text <- sub("^#' ?", '', block[grepl("^#'", block)])
  tags <- regmatches(text, regexpr('^@[A-Za-z]+', text))
  if (any(!tags %in% c('@description', '@param', '@return', '@apiStage', '@export', '@examples'))) {
    stop('Rich documentation needs manual mapping')
  }
  params <- grep('^@param ', text, value = TRUE)
  descriptions <- setNames(sub('^@param [^ ]+ ', '', params), sub('^@param ([^ ]+).*', '\\1', params))
  example <- text[seq.int(which(text == '@examples') + 1L, length(text))]
  example <- example[nzchar(example) & !example %in% c('\\dontrun{', '}')]
  calls <- parse(text = example)
  examples <- lapply(calls, function(call) {
    if (!is.call(call) || !identical(call[[1L]], as.name(name))) {
      stop('Custom example needs manual mapping')
    }
    args <- as.list(call)[-1L]
    if (!length(args)) {
      return(setNames(list(), character()))
    }
    lapply(args, function(x) {
      if (is.call(x) || is.symbol(x)) {
        stop('Computed example needs manual mapping')
      }
      x
    })
  })
  stopifnot(length(examples) > 0L)
  list(
    title = text[[1L]],
    lifecycle = 'experimental',
    parameters = as.list(descriptions),
    return = sub('^@return ', '', grep('^@return ', text, value = TRUE)),
    tags = list(apiStage = 'public'),
    examples = examples
  )
}
for (file in list.files(file.path(baseline, 'R'), '[.]R$', full.names = TRUE)) {
  relative <- file.path('R', basename(file))
  exprs <- parse(file, keep.source = TRUE)
  refs <- attr(exprs, 'srcref')
  lines <- readLines(file, warn = FALSE)
  for (i in seq_along(exprs)) {
    expr <- exprs[[i]]
    if (
      !is.call(expr) ||
        !identical(expr[[1]], as.name('<-')) ||
        !is.call(expr[[3]]) ||
        !identical(expr[[3]][[1]], as.name('function'))
    ) {
      next
    }
    name <- as.character(expr[[2]])
    if (!name %in% exports) {
      next
    }
    record <- list(name = name, file = relative, status = 'retained', reason = '', schema = NULL, key = NULL)
    proposal <- tryCatch(
      {
        if (!grepl('^(ct|chemi|epi)_', name)) {
          stop('Outside CT/Chemi/EPI schema-wrapper scope')
        }
        if (relative %in% owned) {
          stop('Already in the verified pilot')
        }
        if (!identical(classify_experimental_file(file)$status, 'selected')) {
          stop('Protected or incomplete lifecycle/ownership metadata')
        }
        if (name %in% hooks) {
          stop('Client hook policy requires manual review')
        }
        fn <- eval(expr[[3]])
        code <- as.list(body(fn))[-1L]
        if (
          length(code) != 2L ||
            !is.call(code[[1]]) ||
            !identical(code[[1]][[1]], as.name('<-')) ||
            !identical(code[[1]][[2]], as.name('result')) ||
            !identical(code[[2]], quote(return(result)))
        ) {
          stop('Custom implementation requires manual mapping')
        }
        call <- code[[1]][[3]]
        helper <- as.character(call[[1]])
        if (!helper %in% c('generic_request', 'generic_chemi_request')) {
          stop('Helper outside schema migration scope')
        }
        args <- as.list(call)[-1L]
        method <- if (!is.null(args$method)) {
          args$method
        } else if (helper == 'generic_chemi_request') {
          'POST'
        } else {
          'GET'
        }
        match_route <- function(op) {
          startsWith(op$key, paste0(method, ' ')) &&
            identical(short_path(op$key), args$endpoint) &&
            if (startsWith(name, 'ct_')) {
              startsWith(op$schema, 'ctx-')
            } else if (startsWith(name, 'epi_')) {
              startsWith(op$schema, 'epi-')
            } else {
              startsWith(op$schema, 'chemi-')
            }
        }
        matches <- Filter(match_route, operations)
        if (length(matches) != 1L) {
          stop('No unique supported schema/method/path match; no route guessed')
        }
        record$schema <- matches[[1L]]$schema
        record$key <- matches[[1L]]$key
        docs <- documentation(lines, refs[[i]][[1L]], name)
        formal_list <- as.list(formals(fn))
        inputs <- lapply(names(formal_list), function(parameter) {
          default <- formal_list[parameter]
          required <- identical(default, setNames(as.list(formals(function(x) NULL)), parameter))
          if (!required && (is.call(default[[1]]) || is.symbol(default[[1]]))) {
            stop('Computed default requires manual mapping')
          }
          value <- if (required) NULL else default[[1]]
          settings <- list(
            type = if (is.numeric(value)) {
              'numeric'
            } else if (is.logical(value)) {
              'logical'
            } else {
              'character'
            }
          )
          if (required) {
            settings$required <- TRUE
          } else {
            settings['default'] <- list(value)
          }
          settings$description <- docs$parameters[[parameter]]
          settings
        })
        names(inputs) <- if (length(formal_list)) names(formal_list) else character()
        mappings <- lapply(args, binding, parameters = names(inputs))
        list(
          name = name,
          file = relative,
          helper = helper,
          implementation = 'generated',
          inputs = inputs,
          request = list(arguments = mappings),
          docs = docs
        )
      },
      error = identity
    )
    if (inherits(proposal, 'error')) {
      record$reason <- conditionMessage(proposal)
    } else {
      record$status <- 'candidate'
      record$proposal <- proposal
      record$original <- expr[[3]]
    }
    records[[name]] <- record
  }
}
# A grouped file is adopted only if every top-level definition is a candidate.
for (file in unique(vapply(records, `[[`, '', 'file'))) {
  selected <- names(Filter(function(x) x$file == file, records))
  exprs <- parse(file.path(baseline, file))
  complete <- length(exprs) == length(selected) &&
    all(vapply(records[selected], function(x) x$status == 'candidate', FALSE))
  if (!complete) {
    for (name in selected) {
      if (records[[name]]$status == 'candidate') {
        records[[name]]$status <- 'retained'
        records[[name]]$reason <- 'Inseparable grouped file contains a retained or unaccounted definition'
      }
    }
  }
}
# Render and compare interfaces before any proposal can be adopted.
services <- list()
for (name in names(records)) {
  record <- records[[name]]
  if (record$status != 'candidate') {
    next
  }
  checked <- tryCatch(
    {
      native <- specmill::read_operations(file.path('schema', record$schema), policy = list(include = record$key))
      stopifnot(length(native$operations) == 1L, length(native$diagnostics) == 0L)
      service <- list(
        helper = record$proposal$helper,
        documentation = TRUE,
        operations = setNames(list(record$proposal), record$key)
      )
      # Use load_project for the supported configuration validation boundary.
      config <- list(
        id = 'review',
        schemas = list(files = list(file.path('schema', record$schema))),
        selection = list(include = list(record$key)),
        helper = record$proposal$helper,
        documentation = TRUE,
        operations = setNames(list(record$proposal), record$key)
      )
      path <- file.path(out, 'review.yml')
      yaml::write_yaml(config, path)
      project_path <- file.path(out, 'project.yml')
      yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR', services = list(path)), project_path)
      project <- specmill::load_project('.', config = project_path, callbacks = callbacks)
      native <- specmill::read_operations(file.path('schema', record$schema), policy = project$services[[1L]]$policy)
      mapped <- specmill:::configure_operation(native$operations[[1L]], project$services[[1L]])
      code <- specmill::render_operation(mapped$operation, mapped$spec)
      environment <- new.env(parent = baseenv())
      eval(parse(text = code), environment)
      stopifnot(identical(formals(eval(record$original)), formals(environment[[name]])))
      code
    },
    error = identity
  )
  if (inherits(checked, 'error')) {
    records[[name]]$status <- 'retained'
    records[[name]]$reason <- paste('Candidate rejected:', conditionMessage(checked))
  } else {
    records[[name]]$rendered <- checked
  }
}
# Recheck whole-file ownership after candidate rendering failures.
for (file in unique(vapply(records, `[[`, '', 'file'))) {
  selected <- names(Filter(function(x) x$file == file, records))
  if (any(vapply(records[selected], function(x) x$status != 'candidate', FALSE))) {
    for (name in selected) {
      if (records[[name]]$status == 'candidate') {
        records[[name]]$status <- 'retained'
        records[[name]]$reason <- 'Grouped sibling failed candidate verification'
      }
    }
  }
}
for (name in setdiff(exports, names(records))) {
  records[[name]] <- list(
    name = name,
    file = 'NAMESPACE',
    status = 'retained',
    reason = 'Re-exported or nonstandard operator; outside schema-wrapper scope',
    schema = NULL,
    key = NULL
  )
}
saveRDS(records, file.path(out, 'records.rds'))
report <- lapply(records, function(x) x[c('name', 'file', 'status', 'reason', 'schema', 'key')])
jsonlite::write_json(report, 'dev/specmill-full/attempt-results.json', pretty = TRUE, auto_unbox = TRUE, null = 'null')
print(table(vapply(records, `[[`, '', 'status')))
print(sort(table(vapply(Filter(function(x) x$status == 'retained', records), `[[`, '', 'reason')), decreasing = TRUE))
