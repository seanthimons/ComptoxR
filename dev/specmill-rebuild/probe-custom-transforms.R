# Replay pinned-generation compatibility probes; package runtime is unchanged.
source('dev/install_specmill.R')
verify_specmill()
pkgload::load_all(quiet = TRUE)
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
contracts <- readRDS('tests/testthat/fixtures/specmill-rebuild-contracts.rds')
w <- jsonlite::read_json('dev/specmill-rebuild/wave-custom-transforms.json')
probe <- list()
for (path in c('dev/specmill-rebuild/retained-functional-use.yml', 'dev/specmill-rebuild/retained-safety-section.yml')) {
  s <- yaml::read_yaml(path)
  key <- names(s$operations)[[1L]]
  op <- s$operations[[key]]
  name <- op$name
  draft <- s
  draft$schemas$files <- as.list(draft$schemas$files)
  draft$selection$include <- list(key)
  op$implementation <- 'generated'
  draft$operations <- setNames(list(op), key)
  draft$documentation <- FALSE
  d <- 'dev/specmill-pilot/artifacts/custom-transforms-probe'
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(draft, file.path(d, 'service.yml'))
  yaml::write_yaml(
    list(config_version = 1L, package = 'ComptoxR', services = list(file.path(d, 'service.yml'))),
    file.path(d, 'project.yml')
  )
  project <- specmill::load_project('.', config = file.path(d, 'project.yml'), callbacks = callbacks)
  schema <- paste0('schema/', sub(' .*', '', w$reviewed_routes[[name]]))
  stopifnot(schema %in% unlist(draft$schemas$files))
  native <- specmill::read_operations(schema, policy = project$services[[1]]$policy)
  stopifnot(length(native$diagnostics) == 0L, length(native$operations) == 1L)
  mapped <- specmill:::configure_operation(native$operations[[1]], project$services[[1]])
  code <- specmill::render_operation(mapped$operation, mapped$spec)
  env <- new.env(parent = asNamespace('ComptoxR'))
  eval(parse(text = code), env)
  contract <- contracts[[name]]
  assign(op$helper, function(...) contract$calls[[1]]$response, env)
  value <- do.call(env[[name]], contract$inputs)
  probe[[name]] <- list(
    original_class = as.list(class(contract$result)),
    generated_class = as.list(class(value)),
    compatible = identical(value, contract$result)
  )
  stopifnot(!probe[[name]]$compatible)
  draft$operations[[key]]$implementation <- 'existing'
  yaml::write_yaml(draft, file.path(d, 'service.yml'))
  limit <- tryCatch(
    specmill::generate_client(root = '.', config = file.path(d, 'project.yml'),
      callbacks = callbacks, mode = 'plan', artifacts = c('wrappers', 'tests')),
    error = conditionMessage
  )
  stopifnot(is.character(limit), grepl('Missing client helper: req_perform_sequential', limit, fixed = TRUE))
  probe[[name]]$toolkit_retention_limit <- limit

}
w$compatibility_probe[names(probe)] <- probe
w$retained_operations <- 3L
w$blocked_operations <- 0L
w$dispositions$chemi_toxprint <- 'retained_mapped'
w$issue_337_entries_remaining <- 5L
w$schema_or_parser_blocked_entries <- 5L
w$toxprint_resolution <- 'dev/specmill-rebuild/wave-toxprint.json'
jsonlite::write_json(w, 'dev/specmill-rebuild/wave-custom-transforms.json', pretty = TRUE, auto_unbox = TRUE)

source('dev/specmill-rebuild/probe-toxprint.R')
