# Launch with a persistent TMPDIR and the verified official library as argument.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !startsWith(tempdir(), '/tmp/'))
.libPaths(c(normalizePath(args[[1L]]), .libPaths()))
stopifnot(as.character(packageVersion('specmill')) == '0.1.41',
  packageDescription('specmill')$`Config/specmill/source-commit` == '05862bee1804806cea157ff1962300d741516301')
root <- 'dev/specmill-rebuild/chet-chemical-dl'
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
canonical <- digest::digest(file = 'schema/chemi-chet-prod.json', algo = 'sha256')
# Adopt only the reviewed, pre-generation NAMESPACE from base 341b8526.
manifest <- jsonlite::read_json('.specmill/manifest.json')
adopt <- if (is.null(manifest$files$NAMESPACE)) {
  list(NAMESPACE = '85f2e1cd8da15eb12eae45766c105d3c7deb92d5a6ed3b63e3226c4bd832871c')
} else list()
run <- function(mode) specmill::generate_client('.', config = file.path(root, 'specmill.yml'),
  mode = mode, callbacks = callbacks, validation = TRUE, adopt = if (mode == 'apply') adopt else list())
plan <- run('apply')
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$drift))
print(plan)
fresh <- run('check')
stopifnot(!length(fresh$diagnostics), !length(fresh$mapping_diagnostics), !length(fresh$drift),
  identical(canonical, digest::digest(file = 'schema/chemi-chet-prod.json', algo = 'sha256')))
print(fresh)
paths <- c('schema/chemi-chet-prod.json', 'schema/chemi-chet-chemical-dl-reviewed.json',
  'apis/chemi-chet-chemical-dl-reviewed.yml', 'R/chemi_chet_chemicals_chemical_dl.R',
  'man/chemi_chet_chemicals_chemical_dl.Rd', 'NAMESPACE', 'R/z_specmill_request.R',
  'dev/specmill-lock.json', 'tests/testthat/test-native_chet_chemical_dl.R',
  'tests/testthat/fixtures/chet-chemical-dl.csv', '.specmill/manifest.json')
record <- list(specmill_version = as.character(packageVersion('specmill')),
  source_commit = packageDescription('specmill')$`Config/specmill/source-commit`,
  validation = TRUE, reviewed_pre_generation_adoption = adopt, diagnostics = plan$diagnostics, mapping_diagnostics = plan$mapping_diagnostics,
  retained_diagnostics = plan$retained_diagnostics, drift = plan$drift, fresh_check = TRUE,
  sha256 = stats::setNames(lapply(paths, function(path) digest::digest(file = path, algo = 'sha256')), paths))
jsonlite::write_json(record, file.path(root, 'verification.json'), pretty = TRUE, auto_unbox = TRUE, null = 'null')
cat('Official v0.1.41 validation=TRUE apply and fresh check passed.\n')
