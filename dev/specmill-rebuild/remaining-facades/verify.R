# Run with TMPDIR on persistent storage and SPECMILL_LIBRARY set to the released toolkit.
lib <- Sys.getenv('SPECMILL_LIBRARY')
stopifnot(nzchar(lib), dir.exists(lib))
loadNamespace('specmill', lib.loc = lib)
metadata <- utils::packageDescription('specmill', lib.loc = lib)
stopifnot(identical(metadata$Version, '0.1.41'),
  identical(metadata[['Config/specmill/source-commit']], '05862bee1804806cea157ff1962300d741516301'),
  identical(metadata[['Config/specmill/source-archive-sha256']], '70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
sys.source('dev/specmill-rebuild/remaining-facades/callbacks.R', callbacks)
p <- specmill::generate_client('.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'check', artifacts = c('wrappers', 'tests'), validation = TRUE)
stopifnot(!length(p$diagnostics), !length(p$mapping_diagnostics), !length(p$retained_diagnostics), !length(p$drift))
saveRDS(p, 'dev/specmill-rebuild/remaining-facades/whole-client-check.rds')
print(p)
