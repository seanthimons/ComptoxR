out <- 'dev/specmill-rebuild/canonical-holds-audit'
stopifnot(!file.exists('R/chemi_stdizer_groups_preflight_post.R'),
  !any(grepl('^export[(]chemi_stdizer_groups_preflight_post[)]$', readLines('NAMESPACE'))))
proof <- jsonlite::read_json(file.path(out, 'generation-proof.json'))
stopifnot(proof$validation_requested, proof$freshness, proof$helper_matches_official_scaffold,
  all(vapply(proof$validation, function(x) x$status == 'passed', TRUE)))
for (file in c('R/chemi_stdizer_groups_preflight_post.R', 'man/chemi_stdizer_groups_preflight_post.Rd')) {
  snapshot <- file.path(out, paste0(basename(file), '.txt'))
  hash <- digest::digest(paste(readLines(snapshot), collapse = '\n'), algo = 'sha256', serialize = FALSE)
  stopifnot(identical(hash, proof$owners[[file]]$hash))
}
stopifnot(length(parse(file.path(out, 'chemi_stdizer_groups_preflight_post.R.txt'))) > 0L,
  length(tools::parse_Rd(file.path(out, 'chemi_stdizer_groups_preflight_post.Rd.txt'))) > 0L)
results <- testthat::test_file(file.path(out, 'test-candidate.R'), reporter = 'summary')
summary <- as.data.frame(results)
stopifnot(!any(summary$failed), !any(summary$error), !any(summary$warning), !any(summary$skipped))
jsonlite::write_json(list(tests = nrow(summary), passed = sum(summary$passed),
  failed = sum(summary$failed), errors = sum(summary$error), warnings = sum(summary$warning),
  skipped = sum(summary$skipped), localhost_only = TRUE, deployed_behavior_proved = FALSE,
  root_runtime_adopted = FALSE), file.path(out, 'test-proof.json'), pretty = TRUE, auto_unbox = TRUE)
