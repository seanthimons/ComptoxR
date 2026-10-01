# Verify the adopted helper without replacing client-owned files.
source('dev/install_specmill.R')
source('dev/specmill-342/emit.R')
root <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[[1L]] else '.'
scaffold <- emit_issue342(root)
record <- jsonlite::read_json(file.path(root, '.specmill/helpers/.ct_request.json'))
stopifnot(
  identical(record$baseline, scaffold$code),
  identical(record$baseline_hash, specmill:::text_hash(scaffold$code)),
  !any(grepl('specmill::', readLines(file.path(root, 'R/z_specmill_request.R')), fixed = TRUE))
)
local({
  scratch <- tempfile('helper-adoption-')
  dir.create(file.path(scratch, 'R'), recursive = TRUE)
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
  emit_issue342(scratch, 'apply')
  helper <- file.path(scratch, 'R/z_specmill_request.R')
  stopifnot(identical(readLines(helper), readLines(file.path(root, 'R/z_specmill_request.R'))))
  original <- digest::digest(file = helper, algo = 'sha256')
  emit_issue342(scratch, 'apply')
  stopifnot(identical(original, digest::digest(file = helper, algo = 'sha256')))
  cat('\n# Client customization\n', file = helper, append = TRUE)
  customized <- digest::digest(file = helper, algo = 'sha256')
  error <- tryCatch(emit_issue342(scratch, 'apply'), error = identity)
  stopifnot(
    inherits(error, 'error'),
    grepl('Protected native helper', conditionMessage(error)),
    identical(customized, digest::digest(file = helper, algo = 'sha256'))
  )
  emit_issue342(scratch, 'apply', adopt = customized)
  stopifnot(identical(original, digest::digest(file = helper, algo = 'sha256')))
  lock <- file.path(scratch, 'wrong-version.json')
  pin <- jsonlite::read_json('dev/specmill-lock.json')
  pin$version <- 'incorrect-version'
  jsonlite::write_json(pin, lock, auto_unbox = TRUE)
  error <- tryCatch(verify_specmill(lock = lock), error = identity)
  stopifnot(inherits(error, 'error'), grepl('provenance does not match', conditionMessage(error)))
})
manifest <- jsonlite::read_json(file.path(root, '.specmill/manifest.json'))
stopifnot(!any(c('R/z_generic_request.R', 'R/z_specmill_request.R') %in% names(manifest$files)))
review <- jsonlite::read_json('dev/specmill-342/adoption.json')
for (file in c('R/z_generic_request.R', 'R/z_specmill_request.R')) {
  stopifnot(identical(digest::digest(file = file.path(root, file), algo = 'sha256'), review$adopted_sha256[[file]]))
}
cat('Emission freshness, idempotence, provenance, version and whole-file ownership protections pass.\n')
