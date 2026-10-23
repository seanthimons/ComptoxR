# Reproduce a closed Swagger2 subset, preserving canonical snapshots verbatim.
canonical <- 'schema/chemi-amos-prod.json'
staging <- 'dev/specmill-rebuild/sources/amos-staging-2026-10-18.json'
stopifnot(identical(digest::digest(file=canonical,algo='sha256'),'1d0ef1fbd813e2381a1e6e841d69e5070ee438e588a01dc3298b984ba7ca5f35'),
 identical(digest::digest(file=staging,algo='sha256'),'627d6cb4ec4aab1448163b578a6b857476c817a93404369cddfe87a4dd54c401'))
s <- jsonlite::read_json(canonical)
services <- c('apis/amos-pilot.yml','apis/chemi-amos-prod-full.yml','apis/chemi-amos-direct-reads.yml')
keys <- unique(unlist(lapply(services,function(p)names(yaml::read_yaml(p)$operations))))
paths <- list()
for(k in keys) {
 m <- tolower(sub(' .*','',k)); p <- sub('^[^ ]+ ','',k)
 stopifnot(is.list(s$paths[[p]][[m]])); paths[[p]][[m]] <- s$paths[[p]][[m]]
}
corrections <- list('get_similar_structures/{identifier_type}/{identifier}'=c('identifier_type','identifier'),
 'list_sources_by_record_type/{record_type}'='record_type')
for(p in names(corrections)) paths[[paste0('/api/amos/',p)]]$get$parameters <- lapply(corrections[[p]],function(n)
 list(name=n,'in'='path',required=TRUE,type='string'))
paths[['/api/amos/dtxsids/']]$post$responses <- list('200'=list(description='Substance information for supplied DTXSIDs.'))
paths[['/api/amos/dtxsids/']]$post$produces <- list('application/json')
refs <- function(x) if(is.list(x)) unique(c(x[['$ref']],unlist(lapply(x,refs),use.names=FALSE))) else character()
defs <- list(); pending <- refs(paths)
while(length(pending)) {
 r <- pending[[1L]]; pending <- pending[-1L]
 stopifnot(startsWith(r,'#/definitions/')); n <- sub('^#/definitions/','',r)
 if(n %in% names(defs)) next
 stopifnot(!is.null(s$definitions[[n]])); defs[n] <- list(s$definitions[[n]])
 pending <- unique(c(pending,refs(defs[[n]])))
}
bundle <- list(swagger=s$swagger,info=s$info,paths=paths,definitions=defs)
output <- 'schema/chemi-amos-reviewed-native.json'
jsonlite::write_json(bundle,output,pretty=TRUE,auto_unbox=TRUE,null='null')
exceptions <- c('GET /api/amos/get_similar_structures/{identifier_type}/{identifier}',
 'GET /api/amos/list_sources_by_record_type/{record_type}','POST /api/amos/dtxsids/')
for(k in setdiff(keys,exceptions)) {
 m <- tolower(sub(' .*','',k)); p <- sub('^[^ ]+ ','',k)
 stopifnot(identical(bundle$paths[[p]][[m]],s$paths[[p]][[m]]))
}
stopifnot(!'requestBody' %in% unlist(lapply(paths,function(p)unlist(lapply(p,names)))))
record <- list(canonical=canonical,canonical_sha256=digest::digest(file=canonical,algo='sha256'),
 staging=staging,staging_sha256=digest::digest(file=staging,algo='sha256'),
 output=output,output_sha256=digest::digest(file=output,algo='sha256'),dialect='Swagger 2.0 unchanged',
 operations=keys,definition_closure=names(defs),unchanged_operations=setdiff(keys,exceptions),
 changes=list(path_parameters='Only the two existing reviewed string path corrections, no enums or other constraints.',
 responses='Materialize the existing response_correction verbatim: 200 description and produces application/json; remove the now redundant config correction. No request change.',
 removals='Unselected paths and unreferenced definitions only.',server='Canonical lacks origin; preserved unchanged. Existing explicit production mappings/resolver remain in force.'),
 evidence=c('dev/specmill-rebuild/wave-amos-reviewed-paths.json','dev/specmill-rebuild/amos-positive-native-live-review.rds',
 'dev/specmill-rebuild/amos-root-live-review.rds','tests/testthat/fixtures/native-amos-dtxsids.rds','dev/specmill-rebuild/amos-v41/live.rds'),
 ownership='Original service IDs, operation keys, names, files, formals and controls retained.',
 upstream='https://github.com/seanthimons/specmill/issues/27')
jsonlite::write_json(record,'dev/specmill-rebuild/amos-v41/provenance.json',pretty=TRUE,auto_unbox=TRUE)
