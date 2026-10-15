# Replay pinned-generation compatibility probes; package runtime is unchanged.
source('dev/install_specmill.R')
verify_specmill()
pkgload::load_all(quiet = TRUE)
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
w <- jsonlite::read_json('dev/specmill-rebuild/wave-prediction-classifier.json')
probe <- list()
for (path in 'dev/specmill-rebuild/retained-predict.yml') {
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
  d <- 'dev/specmill-pilot/artifacts/prediction-classifier-probe'
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
  original_inputs <- names(formals(ComptoxR::chemi_predict))
  generated_inputs <- names(formals(env[[name]]))
  probe[[name]] <- list(original_inputs = as.list(original_inputs), generated_inputs = as.list(generated_inputs), compatible = identical(original_inputs, generated_inputs))
  stopifnot(!probe[[name]]$compatible)
  draft$operations[[key]]$implementation <- 'existing'
  draft$operations[[key]]$inputs <- list(query = list(type = 'character', required = TRUE), report = list(type = 'character', default = 'JSON'))
  # Diagnostic-only NULL request placeholder reaches retained-helper validation.
  # It is never executed or adopted; the original builder owns the real request.
  draft$operations[[key]]$request <- list(arguments = list(req = list(value = NULL)))
  yaml::write_yaml(draft, file.path(d, 'service.yml'))
  limit <- tryCatch(
    specmill::generate_client(root = '.', config = file.path(d, 'project.yml'),
      callbacks = callbacks, mode = 'plan', artifacts = c('wrappers', 'tests')),
    error = conditionMessage
  )
  stopifnot(is.character(limit), grepl('Missing client helper: req_perform', limit, fixed = TRUE))
  probe[[name]]$toolkit_retention_limit <- limit

}
w$compatibility_probe <- probe
jsonlite::write_json(w, 'dev/specmill-rebuild/wave-prediction-classifier.json', pretty = TRUE, auto_unbox = TRUE)
