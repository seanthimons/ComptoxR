verify_harmonizer_migration <- function(
  root = 'C:/Users/sxthi/Documents/amos-harmonizer/.worktrees/feat/envharmonizer-lifestage'
) {
  package <- file.path(root, 'artifacts/envharmonizer_0.1.0.tar.gz')
  stopifnot(identical(
    digest::digest(file = package, algo = 'sha256'),
    '4afe80e6d806fcb0279a93c159e9e7ce5c0d4cbdaca6fa36304d0579a914c6b0'
  ))
  inventory <- utils::read.csv(file.path(root, 'reports/source-inventory.csv'))
  original <- file.path('C:/Users/sxthi/Documents/ComptoxR', inventory$path)
  copied <- file.path(root, 'dev/lifestage/history/comptoxr', inventory$path)
  hash <- function(paths) {
    unname(vapply(paths, function(path) digest::digest(file = path, algo = 'sha256'), character(1)))
  }
  stopifnot(identical(hash(original), inventory$sha256), identical(hash(copied), inventory$sha256))
  checks <- new.env(parent = globalenv())
  sys.source(file.path(root, 'scripts/verify-release.R'), checks)
  checks$verify_release(root)
  library <- file.path(normalizePath('.migration-evidence', winslash = '/'), 'harmonizer-library')
  dir.create(library, recursive = TRUE, showWarnings = FALSE)
  utils::install.packages(package, repos = NULL, type = 'source', lib = library)
  sys.source(file.path(root, 'scripts/check-installed.R'), checks)
  checks$check_installed(library, file.path(root, 'reports/baseline.rds'), '.migration-evidence/harmonizer-review')
  message('Coordinator verified source hashes, release files, and exact installed harmonizer tarball.')
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  verify_harmonizer_migration()
}
