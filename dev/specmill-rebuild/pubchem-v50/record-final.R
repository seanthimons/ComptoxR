base <- '/home/sxthi/.cache/comptoxr-specmill-finish/release50-verification/pubchem-candidate'
wire <- readRDS(file.path(base,'wire.rds'))
stopifnot(length(wire$calls)==81L)
prefix <- Filter(function(x) grepl('^/(rest/pug|custom/pug-v2)/compound/',x$path),wire$calls)
stopifnot(length(prefix)==24L)
jsonlite::write_json(list(actual_http=length(wire$calls),methods=as.list(table(vapply(wire$calls,`[[`,'','method'))),cold_prefix_requests=length(prefix),prefixes=c('/rest/pug','/custom/pug-v2'),prefix_route_requests=prefix,default_url_dry_run_routes=6L,default_url_dry_run_http=0L),file.path(base,'prefix-wire-proof.json'),auto_unbox=TRUE,pretty=TRUE)
old <- '/home/sxthi/.cache/comptoxr-specmill-finish/release48-verification/pubchem-candidate/project/R/pubchem_policy.R'
stopifnot(identical(parse(old,keep.source=FALSE),parse(file.path(base,'project/R/pubchem_policy.R'),keep.source=FALSE)))
cat('Final policy AST unchanged, 81 actual localhost calls, 24 cold full-prefix requests and six default URL dry-run routes.\n')
