# One-time adoption of the explicitly reviewed #358 public contract repair.
source('dev/install_specmill.R')
verify_specmill()
callbacks <- new.env(parent = baseenv())
for (file in yaml::read_yaml('specmill.yml')$callback_files) sys.source(file, callbacks)
paths <- c('R/chemi_resolver_getsimilaritylist.R', 'man/chemi_resolver_getsimilaritylist.Rd')
adopt <- lapply(stats::setNames(paths, paths), specmill:::output_hash)
plan <- specmill::generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'plan', validation = TRUE, artifacts = c('wrappers', 'tests'),
  adopt = adopt)
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics),
  !length(plan$retained_diagnostics),
  all(vapply(plan$validation, function(x) identical(x$status, 'passed'), TRUE)),
  all(vapply(plan$drift, function(x)
    identical(x$endpoint, 'chemi-resolver-reviewed-similarity POST /api/resolver/getsimilaritylist'), TRUE)),
  setequal(vapply(plan$drift, `[[`, '', 'parameter'),
    c('fingerprintName', 'get_chemicals', 'main', 'scoreName')))
jsonlite::write_json(plan$drift, 'dev/specmill-rebuild/issue-358/reviewed-public-drift.json',
  pretty = TRUE, auto_unbox = TRUE)
result <- specmill::generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'apply', validation = TRUE, artifacts = c('wrappers', 'tests'),
  adopt = adopt)
stopifnot(!length(result$diagnostics), !length(result$mapping_diagnostics),
  !length(result$retained_diagnostics), identical(result$drift, plan$drift))
jsonlite::write_json(list(validation = result$validation,
  changed = Filter(function(file) file$action != 'unchanged', result$files)),
  'dev/specmill-rebuild/issue-358/generation.json', pretty = TRUE, auto_unbox = TRUE)
