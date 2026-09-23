#!/usr/bin/env Rscript
# Offline package gates; focused tests and localhost transport run separately.
args <- commandArgs(TRUE)
root <- normalizePath(if (length(args)) args[[1]] else ".", mustWork = TRUE)
baseline <- file.path(root, "dev/specmill-pilot/artifacts/before-source")
stopifnot(file.exists(file.path(baseline, "DESCRIPTION")))
output <- file.path(root, "dev/specmill-pilot/artifacts")
env <- c(
  `_R_CHECK_FORCE_SUGGESTS_` = "false",
  `_R_CHECK_CRAN_INCOMING_REMOTE_` = "false",
  `_R_CHECK_CRAN_INCOMING_` = "false",
  R_ENVIRON_USER = "/dev/null",
  R_PROFILE_USER = "/dev/null",
  http_proxy = "http://127.0.0.1:9",
  https_proxy = "http://127.0.0.1:9",
  HTTP_PROXY = "http://127.0.0.1:9",
  HTTPS_PROXY = "http://127.0.0.1:9",
  ALL_PROXY = "http://127.0.0.1:9",
  NO_PROXY = "127.0.0.1,localhost"
)
run_gate <- function(source, label) {
  path <- file.path(output, paste0("check-", label))
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  desc <- read.dcf(file.path(source, "DESCRIPTION"))
  runtime <- paste(desc[1, intersect(colnames(desc), c("Imports", "Depends"))], collapse = ",")
  stopifnot(!grepl("(^|[,[:space:]])specmill([[:space:],(]|$)", runtime))
  r <- file.path(R.home("bin"), "R")
  build_args <- c("CMD", "build", "--no-build-vignettes", "--no-manual", source)
  check_args <- c("CMD", "check", "--no-manual", "--no-vignettes", "--no-tests", "--no-examples")
  build <- processx::run(
    r,
    build_args,
    wd = path,
    env = c("current", env),
    error_on_status = FALSE,
    stdout = file.path(path, "build.log"),
    stderr_to_stdout = TRUE
  )
  result <- list(
    source = source,
    build_command = c(r, build_args),
    build_status = build$status,
    specmill_runtime_dependency = FALSE,
    build_log = readLines(file.path(path, "build.log"), warn = FALSE)
  )
  if (build$status != 0L) {
    return(result)
  }
  tarball <- file.path(path, paste0(desc[1, "Package"], "_", desc[1, "Version"], ".tar.gz"))
  stopifnot(file.exists(tarball))
  check <- processx::run(
    r,
    c(check_args, tarball),
    wd = path,
    env = c("current", env),
    error_on_status = FALSE,
    stdout = file.path(path, "check.log"),
    stderr_to_stdout = TRUE
  )
  log <- readLines(file.path(path, paste0(desc[1, "Package"], ".Rcheck"), "00check.log"), warn = FALSE)
  starts <- grep("^\\* checking", log)
  findings <- lapply(starts[grepl("(ERROR|WARNING|NOTE|INFO)$", log[starts])], function(start) {
    following <- which(seq_along(log) > start & grepl("^\\* ", log))
    end <- if (length(following)) following[[1]] - 1L else length(log)
    log[start:end]
  })
  c(
    result,
    list(
      check_command = c(r, check_args, tarball),
      check_status = check$status,
      status = grep("^Status:", log, value = TRUE),
      findings = findings,
      full_check_log = log
    )
  )
}
results <- list(
  environment = as.list(env),
  exclusions = "Examples, tests, vignette rebuilding and manual disabled. Focused tests and installed-client localhost comparisons run separately.",
  before = run_gate(baseline, "before"),
  after = run_gate(root, "after")
)
# Keep line numbers and findings intact; this is evidence, not a filtered pass report.
results$identical_findings <- identical(results$before$findings, results$after$findings)
jsonlite::write_json(
  results,
  file.path(root, "dev/specmill-pilot/check-results.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)
cat(
  "Before:",
  results$before$status,
  "\nAfter:",
  results$after$status,
  "\nIdentical findings:",
  results$identical_findings,
  "\n"
)
if (
  results$before$build_status != 0L ||
    results$after$build_status != 0L ||
    is.null(results$before$check_status) ||
    is.null(results$after$check_status) ||
    results$before$check_status != 0L ||
    results$after$check_status != 0L ||
    !results$identical_findings
) {
  quit(status = 1)
}
