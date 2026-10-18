source('dev/install_specmill.R')
verify_specmill()
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
sys.source('dev/specmill-rebuild/remaining-facades/callbacks.R', callbacks)
# Explicitly retire the superseded owned helper-only test through the public API.
retired <- 'tests/testthat/test-contract-chemi_safety_rqcodes.R'
specmill::apply_files('.', list(), remove = retired, mode = 'apply')
# Match the existing root maintenance workflow's wrapper/test artifact scope.
args <- list(root = '.', config = 'specmill.yml', callbacks = callbacks,
  validation = TRUE, artifacts = c('wrappers', 'tests'))
applied <- do.call(specmill::generate_client, c(args, list(mode = 'apply')))
stopifnot(!length(applied$diagnostics), !length(applied$mapping_diagnostics), !length(applied$drift))
cat('Root wrapper/test apply passed.\n')
fresh <- do.call(specmill::generate_client, c(args, list(mode = 'check')))
stopifnot(!length(fresh$diagnostics), !length(fresh$mapping_diagnostics), !length(fresh$drift))
saveRDS(list(apply = applied, check = fresh),
  'dev/specmill-rebuild/issue-352/generation-results.rds')
cat('PASS: validated root wrapper/test generation and freshness.\n')
