out <- 'dev/specmill-rebuild/released-v50'
source('dev/install_specmill.R'); verify_specmill()
stopifnot(identical(as.character(utils::packageVersion('specmill')), '0.1.50'))
source('dev/specmill-342/emit.R'); emit_issue342(mode = 'check')
before <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(length(before) == 711L)
retirement <- jsonlite::read_json('dev/specmill-rebuild/pubchem-v50/retire-helper-contracts.json')$paths_sha256
for (path in names(retirement)) {
  stopifnot(identical(digest::digest(file = path, algo = 'sha256'), retirement[[path]]),
    is.null(before[[path]]))
  archive <- file.path(out, 'retired-helper-tests', basename(path))
  dir.create(dirname(archive), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(path, archive))
}
retired <- specmill::apply_files('.', list(), remove = names(retirement), mode = 'apply', owned = function(path) {
  relative <- sub(paste0(normalizePath('.'), '/'), '', path, fixed = TRUE)
  !is.null(retirement[[relative]]) && identical(digest::digest(file = path, algo = 'sha256'), retirement[[relative]])
})
saveRDS(retired, file.path(out, 'test-retirement.rds'))
source('dev/generate_specmill.R')
plan <- generate_specmill('plan')
saveRDS(plan, file.path(out, 'plan.rds'))
stopifnot(!any(vapply(plan$files, function(x) identical(x$action, 'protected'), FALSE)))
applied <- generate_specmill('apply')
saveRDS(applied, file.path(out, 'applied.rds'))
cat('ROOT50 APPLY COMPLETE\n')
after <- jsonlite::read_json('.specmill/manifest.json')$files
fresh <- generate_specmill('check')
saveRDS(fresh, file.path(out, 'fresh.rds'))
stopifnot(all(vapply(names(after), function(path) identical(specmill:::output_hash(path), after[[path]]$hash), FALSE)))
changed <- intersect(names(before), names(after))
changed <- changed[!vapply(changed, function(path) identical(before[[path]], after[[path]]), FALSE)]
jsonlite::write_json(list(pin = jsonlite::read_json('dev/specmill-lock.json'),
  owners = length(after), preceding_owners = length(before),
  removed_owners = setdiff(names(before), names(after)),
  changed_preceding_records = changed, new_owners = setdiff(names(after), names(before)),
  sources = length(fresh$validation), freshness = TRUE,
  helper_sha256 = digest::digest(file = 'R/z_specmill_request.R', algo = 'sha256')),
  file.path(out, 'generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS: official50 helper, validated sources, all owner hashes and public freshness.\n')
