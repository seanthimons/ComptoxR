# Deletion/rebuild rehearsal (#327, reused by #328). Run from the package root of a
# clean, committed checkout. Never deletes in the working tree: it creates a detached
# worktree under ignored artifacts, removes only allowlisted files there, regenerates,
# and requires git to report no difference afterwards.
# Usage: Rscript dev/specmill-rebuild/rehearse.R [allowlist.json]
args <- commandArgs(TRUE)
allowlist_file <- if (length(args)) args[[1]] else 'dev/specmill-rebuild/removal-allowlist.json'
root <- normalizePath('.')
run <- function(cmd, dir = root) {
  status <- system(sprintf('cd %s && %s', shQuote(dir), cmd))
  if (status != 0L) stop('Command failed (', status, '): ', cmd)
}
capture <- function(cmd, dir) system(sprintf('cd %s && %s', shQuote(dir), cmd), intern = TRUE)
stopifnot(length(capture('git status --porcelain', root)) == 0L)
commit <- capture('git rev-parse HEAD', root)
allowlist <- jsonlite::read_json(allowlist_file)

work <- file.path(root, 'dev/specmill-pilot/artifacts', paste0('rebuild-', substr(commit, 1, 12)))
if (dir.exists(work)) {
  run(sprintf('git worktree remove --force %s', shQuote(work)))
}
run(sprintf('git worktree add --detach %s %s', shQuote(work), commit))
dir.create(file.path(work, 'dev/specmill-pilot/artifacts'), recursive = TRUE)
file.symlink(file.path(root, 'dev/specmill-pilot/artifacts/toolkit-library'), file.path(work, 'dev/specmill-pilot/artifacts/toolkit-library'))

# Remove only whole allowlisted files whose hash still matches the reviewed allowlist.
files <- names(allowlist$files)
hashes <- vapply(file.path(work, files), digest::digest, '', file = TRUE, algo = 'sha256', USE.NAMES = FALSE)
stopifnot(identical(hashes, unname(unlist(allowlist$files))))
stopifnot(all(file.remove(file.path(work, files))))
deleted <- capture('git status --porcelain', work)
stopifnot(length(deleted) == length(files), all(startsWith(deleted, ' D ')))

run('Rscript dev/generate_specmill.R --apply', work)
after_first <- capture('git status --porcelain', work)
run('Rscript dev/generate_specmill.R --apply', work)
after_second <- capture('git status --porcelain', work)
run('Rscript dev/generate_specmill.R --check', work)
after_check <- capture('git status --porcelain', work)
result <- list(
  commit = commit,
  worktree = work,
  toolkit = jsonlite::read_json(file.path(root, 'dev/specmill-lock.json')),
  air = capture('air --version', work),
  removed_files = length(files),
  removed_operations = allowlist$operations,
  differences_after_regeneration = as.list(after_first),
  differences_after_second_apply = as.list(after_second),
  differences_after_check = as.list(after_check),
  byte_identical = length(after_first) == 0L && length(after_second) == 0L && length(after_check) == 0L
)
jsonlite::write_json(result, file.path(root, 'dev/specmill-pilot/artifacts', paste0('rebuild-', substr(commit, 1, 12), '.json')), pretty = TRUE, auto_unbox = TRUE)
if (!result$byte_identical) {
  print(result[grep('^differences', names(result))])
  stop('Regeneration diverged; worktree kept for review at ', work)
}
cat('Removed', length(files), 'files; regeneration, second apply and check are byte-identical.\nWorktree:', work, '\n')
