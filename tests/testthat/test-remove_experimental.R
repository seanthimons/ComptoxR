root <- normalizePath(testthat::test_path('..', '..'), winslash = '/')
script <- file.path(root, 'dev/toolkit_adapter.R')
if (!file.exists(script)) {
  testthat::skip('Maintainer-only ownership metadata is excluded from source archives')
}
source(script, local = TRUE)

test_that('generated ownership covers selected operations and leaves manual sources unowned', {
  manifest <- jsonlite::read_json(file.path(root, '.apipak/manifest.json'))
  inventory <- comptox_inventory(root)
  expect_true(all(file.exists(file.path(root, names(manifest$files)))))
  owners <- unlist(lapply(manifest$files, `[[`, 'operations'), use.names = FALSE)
  expect_true(all(owners %in% names(inventory$operations)))
  manual <- vapply(inventory$manual_exports, `[[`, character(1), 'file')
  expect_length(intersect(manual, names(manifest$files)), 0)
})

test_that('schema workflow blocks failed inputs before generation and keeps explicit rebuild flags', {
  workflow <- yaml::yaml.load(
    paste(
      readLines(
        file.path(root, '.github/workflows/schema-check.yml'),
        encoding = 'UTF-8'
      ),
      collapse = '\n'
    ),
    eval.expr = FALSE
  )
  steps <- workflow$jobs[[1L]]$steps
  for (id in c('download', 'hash', 'diff', 'gaps')) {
    step <- Filter(function(x) identical(x$id, id), steps)[[1L]]
    expect_false(isTRUE(step[['continue-on-error']]))
  }
  run <- paste(vapply(steps, function(x) if (is.null(x$run)) '' else x$run, character(1)), collapse = '\n')
  for (prefix in c('ct', 'chemi', 'epi')) {
    expect_true(grepl(paste0('--rebuild=', prefix), run, fixed = TRUE))
  }
})
