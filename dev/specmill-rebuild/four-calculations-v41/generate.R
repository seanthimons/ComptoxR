# Run from the package root with a persistent TMPDIR set before starting R.
library_path <- Sys.getenv('SPECMILL_LIB', '/tmp/chet-specmill41-library')
.libPaths(c(library_path, .libPaths()))
source('dev/install_specmill.R')
verify_specmill(library_path, 'dev/specmill-rebuild/four-calculations-v41/release-provenance.json')
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
mode <- if ('--apply' %in% commandArgs(TRUE)) 'apply' else 'check'
client_warnings <- character()
result <- withCallingHandlers(specmill::generate_client('.', config='specmill.yml', callbacks=callbacks,
  mode=mode, artifacts=c('wrappers','tests'), validation=TRUE),
  warning=function(w) client_warnings <<- c(client_warnings,conditionMessage(w)))
result$client_warnings <- client_warnings
saveRDS(result, paste0('dev/specmill-rebuild/four-calculations-v41/generation-',mode,'.rds'), version=2)
print(table(vapply(result$files, `[[`, "", "action")))
print(vapply(result$validation, `[[`, "", "status"))
if (length(result$retained_diagnostics)) {
  review <- jsonlite::read_json('dev/specmill-rebuild/wave-toxprint.json')
  hashes <- review$reviewed_contract_sha256
  actual <- setNames(lapply(names(hashes), function(path) digest::digest(file=path,algo='sha256')),names(hashes))
  normalized <- lapply(result$retained_diagnostics,function(d) {
    d$source <- sub(paste0(normalizePath('.'),'/'),'',d$source,fixed=TRUE)
    d
  })
  stopifnot(identical(actual,hashes),identical(normalized,review$reviewed_retained_diagnostics))
}
stopifnot(!length(result$diagnostics), !length(result$mapping_diagnostics), !length(result$drift))
if (mode == 'check') stopifnot(!any(vapply(result$files, `[[`, '', 'action') %in% c('write','remove','protected')))
