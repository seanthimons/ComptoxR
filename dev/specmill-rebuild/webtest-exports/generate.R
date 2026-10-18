# Parent ownership stays untouched; the integration proof owns its own manifest.
source('dev/install_specmill.R')
verify_specmill('/home/sxthi/Documents/Projects/ComptoxR/dev/specmill-pilot/artifacts/toolkit-library/0.1.42')
root <- path.expand('~/.cache/comptoxr-specmill-finish/proof')
if (dir.exists(root)) unlink(root, recursive = TRUE)
dir.create(root, recursive = TRUE)
archive <- tempfile(fileext = '.tar')
stopifnot(system2('git', c('archive', '--format=tar',
  paste0('--output=', shQuote(archive)), '3ea6140c')) == 0L)
utils::untar(archive, exdir = root)
unlink(archive)
stopifnot(file.copy('apis/chemi-webtest-exports.yml', file.path(root, 'apis')))
cfg <- yaml::read_yaml(file.path(root, 'specmill.yml'))
cfg$services <- c(cfg$services, 'apis/chemi-webtest-exports.yml')
yaml::write_yaml(cfg, file.path(root, 'specmill.yml'))
callbacks <- new.env(parent = baseenv())
sys.source(file.path(root, 'dev/specmill_callbacks.R'), callbacks)
sys.source(file.path(root, 'dev/specmill-rebuild/remaining-facades/callbacks.R'), callbacks)
run <- function(mode) specmill::generate_client(root = root, config = 'specmill.yml',
  callbacks = callbacks, mode = mode, artifacts = c('wrappers', 'tests'), validation = TRUE)
plan <- run('apply')
print(plan)
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$retained_diagnostics), !length(plan$drift))
roxygen2::roxygenise(root, roclets = c('rd', 'namespace'))
run('apply')
fresh <- run('check')
stopifnot(all(vapply(fresh$files, `[[`, '', 'action') == 'unchanged'))
saveRDS(fresh, path.expand('~/.cache/comptoxr-specmill-finish/freshness.rds'), version = 2)
for (name in c('chemi_webtest_predict_export', 'chemi_webtest_export_append')) {
  for (path in c(paste0('R/', name, '.R'), paste0('man/', name, '.Rd'))) {
    stopifnot(file.copy(file.path(root, path), path, overwrite = TRUE))
  }
}
namespace <- readLines(file.path(root, 'NAMESPACE'))
previous <- system2('git', c('show', '3ea6140c:NAMESPACE'), stdout = TRUE)
stopifnot(setequal(setdiff(namespace, previous),
  c('export(chemi_webtest_predict_export)', 'export(chemi_webtest_export_append)')),
  !length(setdiff(previous, namespace)))
writeLines(c(previous, 'export(chemi_webtest_predict_export)', 'export(chemi_webtest_export_append)'), 'NAMESPACE')
