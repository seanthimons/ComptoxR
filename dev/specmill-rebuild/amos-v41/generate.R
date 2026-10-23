# Whole-client generation in a disk-backed copy; never write the root manifest/helper.
source('dev/install_specmill.R'); verify_specmill()
stopifnot(startsWith(normalizePath(tempdir()), '/home/sxthi/.cache/'))
directory <- 'dev/specmill-rebuild/amos-v41'
work <- '/home/sxthi/.cache/comptoxr-amos-v41/project'
if (!dir.exists(work)) {
 dir.create(work, recursive=TRUE)
 archive <- tempfile(fileext='.tar')
 stopifnot(system2('git',c('archive','--format=tar',paste0('--output=',shQuote(archive)),'HEAD'))==0L)
 utils::untar(archive,exdir=work); unlink(archive)
}
# Copy reviewed inputs and current scoped outputs before each run.
paths <- c('NAMESPACE','apis/amos-pilot.yml','apis/chemi-amos-prod-full.yml','apis/chemi-amos-direct-reads.yml',
 'schema/chemi-amos-reviewed-native.json','inst/hook_config.yml',
 'tests/testthat/test-native_amos_direct_reads.R','tests/testthat/fixtures/native-amos-direct-reads.json',directory)
for(p in paths) {
 if(dir.exists(p)) {unlink(file.path(work,p),recursive=TRUE); dir.create(dirname(file.path(work,p)),recursive=TRUE,showWarnings=FALSE); stopifnot(file.copy(p,dirname(file.path(work,p)),recursive=TRUE))}
 else stopifnot(file.copy(p,file.path(work,p),overwrite=TRUE))
}
callbacks <- new.env(parent=baseenv()); sys.source('dev/specmill_callbacks.R',callbacks)
args <- list(root=work,config=paste0(directory,'/specmill.yml'),callbacks=callbacks,
 artifacts=c('wrappers','tests'),validation=TRUE)
new_service <- yaml::read_yaml('apis/chemi-amos-direct-reads.yml')
new_paths <- vapply(new_service$operations, `[[`, '', 'file')
existing <- new_paths[file.exists(file.path(work,new_paths))]
args$adopt <- setNames(lapply(existing,function(p)specmill:::output_hash(file.path(work,p))),existing)
mode <- commandArgs(TRUE)[[1L]]
plan <- do.call(specmill::generate_client,c(args,list(mode=mode)))
print(plan)
if(mode=='plan') {print(plan$diagnostics); print(plan$mapping_diagnostics); print(plan$retained_diagnostics)}
saveRDS(plan,file.path(directory,paste0('generation-',mode,'.rds')))
stopifnot(!length(plan$diagnostics),!length(plan$mapping_diagnostics),!length(plan$retained_diagnostics),!length(plan$drift))
if(mode=='apply') {
 changed <- Filter(function(f) f$action %in% c('write','remove','protected'),plan$files)
 print(lapply(changed,function(x)x[c('file','action')]))
 stopifnot(!any(vapply(changed, function(f) f$action %in% c('remove','protected'),logical(1))))
 for(f in changed) {
  if(f$file=='.specmill/manifest.json') next
  stopifnot(grepl('^R/chemi_amos_|^tests/testthat/test-contract-chemi_amos_',f$file))
  stopifnot(file.copy(file.path(work,f$file),f$file,overwrite=TRUE))
 }
} else stopifnot(!any(vapply(plan$files,function(f)f$action %in% c('write','remove','protected'),logical(1))))
manifest <- jsonlite::read_json(file.path(work,'.specmill/manifest.json'))$files
# Check each record independently, including unchanged output from other services.
for(p in names(manifest)) stopifnot(identical(specmill:::output_hash(file.path(work,p)),manifest[[p]]$hash))
jsonlite::write_json(list(mode=mode,validation=TRUE,owners_checked=length(manifest),
 validation_results=lapply(plan$validation,function(v)v[c('source','status','source_sha256')]),
 actions=as.list(table(vapply(plan$files,`[[`,'','action')))),file.path(directory,paste0('generation-',mode,'.json')),pretty=TRUE,auto_unbox=TRUE)
old_manifest <- jsonlite::read_json('.specmill/manifest.json')$files
for(p in names(old_manifest)) {
 stopifnot(identical(manifest[[p]]$operations,old_manifest[[p]]$operations),
 identical(manifest[[p]]$hash,old_manifest[[p]]$hash))
}
cat('PASS all',length(manifest),'ownership hashes\n')
