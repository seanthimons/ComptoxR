# Bump the pinned specmill toolkit and re-adopt everything it generates.
#
# Usage: Rscript dev/bump_specmill.R [ref] [--review=<text>]
#
# `ref` is any commit-ish in the specmill clone at SPECMILL_SOURCE_REPO
# (default ../specmill), after `git fetch origin`; it defaults to origin/main.
# The script rewrites dev/specmill-lock.json, installs and verifies the new
# toolkit, re-emits the request helper, records the adoption in
# dev/specmill-342/adoption.json, regenerates wrappers and tests, and runs the
# freshness checks that specmill-maintenance runs. If a step fails, discard the
# partial bump with `git checkout -- .`, remove any new files `git status`
# lists, and re-run `Rscript dev/install_specmill.R`.
source('dev/install_specmill.R')

git <- function(repo, ...) {
  out <- system2('git', c('-C', shQuote(repo), ...), stdout = TRUE)
  if (!is.null(attr(out, 'status'))) stop('git ', paste(c(...), collapse = ' '), ' failed.')
  out
}

run <- function(...) {
  cat('\n==> Rscript', ..., '\n')
  if (system2(file.path(R.home('bin'), 'Rscript'), c(...)) != 0L) {
    stop('Step failed: Rscript ', paste(c(...), collapse = ' '))
  }
}

args <- commandArgs(TRUE)
flags <- grepl('^--', args)
if (any(flags & !grepl('^--review=', args)) || sum(!flags) > 1L) {
  stop('Usage: Rscript dev/bump_specmill.R [ref] [--review=<text>]')
}
review <- sub('^--review=', '', args[flags])
review <- review[nzchar(review)]
ref <- c(args[!flags], 'origin/main')[[1L]]
repo <- normalizePath(Sys.getenv('SPECMILL_SOURCE_REPO', '../specmill'), mustWork = TRUE)
lock <- 'dev/specmill-lock.json'
helper <- 'R/z_specmill_request.R'
adoption_path <- 'dev/specmill-342/adoption.json'

if (length(system2('git', c('status', '--porcelain'), stdout = TRUE))) {
  stop('Commit or stash ComptoxR changes, including untracked files, first.')
}
fetched <- tryCatch(git(repo, 'fetch', '--quiet', 'origin'), error = identity)
if (inherits(fetched, 'error')) warning('Could not fetch specmill; using the local clone as is.')
commit <- git(repo, 'rev-parse', '--verify', shQuote(paste0(ref, '^{commit}')))
pin <- jsonlite::read_json(lock)
if (identical(pin$source_commit, commit)) stop('specmill is already pinned to ', commit, '.')

description <- read.dcf(textConnection(git(repo, 'show', paste0(commit, ':DESCRIPTION'))))
old_version <- pin$version
pin$version <- unname(description[1L, 'Version'])
pin$source_commit <- commit
archive <- tempfile(fileext = '.tar')
pin$source_archive_sha256 <- archive_specmill(repo, commit, archive)
unlink(archive)
if (identical(old_version, pin$version)) {
  warning('Version unchanged; reinstalling replaces the current ', old_version, ' toolkit library.')
}
jsonlite::write_json(pin, lock, auto_unbox = TRUE, pretty = TRUE)
cat('Pinned specmill ', old_version, ' -> ', pin$version, ' (', commit, ')\n', sep = '')

# Child processes inherit these: the installer reads the clone, and the
# generators load specmill from the versioned toolkit library.
Sys.setenv(
  SPECMILL_SOURCE_REPO = repo,
  R_LIBS = file.path(getwd(), 'dev/specmill-pilot/artifacts/toolkit-library', pin$version)
)
run('dev/install_specmill.R')

# The current helper is the reviewed one, so it may be replaced.
old_helper <- digest::digest(file = helper, algo = 'sha256')
run('-e', shQuote(sprintf("source('dev/specmill-342/emit.R'); emit_issue342(mode = 'apply', adopt = '%s')", old_helper)))
new_helper <- digest::digest(file = helper, algo = 'sha256')
helper_changed <- !identical(old_helper, new_helper)

adoption <- jsonlite::read_json(adoption_path)
current <- adoption$current_adoption
adoption$adoption_history <- c(adoption$adoption_history, list(current))
current$reviewed_at <- format(Sys.Date())
current$base_commit <- git('.', 'rev-parse', 'HEAD')
current$toolkit <- pin
current$adopted_sha256 <- list(
  `R/z_specmill_request.R` = new_helper,
  `dev/specmill-342/emit.R` = digest::digest(file = 'dev/specmill-342/emit.R', algo = 'sha256')
)
current$review <- if (length(review)) {
  review
} else {
  paste0('Specmill ', pin$version, ' scaffold emission; helper output ', if (helper_changed) 'changed.' else 'unchanged.')
}
adoption$current_adoption <- current
jsonlite::write_json(adoption, adoption_path, auto_unbox = TRUE, pretty = TRUE)

# Second --apply records the man/ and NAMESPACE that document() rewrote.
run('dev/generate_specmill.R', '--apply')
run('-e', shQuote('devtools::document()'))
run('dev/generate_specmill.R', '--apply')
run('dev/generate_tests.R', '--generate')
run('dev/check_public_api.R')
run('dev/check_hook_config.R')
run('dev/specmill-342/verify.R')
run('dev/specmill-333/verify.R')
run('dev/generate_specmill.R', '--check')
run('dev/generate_tests.R', '--check')

cat(
  '\nBumped specmill ', old_version, ' -> ', pin$version, '. Request helper ',
  if (helper_changed) 'CHANGED: review the diff of R/z_specmill_request.R' else 'unchanged', '.\n',
  'Next: run the full test suite (devtools::test()), adjust the review note in ',
  adoption_path, ' if needed, add a NEWS.md bullet, and commit.\n',
  sep = ''
)
