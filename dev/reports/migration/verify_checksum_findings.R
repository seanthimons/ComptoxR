verify_checksum_findings <- function() {
  log <- readLines('.migration-evidence/gitleaks.log', warn = FALSE)
  fingerprints <- trimws(sub('.*Fingerprint: *', '', grep('Fingerprint:', log, value = TRUE)))
  prefix <- 'ab04f0a59004e9a689bbc3939a131badbab67487:dev/reports/migration/baseline-files.csv:'
  stopifnot(all(startsWith(fingerprints, prefix)))
  rows <- as.integer(sub('.*:', '', fingerprints)) - 1L
  records <- read.csv('dev/reports/migration/baseline-files.csv')[rows, ]
  actual <- unname(tools::md5sum(file.path('C:/Users/sxthi/Documents/ComptoxR', records$path)))
  stopifnot(identical(actual, records$md5))
  writeLines(
    c('# Verified MD5 checksums; exact commit/file/rule/line exceptions only.', fingerprints),
    '.gitleaksignore'
  )
  message(length(fingerprints), ' checksum findings verified against frozen source files.')
}
if (sys.nframe() == 0L) {
  verify_checksum_findings()
}
