out <- 'dev/specmill-rebuild/released-v50'
source('dev/install_specmill.R'); verify_specmill()
source('dev/specmill-342/emit.R'); emit_issue342(mode = 'check')
before <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(length(before) == 715L)
source('dev/generate_specmill.R')
applied <- generate_specmill('apply')
saveRDS(applied, file.path(out, 'reconciled.rds'))
after <- jsonlite::read_json('.specmill/manifest.json')$files
changed <- names(before)[!vapply(names(before), function(path) identical(before[[path]], after[[path]]), FALSE)]
stopifnot(identical(changed, 'R/chemi_alerts_render.R'), identical(before[['R/chemi_alerts_render.R']]$hash, after[['R/chemi_alerts_render.R']]$hash), is.null(after[['R/chemi_alerts_render.R']]$response_sources))
fresh <- generate_specmill('check')
saveRDS(fresh, file.path(out, 'fresh.rds'))
stopifnot(all(vapply(names(after), function(path) identical(specmill:::output_hash(path), after[[path]]$hash), FALSE)))
jsonlite::write_json(list(pin = jsonlite::read_json('dev/specmill-lock.json'),
  owners = length(after), sources = length(fresh$validation), freshness = TRUE,
  owners_unchanged_except_removal_of_held_render_response_sources = TRUE,
  new_owners = c('R/chemi_descriptors.R', 'R/pubchem_properties.R', 'R/pubchem_search.R', 'R/pubchem_synonyms.R'),
  preceding_records_changed_from_253c38a2 = character(),
  held_duplicate_response = 'https://github.com/seanthimons/specmill/issues/186',
  helper_sha256 = digest::digest(file = 'R/z_specmill_request.R', algo = 'sha256')),
  file.path(out, 'generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS: official50 helper, validated sources, all715 owner hashes and public freshness.\n')
