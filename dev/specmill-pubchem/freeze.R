# Freeze unchanged root implementations, including the actual transport boundary.
stopifnot(startsWith(system('git rev-parse HEAD', intern = TRUE), '341b8526'))
paths <- c('R/pubchem_properties.R', 'R/pubchem_search.R', 'R/pubchem_synonyms.R')
functions <- list()
for (path in paths) {
  for (expr in parse(path)) if (is.call(expr) && identical(expr[[1L]], as.name('<-'))) {
    functions[[as.character(expr[[2L]])]] <- expr[[3L]]
  }
}
for (expr in parse('R/z_generic_request.R')) if (is.call(expr) && identical(expr[[1L]], as.name('<-')) &&
    identical(expr[[2L]], as.name('generic_pubchem_request'))) functions$generic_pubchem_request <- expr[[3L]]
saveRDS(list(base = system('git rev-parse HEAD', intern = TRUE), functions = functions,
  hashes = setNames(lapply(paths, function(path) digest::digest(file = path, algo = 'sha256')), paths)),
  'tests/testthat/fixtures/pubchem-retained-originals.rds', version = 3)
