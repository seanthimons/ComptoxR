verify_protected <- function(root = '.') {
  old <- setwd(root)
  on.exit(setwd(old))
  recorded <- readLines('dev/migration-evidence/toolkit-baseline-sha256.txt')
  paths <- substring(recorded, 66L)
  hashes <- substring(recorded, 1L, 64L)
  keep <- grepl('^(R/|schema/|inst/hook_config)', paths)
  actual <- vapply(paths[keep], digest::digest, character(1), algo = 'sha256', file = TRUE)
  stopifnot(identical(unname(actual), unname(hashes[keep])))
  writeLines(
    c(
      paste(sum(keep), 'runtime/schema/hook files match baseline SHA256'),
      paste(digest::digest('data/testing_chemicals.rda', algo = 'sha256', file = TRUE), 'data/testing_chemicals.rda')
    ),
    'dev/migration-evidence/toolkit-protected.txt'
  )
}
if (sys.nframe() == 0L) {
  verify_protected()
}
