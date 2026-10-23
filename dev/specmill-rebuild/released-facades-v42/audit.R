# Preserve source facts separately from byte-compatible facade migration.
legacy <- readRDS('tests/testthat/fixtures/released-facades-v42-legacy.rds')
paths <- c('schema/chemi-chet-prod.json', 'schema/chemi-resolver-prod.json',
  'schema/chemi-toxprints-prod.json', 'schema/chemi-stdizer-prod.json')
protected <- c(paths, 'specmill.yml', 'inst/hook_config.yml', 'NAMESPACE', '.specmill/manifest.json',
  'R/z_specmill_request.R', 'R/z_generic_request.R', 'dev/install_specmill.R', 'dev/specmill-lock.json',
  'dev/specmill_callbacks.R', 'dev/specmill-rebuild/progress.md', 'dev/specmill-rebuild/HANDOFF.md')
stopifnot(!length(system2('git', c('diff', 'cd34efb4', '--', protected), stdout = TRUE)))
hashes <- lapply(protected, function(path) digest::digest(file = path, algo = 'sha256'))
names(hashes) <- protected
jsonlite::write_json(list(base = 'cd34efb4', untouched = hashes),
 'dev/specmill-rebuild/released-facades-v42/untouched.json', auto_unbox = TRUE, pretty = TRUE)
code <- parse('R/chemi_toxprints.R', keep.source = FALSE)
statement <- Filter(function(x) is.call(x) && identical(x[[1L]], as.name('<-')) &&
  identical(x[[2L]], as.name('chemi_toxprints_bulk')), as.list(code))
stopifnot(length(statement) == 1L, identical(statement[[1L]][[3L]], legacy$chemi_toxprints_bulk))
cat('Canonical schemas and parent-owned files unchanged; held bulk body/formals unchanged.\n')
