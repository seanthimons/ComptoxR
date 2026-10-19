out <- 'dev/specmill-rebuild/released-booleans-v45'
source('dev/install_specmill.R')
verify_specmill()
source('dev/specmill-342/emit.R')
old_helper <- digest::digest(file = 'R/z_specmill_request.R', algo = 'sha256')
emit_issue342(mode = 'apply', adopt = old_helper)
emit_issue342(mode = 'check')
before <- jsonlite::read_json('.specmill/manifest.json')$files
source('dev/generate_specmill.R')
applied <- generate_specmill('apply')
saveRDS(applied, file.path(out, 'applied.rds'))
cat('ROOT APPLY COMPLETE\n')
fresh <- generate_specmill('check')
saveRDS(fresh, file.path(out, 'fresh.rds'))
after <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(all(vapply(names(after), function(path) identical(specmill:::output_hash(path), after[[path]]$hash), FALSE)))
changed <- names(before)[!vapply(names(before), function(path) identical(before[[path]], after[[path]]), FALSE)]
jsonlite::write_json(list(pin = jsonlite::read_json('dev/specmill-lock.json'),
  owners = length(after), preceding_owners = length(before), changed_preceding_records = changed,
  sources = length(fresh$validation), freshness = TRUE, old_helper_sha256 = old_helper,
  helper_sha256 = digest::digest(file = 'R/z_specmill_request.R', algo = 'sha256')),
  file.path(out, 'generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS: official helper, validated generation/freshness and', length(after), 'owner hashes.\n')
