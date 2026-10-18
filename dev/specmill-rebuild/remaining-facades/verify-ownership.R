lib <- Sys.getenv('SPECMILL_LIBRARY')
stopifnot(nzchar(lib), dir.exists(lib))
loadNamespace('specmill', lib.loc = lib)
stopifnot(identical(utils::packageDescription('specmill', lib.loc = lib)[['Config/specmill/source-commit']],
  '05862bee1804806cea157ff1962300d741516301'))
folder <- 'dev/specmill-rebuild/remaining-facades'
frozen <- readRDS(file.path(folder, 'legacy.rds'))
for (path in setdiff(names(frozen$bytes), 'R/chemi_resolver_safety_flags.R')) {
  stopifnot(identical(readBin(path, 'raw', n = 1e6), frozen$bytes[[path]]))
}
for (name in names(frozen$schemas)) {
  stopifnot(identical(digest::digest(file = paste0('schema/chemi-', name, '-prod.json'), algo = 'sha256'), frozen$schemas[[name]]))
}
manifest <- jsonlite::read_json('.specmill/manifest.json')
paths <- names(manifest$files)
bad <- paths[!vapply(paths, function(path) identical(specmill:::output_hash(path), manifest$files[[path]]$hash), logical(1))]
stopifnot(!length(bad))
for (path in c('R/chemi_resolver_safety_flags.R', 'man/chemi_resolver_safety_flags_bulk.Rd')) {
  stopifnot(identical(manifest$files[[path]]$operations, 'remaining-resolver-facade POST /api/resolver/safety-flags'))
}
message(length(paths), ' owned files match; five held wrappers and three canonical schemas are unchanged.')
