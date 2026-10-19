# Render only the generated similarity wrapper's help page.
pkgload::load_all('.', quiet = TRUE)
file <- 'R/chemi_resolver_getsimilaritylist.R'
roclet <- roxygen2::rd_roclet()
blocks <- roxygen2::parse_file(file)
results <- roxygen2::roclet_process(roclet, blocks, env = baseenv(), base_path = '.')
stopifnot(identical(names(results), 'chemi_resolver_getsimilaritylist.Rd'))
output <- tempfile('similarity-doc-')
dir.create(output)
dir.create(file.path(output, "man"))
roxygen2::roclet_output(roclet, results, base_path = output)
stopifnot(file.copy(file.path(output, 'man/chemi_resolver_getsimilaritylist.Rd'),
  'man/chemi_resolver_getsimilaritylist.Rd', overwrite = TRUE))
unlink(output, recursive = TRUE)
