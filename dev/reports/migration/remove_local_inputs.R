remove_local_inputs <- function(local_root, apply = FALSE) {
  root <- normalizePath('schema', winslash = '/', mustWork = TRUE)
  local_root <- normalizePath(local_root, winslash = '/', mustWork = TRUE)
  stopifnot(!startsWith(local_root, paste0(root, '/')))
  files <- list.files(root, '-(dev|staging)[.]json$', full.names = TRUE)
  copies <- file.path(local_root, basename(files))
  stopifnot(all(file.exists(copies)))
  hashes <- vapply(files, function(f) digest::digest(file = f, algo = 'sha256'), character(1))
  saved <- vapply(copies, function(f) digest::digest(file = f, algo = 'sha256'), character(1))
  stopifnot(identical(unname(hashes), unname(saved)))
  evidence <- data.frame(file = basename(files), sha256 = unname(hashes))
  if (apply) {
    utils::write.csv(evidence, 'dev/reports/migration/local-input-hashes.csv', row.names = FALSE)
    stopifnot(all(dirname(files) == root), unlink(files) == 0L, !any(file.exists(files)))
  }
  evidence
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) %in% 1:2)
  print(remove_local_inputs(args[1], '--apply' %in% args))
}
