# Run after stage.R. Check repeat emission, provenance and installation identity.
source('dev/install_specmill.R')
verify_specmill()
root <- 'dev/specmill-pilot/artifacts/issue-342-rehearsal'
scaffold <- specmill:::request_helper_scaffold(
  '.ct_request',
  'https://example.invalid',
  NULL,
  'COMPTOXR_NATIVE_DRY_RUN',
  companions = 'batching'
)
helper <- file.path(root, 'R/z_specmill_request.R')
record <- jsonlite::read_json(file.path(root, '.specmill/helpers/.ct_request.json'))
stopifnot(
  identical(paste(readLines(helper), collapse = '\n'), scaffold$code),
  identical(record$baseline, scaffold$code),
  identical(record$baseline_hash, specmill:::text_hash(scaffold$code)),
  !grepl('specmill::', scaffold$code, fixed = TRUE)
)
local({
  lock <- tempfile(fileext = '.json')
  on.exit(unlink(lock), add = TRUE)
  pin <- jsonlite::read_json('dev/specmill-lock.json')
  pin$version <- 'incorrect-version'
  jsonlite::write_json(pin, lock, auto_unbox = TRUE)
  error <- tryCatch(verify_specmill(lock = lock), error = identity)
  stopifnot(inherits(error, 'error'), grepl('provenance does not match', conditionMessage(error)))
})
source('dev/specmill-342/stage.R')
previous <- digest::digest(file = helper, algo = 'sha256')
error <- tryCatch(stage_issue342(root), error = identity)
stopifnot(
  inherits(error, 'error'),
  grepl('destination already exists', conditionMessage(error)),
  identical(previous, digest::digest(file = helper, algo = 'sha256'))
)
cat('Repeated emission, provenance, runtime isolation, version and overwrite protections pass.\n')
