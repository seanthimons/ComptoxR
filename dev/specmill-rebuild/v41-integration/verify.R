# Run from the package root with TMPDIR on a filesystem with enough free space.
source('dev/install_specmill.R')
verify_specmill()
source('dev/specmill-342/emit.R')
emit_issue342(mode = 'check')
callbacks <- new.env(parent = baseenv())
for (file in yaml::read_yaml('specmill.yml')$callback_files) sys.source(file, callbacks)
plan <- specmill::generate_client(root = '.', config = 'specmill.yml',
  callbacks = callbacks, mode = 'check', artifacts = c('wrappers', 'tests'),
  validation = TRUE)
stopifnot(length(plan$diagnostics) == 0L, length(plan$mapping_diagnostics) == 0L,
  length(plan$retained_diagnostics) == 0L, length(plan$drift) == 0L,
  all(vapply(plan$files, `[[`, '', 'action') == 'unchanged'))
manifest <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(all(vapply(names(manifest), function(path)
  identical(specmill:::output_hash(path), manifest[[path]]$hash), logical(1))))
source('dev/generate_tests.R')
generate_tests_main(c('--check'))
