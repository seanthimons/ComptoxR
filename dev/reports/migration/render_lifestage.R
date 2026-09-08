output <- normalizePath('.migration-evidence', winslash = '/')
rmarkdown::render('vignettes/articles/ecotox.Rmd', output_format = 'html_document', output_dir = output, quiet = TRUE)
rmarkdown::render(
  'vignettes/articles/risk-evidence-compilation.Rmd',
  output_format = 'html_document',
  output_dir = output,
  quiet = TRUE
)
html <- paste(readLines(file.path(output, 'ecotox.html'), warn = FALSE), collapse = '\n')
stopifnot(
  grepl('harmonize_lifestage', html),
  grepl('Restart the server', html),
  grepl('not independently reviewed', html)
)
message('Migration articles rendered with explicit mapping and restart instructions.')
