# Render the two ToxPrint help topics from the generated shared source file.
pkgload::load_all('.', quiet = TRUE)
file <- 'R/chemi_toxprints.R'
roclet <- roxygen2::rd_roclet()
blocks <- roxygen2::parse_file(file)
results <- roxygen2::roclet_process(roclet, blocks, env = baseenv(), base_path = '.')
topics <- c('chemi_toxprints.Rd', 'chemi_toxprints_bulk.Rd')
results <- results[topics]
stopifnot(length(results) == 2L, all(!vapply(results, is.null, TRUE)))
output <- tempfile('toxprints-doc-')
dir.create(output)
dir.create(file.path(output, 'man'))
roxygen2::roclet_output(roclet, results, base_path = output)
for (topic in topics) stopifnot(file.copy(file.path(output, 'man', topic),
  file.path('man', topic), overwrite = TRUE))
unlink(output, recursive = TRUE)
