# Client selection is explicit; the installed toolkit owns parsing and reporting.
.diff_root <- apipak::script_root('diff_schemas.R')
.diff_callbacks <- new.env(parent = baseenv())
sys.source(file.path(.diff_root, 'dev/apipak_callbacks.R'), envir = .diff_callbacks)
.diff_services <- apipak::load_project(.diff_root, callbacks = .diff_callbacks)$services
.diff_policies <- unlist(
  lapply(.diff_services, function(service) {
    setNames(rep(list(service$policy), length(service$files)), basename(service$files))
  }),
  recursive = FALSE,
  use.names = FALSE
)
names(.diff_policies) <- unlist(lapply(.diff_services, function(service) basename(service$files)), use.names = FALSE)
diff_schemas <- function(old_dir, new_dir, pattern = '\\.json$', stage_priority = NULL, exclude_pattern = NULL) {
  apipak::schema_diff(old_dir, new_dir, pattern, stage_priority, exclude_pattern, .diff_policies)
}
format_diff_markdown <- apipak::format_diff_markdown
count_diff_changes <- apipak::count_diff_changes
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  old_dir <- if (length(args) >= 1L) args[[1L]] else file.path(.diff_root, 'schema_old')
  new_dir <- if (length(args) >= 2L) args[[2L]] else file.path(.diff_root, 'schema')
  results <- diff_schemas(
    old_dir,
    new_dir,
    pattern = '-prod[.]json$',
    stage_priority = 'prod',
    exclude_pattern = 'ui|coverage_baseline|schema_hashes'
  )
  writeLines(format_diff_markdown(results), file.path(.diff_root, 'schema_diff_report.md'))
  counts <- count_diff_changes(results)
  cat(sprintf('BREAKING_COUNT=%d\nNONBREAKING_COUNT=%d\n', counts$breaking, counts$nonbreaking))
}
