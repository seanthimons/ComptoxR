# Assert the useful parity controls and the exact reasons adoption remains held.
# Run from the package root after verify.R.
directory <- 'dev/specmill-rebuild/chet-search-candidate'
results <- readRDS(file.path(directory, 'results.rds'))
find <- function(name, args, status) {
  hit <- Filter(function(x) identical(x$name, name) && identical(x$args, args) && identical(x$status, status) && is.null(x$payload), results)
  stopifnot(length(hit) == 1L)
  hit[[1L]]
}
counts <- 'chemi_chet_reaction_searchcounts'
page <- 'chemi_chet_reaction_database_old_by_pagenum_and_searchterm'
for (name in c(counts, page)) {
  input <- if (name == counts) 'one' else 1L
  for (status in list(200L, 404L, 500L, 'transport')) {
    stopifnot(find(name, list(input, NULL), status)$equal)
  }
  stopifnot(is.null(find(name, list(input, NULL), 200L)$candidate$error))
  unauthorized <- find(name, list(input, NULL), 401L)
  stopifnot('specmill_call_error' %in% unauthorized$candidate$error$class,
    identical(unauthorized$old_wire, unauthorized$candidate_wire))
}
for (case in list(list(counts, c('one', 'two')), list(page, c(1L, 2L)))) {
  blocked <- find(case[[1L]], list(case[[2L]], 'chemical'), 200L)
  stopifnot('rlang_error' %in% blocked$old$error$class,
    grepl('Cannot use path_params with batching', blocked$old$error$message, fixed = TRUE),
    is.null(blocked$candidate$error), !length(blocked$old_wire), !length(blocked$candidate_wire))
}
permissive <- find(counts, list(1L, NULL), 200L)
stopifnot(is.null(permissive$old$error), !is.null(permissive$candidate$error),
  length(permissive$old_wire) == 1L, !length(permissive$candidate_wire))
suppressPackageStartupMessages(pkgload::load_all('.', quiet = TRUE))
withr::with_options(list(comptoxr_native.request = list(timeout = -1)), {
  for (name in c(counts, page)) {
    environment <- new.env(parent = asNamespace('ComptoxR'))
    sys.source(file.path(directory, paste0(name, '.R')), environment)
    fn <- environment[[name]]; environment(fn) <- asNamespace('ComptoxR')
    error <- tryCatch(fn(if (name == counts) c('one', 'two') else c(1L, 2L)), error = identity)
    stopifnot(inherits(error, 'specmill_call_error'), grepl('timeout must be', conditionMessage(error)))
  }
})
cat('Parity controls, held preflight/type regressions, hard 401 and hard configuration assertions pass.\n')
