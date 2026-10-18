source('dev/install_specmill.R'); verify_specmill()
stopifnot(startsWith(normalizePath(tempdir()),'/home/sxthi/.cache/'))
directory <- 'dev/specmill-rebuild/amos-v41'
record <- jsonlite::read_json(file.path(directory,'provenance.json'))
for(pair in list(c(record$canonical,record$canonical_sha256),c(record$staging,record$staging_sha256),c(record$output,record$output_sha256)))
 stopifnot(identical(digest::digest(file=pair[[1L]],algo='sha256'),pair[[2L]]))
stopifnot(identical(specmill::validate_schema(record$output)$status,'passed'))
before <- digest::digest(file=record$output,algo='sha256')
source(file.path(directory,'bundle.R'),local=TRUE)
stopifnot(identical(before,digest::digest(file=record$output,algo='sha256')))
base <- readLines(file.path(directory,'base-commit.txt'))
services <- lapply(c('apis/amos-pilot.yml','apis/chemi-amos-prod-full.yml','apis/chemi-amos-reviewed-reads.yml'),yaml::read_yaml)
ns <- pkgload::load_all(quiet=TRUE)$env
checked <- character()
for(service in services) for(op in service$operations) {
 name <- op$name
 if(name %in% checked) next
 original <- system2('git',c('show',shQuote(paste0(base,':',op$file))),stdout=TRUE)
 parsed <- parse(text=original)
 assignments <- Filter(function(x)is.call(x)&&identical(x[[1L]],as.name('<-'))&&identical(x[[2L]],as.name(name)),as.list(parsed))
 stopifnot(length(assignments)==1L)
 old <- eval(assignments[[1L]][[3L]],ns)
 stopifnot(identical(formals(get(name,ns)),formals(old)))
 checked <- c(checked,name)
}
# Generate documentation in a minimal copy, then copy only new public registrations.
stage <- tempfile('amos-docs-'); dir.create(stage)
for(p in c('DESCRIPTION','NAMESPACE','LICENSE','R','man','inst','data')) if(file.exists(p))stopifnot(file.copy(p,stage,recursive=TRUE))
roxygen2::roxygenise(stage,roclets=c('rd','namespace'))
new <- names(jsonlite::read_json('tests/testthat/fixtures/native-amos-direct-reads.json'))
for(name in new)stopifnot(file.copy(file.path(stage,'man',paste0(name,'.Rd')),file.path('man',paste0(name,'.Rd')),overwrite=TRUE))
# Preserve namespace order and multiline imports; register exactly three exports.
namespace <- readLines('NAMESPACE')
for(name in new) if(!paste0('export(',name,')') %in% namespace)namespace <- c(namespace,paste0('export(',name,')'))
writeLines(namespace,'NAMESPACE')
stopifnot(length(parse(text=namespace)) > 0L)
unlink(stage,recursive=TRUE)
results <- testthat::test_local(filter='amos|native_pagers|native_classyfire|native_static_media|native_service_info',reporter='summary',stop_on_failure=TRUE)
saveRDS(results,file.path(directory,'tests.rds'))
summary <- as.data.frame(results)
jsonlite::write_json(list(existing_signatures=length(checked),passed=sum(summary$passed),failed=sum(summary$failed),
 errors=sum(summary$error),warnings=sum(summary$warning),skipped=sum(summary$skipped)),file.path(directory,'tests.json'),auto_unbox=TRUE,pretty=TRUE)
stopifnot(sum(summary$failed)==0L,!any(summary$error))
for(p in c('.specmill/manifest.json','dev/specmill-lock.json','R/z_specmill_request.R','R/z_generic_request.R','dev/specmill-rebuild/HANDOFF.md','dev/specmill-rebuild/progress.md')) {
 if(!file.exists(p))next
 old <- system2('git',c('show',shQuote(paste0(base,':',p))),stdout=TRUE)
 stopifnot(identical(readLines(p,warn=FALSE),old))
}
stopifnot(length(system2('git',c('diff',base,'--name-only','--','schema/*-prod.json'),stdout=TRUE))==0L)
