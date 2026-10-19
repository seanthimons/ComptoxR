out <- 'dev/specmill-rebuild/canonical-holds-audit/protocol-paging-recheck'
before <- jsonlite::read_json('.specmill/manifest.json')$files
source('dev/generate_specmill.R')
applied <- generate_specmill('apply')
fresh <- generate_specmill('check')
after <- jsonlite::read_json('.specmill/manifest.json')$files
for (file in names(before)) stopifnot(identical(before[[file]], after[[file]]))
for (file in names(after)) stopifnot(identical(specmill:::output_hash(file), after[[file]]$hash))
stopifnot('R/chemi_stdizer_protocols_by_id_post.R' %in% names(after),
  identical(after[['R/chemi_stdizer_protocols_by_id_post.R']]$hash,
    specmill:::output_hash('R/chemi_stdizer_protocols_by_id_post.R')))
saveRDS(list(applied = applied, fresh = fresh), file.path(out, 'root-generation.rds'))
jsonlite::write_json(list(owners = length(after), preceding_owner_records_unchanged = length(before),
  sources = length(fresh$validation), freshness = TRUE, validation = fresh$validation),
  file.path(out, 'root-generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS:', length(after), 'hashes;', length(before), 'preceding owner records unchanged.\n')
