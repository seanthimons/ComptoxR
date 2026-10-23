lib <- Sys.getenv('SPECMILL_LIBRARY')
stopifnot(nzchar(lib), dir.exists(lib))
loadNamespace('specmill', lib.loc = lib)
metadata <- utils::packageDescription('specmill', lib.loc = lib)
stopifnot(identical(metadata[['Config/specmill/source-commit']], '05862bee1804806cea157ff1962300d741516301'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
sys.source('dev/specmill-rebuild/remaining-facades/callbacks.R', callbacks)
for (name in c('pubchem', 'recursive')) {
  config <- paste0('dev/specmill-rebuild/remaining-facades/held-', name, '-config.yml')
  result <- tryCatch(specmill::generate_client('.', config = config, callbacks = callbacks,
    mode = 'plan', artifacts = 'wrappers', validation = TRUE), error = identity)
  stopifnot(inherits(result, 'error'))
  expected <- if (name == 'pubchem') 'pagination.parameter must name an integer or number path or query parameter' else
    'batch.fan_out must name a scalar path or query parameter'
  stopifnot(startsWith(conditionMessage(result), expected))
  message(name, ': ', conditionMessage(result))
}
