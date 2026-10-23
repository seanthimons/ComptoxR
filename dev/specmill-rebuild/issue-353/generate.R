source('dev/install_specmill.R')
verify_specmill()
callbacks <- new.env(parent = baseenv())
for (file in yaml::read_yaml('specmill.yml')$callback_files) sys.source(file, callbacks)
result <- specmill::generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'apply', validation = TRUE, artifacts = c('wrappers', 'tests'))
stopifnot(!length(result$diagnostics), !length(result$mapping_diagnostics),
  !length(result$retained_diagnostics), !length(result$drift),
  all(vapply(result$validation, function(x) identical(x$status, 'passed'), TRUE)))
before <- jsonlite::read_json('dev/specmill-rebuild/issue-353/before.json')
old_get <- eval(parse(text = before$GET_prefix, keep.source = FALSE)[[1L]][[3L]], baseenv())
new_get <- eval(parse('R/chemi_toxprints.R', keep.source = FALSE)[[1L]][[3L]], baseenv())
stopifnot(identical(formals(old_get), formals(new_get)),
  identical(body(old_get), body(new_get)),
  identical(jsonlite::read_json('.specmill/manifest.json')$files[['R/chemi_toxprints.R']]$operations,
    before$ownership$operations))
jsonlite::write_json(list(validation = result$validation,
  changed = Filter(function(x) x$action != 'unchanged', result$files), GET_implementation_unchanged = TRUE),
  'dev/specmill-rebuild/issue-353/generation.json', pretty = TRUE, auto_unbox = TRUE)
