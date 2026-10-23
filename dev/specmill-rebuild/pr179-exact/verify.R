folder <- 'dev/specmill-rebuild/pr179-exact'
cache <- Sys.getenv('PR179_CACHE', path.expand('~/.cache/comptoxr-pr179'))
.libPaths(c(file.path(cache,'library'),.libPaths()))
provenance <- jsonlite::read_json(file.path(folder,'provenance.json'))
stopifnot(identical(digest::digest(file=file.path(cache,'source.tar.gz'),algo='sha256'),provenance$archive_sha256))
for(path in names(provenance$production_sha256))
  stopifnot(identical(digest::digest(file=path,algo='sha256'),provenance$production_sha256[[path]]))
work <- file.path(cache,'project')
manifest <- jsonlite::read_json(file.path(work,'.specmill/manifest.json'))
for(path in names(manifest$files))
  stopifnot(identical(specmill:::output_hash(file.path(work,path)),manifest$files[[path]]$hash))
scaffold <- specmill:::request_helper_scaffold('.ct_request','https://example.invalid',NULL,
 'COMPTOXR_NATIVE_DRY_RUN',companions=c('batching','pagination'))
stopifnot(identical(readLines(file.path(work,'R/z_specmill_request.R')),strsplit(scaffold$code,'\n',fixed=TRUE)[[1]]),
 identical(paste(readLines(file.path(work,'.specmill/helpers/.ct_request.json')),collapse='\n'),scaffold$provenance))
summary <- list(source_sha=provenance$source_sha,archive_sha256=provenance$archive_sha256,
 installed_library=normalizePath(file.path(cache,'library')),installed_version=as.character(packageVersion('specmill')),
 owners=length(manifest$files),owner_hashes=manifest$files,helper_sha256=digest::digest(file=file.path(work,'R/z_specmill_request.R'),algo='sha256'),
 production_hashes_unchanged=TRUE,helper_exact_official_code=TRUE,
 schemas=lapply(readRDS(file.path(folder,'generation.rds'))$validation,function(v) list(source=basename(v$source),status=v$status)))
jsonlite::write_json(summary,file.path(folder,'verification.json'),auto_unbox=TRUE,pretty=TRUE)
cat('Verified archive, installed private library, both owner hashes, official helper/provenance and all frozen production hashes.\n')
