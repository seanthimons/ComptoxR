out <- 'dev/specmill-rebuild/released-v51'
invisible(parse(file.path(out, 'generate.R')))
source('dev/install_specmill.R'); verify_specmill()
for (name in c('applied', 'root-fresh')) {
  result <- readRDS(file.path(out, paste0(name, '.rds')))
  stopifnot(length(result$validation) == 34L,
    all(vapply(result$validation, function(x) identical(x$status, 'passed'), FALSE)),
    !length(result$diagnostics), !length(result$mapping_diagnostics), !length(result$drift))
  actions <- vapply(result$files, `[[`, '', 'action')
  stopifnot(!any(actions %in% c('remove', 'protected')))
  writes <- vapply(result$files[actions == 'write'], `[[`, '', 'file')
  if (name == 'applied') stopifnot(identical(unname(writes), '.specmill/manifest.json'))
  else stopifnot(!length(writes))
}
files <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(length(files) == 715L,
  all(vapply(names(files), function(p) identical(specmill:::output_hash(p), files[[p]]$hash), FALSE)))
state <- jsonlite::read_json(file.path(out, 'before-state.json'))
for (group in c('core', 'schema_hashes')) stopifnot(all(vapply(names(state[[group]]), function(p)
  identical(digest::digest(file = p, algo = 'sha256'), state[[group]][[p]]), FALSE)))
jsonlite::write_json(list(saved_results_verified_in_fresh_process = TRUE, validation = TRUE,
  sources = 34L, owners = 715L, public_freshness = TRUE, only_apply_write = '.specmill/manifest.json',
  runner_parses = TRUE, package_core_and_schema_hashes_unchanged = TRUE),
  file.path(out, 'saved-proof-verification.json'), pretty = TRUE, auto_unbox = TRUE)
cat('PASS saved root results, all hashes, current script parse in fresh R process.\n')
