output <- 'dev/specmill-pilot/artifacts/search-safety'
dir.create(output, recursive = TRUE, showWarnings = FALSE)
source('dev/install_specmill.R')
pin <- readRDS('dev/specmill-rebuild/search-safety-v41/evidence.rds')$pin
lock <- tempfile('search-safety-v41-', fileext='.json')
jsonlite::write_json(pin, lock, auto_unbox=TRUE)
verify_specmill(lock=lock)
unlink(lock)
callbacks <- new.env(parent=baseenv()); sys.source('dev/specmill_callbacks.R', callbacks)
args <- list(root='.', config='specmill.yml', callbacks=callbacks,
 artifacts=c('wrappers','tests'), validation=TRUE)
mode <- commandArgs(TRUE)[[1L]]
p <- do.call(specmill::generate_client,c(args,list(mode=mode)))
stopifnot(!length(p$diagnostics),!length(p$mapping_diagnostics),!length(p$retained_diagnostics),!length(p$drift))
actions <- table(vapply(p$files, `[[`, '', 'action'))
changes <- Filter(function(x) x$action %in% c('write','remove','protected'),p$files)
stopifnot(!length(changes) || (mode == 'apply' && identical(vapply(changes, `[[`, '', 'file'), '.specmill/manifest.json')))
summary <- list(mode=mode, version=as.character(utils::packageVersion('specmill')),
 source=pin,
 manifest_only=all(vapply(changes,function(x) x$file == '.specmill/manifest.json',logical(1))), diagnostics=length(p$diagnostics),
 mapping_diagnostics=length(p$mapping_diagnostics),retained_diagnostics=length(p$retained_diagnostics),
 drift=length(p$drift),operations=length(p$operations),files=as.list(actions),
 validation=lapply(p$validation,function(x)list(source=basename(x$source),status=x$status,reason=x$reason)))
jsonlite::write_json(summary,paste0('dev/specmill-pilot/artifacts/search-safety/full-',mode,'.json'),auto_unbox=TRUE,pretty=TRUE)
cat('PASS whole-client validated',mode,'with',length(p$operations),'operations; no changed generated output.\n')
