freeze_toolkit <- function(root = '.') {
  old <- setwd(root)
  on.exit(setwd(old))
  if (file.exists('dev/migration-evidence/toolkit-baseline-sha256.txt')) {
    stop('Baseline is already frozen. Use a fresh checkout to establish a new baseline.')
  }
  files <- system2(
    'git',
    c('ls-files', 'schema', 'inst/hook_config.yml', 'inst/hook_config_generated.yml', 'R', 'tests/testthat', 'dev'),
    stdout = TRUE
  )
  hashes <- vapply(files, digest::digest, character(1), algo = 'sha256', file = TRUE)
  writeLines(paste(hashes, files), 'dev/migration-evidence/toolkit-baseline-sha256.txt')
  writeLines(
    c(system2('git', c('rev-parse', 'HEAD'), stdout = TRUE), capture.output(sessionInfo())),
    'dev/migration-evidence/toolkit-baseline-session.txt'
  )
  devtools::test(
    filter = 'generate_tests_pipeline|stub_generation_call_shape|stub_generation_multischema|diff_schemas_counts|hooks'
  )
}
if (sys.nframe() == 0L) {
  freeze_toolkit()
}
