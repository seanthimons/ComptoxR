#!/usr/bin/env Rscript
# Parent entrypoint for generated offline wrapper contract tests.

suppressPackageStartupMessages({
  if (requireNamespace("cli", quietly = TRUE)) {
    library(cli)
  }
})

source_test_generation_pipeline <- function(root = ".") {
  module_dir <- file.path(root, "dev", "test_generation")
  modules <- c(
    "00_config.R",
    "01_inventory.R",
    "02_wrapper_metadata.R",
    "03_test_values.R",
    "04_renderer.R",
    "05_scaffold.R",
    "06_static_validation.R",
    "07_token_preflight.R"
  )

  for (module in modules) {
    path <- file.path(module_dir, module)
    if (!file.exists(path)) {
      stop("Missing test generation module: ", path, call. = FALSE)
    }
    source(path, local = FALSE)
  }

  invisible(TRUE)
}

parse_generate_tests_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  mode_flags <- intersect(args, c("--generate", "--check", "--dry-run"))
  if (length(mode_flags) > 1) {
    stop("Choose only one mode: --generate, --check, or --dry-run", call. = FALSE)
  }

  list(
    mode = if (length(mode_flags) == 0) "generate" else sub("^--", "", mode_flags[[1]]),
    force = "--force" %in% args,
    help = any(args %in% c("--help", "-h"))
  )
}

print_generate_tests_help <- function() {
  cat(
    "Usage:\n",
    "  Rscript dev/generate_tests.R --generate\n",
    "  Rscript dev/generate_tests.R --check\n",
    "  Rscript dev/generate_tests.R --dry-run\n",
    "  Rscript dev/generate_tests.R --generate --force\n",
    "\n",
    "Generated tests are offline mocked contract tests. Hand-written tests are not overwritten.\n",
    sep = ""
  )
}

build_generated_test_specs <- function(root = ".") {
  metadata <- tg_collect_wrapper_metadata(root)
  tg_render_all_tests(metadata)
}

summarise_scaffold <- function(scaffold) {
  actions <- vapply(scaffold$writes, `[[`, character(1), "action")
  list(
    tests_generated = sum(actions %in% c("created", "updated")),
    tests_created = sum(actions == "created"),
    tests_updated = sum(actions == "updated"),
    tests_skipped = sum(actions == "skipped_manual"),
    tests_unchanged = sum(actions == "unchanged"),
    tests_removed = length(scaffold$removed)
  )
}

generate_tests_main <- function(args = commandArgs(trailingOnly = TRUE), root = ".") {
  parsed <- parse_generate_tests_args(args)
  if (parsed$help) {
    print_generate_tests_help()
    return(invisible(NULL))
  }

  source_test_generation_pipeline(root)
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::cli_h1("Generated Wrapper Contract Tests")
  }

  specs <- build_generated_test_specs(root)
  tg_cli_info(sprintf("Discovered %d exported API wrapper function(s)", length(specs)))

  if (identical(parsed$mode, "dry-run")) {
    scaffold <- tg_scaffold_generated_tests(specs, root = root, dry_run = TRUE, force = parsed$force)
    summary <- summarise_scaffold(scaffold)
    tg_cli_info("Dry run only. No files were changed.")
    tg_cli_info(sprintf("Would generate/update: %d", summary$tests_generated))
    tg_cli_info(sprintf("Would skip manual tests: %d", summary$tests_skipped))
    tg_cli_info(sprintf("Would remove generated files: %d", summary$tests_removed))
    tg_write_github_outputs(c(
      tests_generated = summary$tests_generated,
      tests_skipped = summary$tests_skipped,
      tests_removed = summary$tests_removed,
      check_status = "dry_run",
      gaps_remaining = 0
    ))
    return(invisible(list(specs = specs, scaffold = scaffold, summary = summary)))
  }

  if (identical(parsed$mode, "check")) {
    check <- tg_check_generated_tests_current(specs, root = root)
    status <- if (isTRUE(check$current)) "pass" else "fail"
    tg_write_github_outputs(c(
      tests_generated = 0,
      tests_skipped = 0,
      tests_removed = 0,
      check_status = status,
      gaps_remaining = 0
    ))

    if (!isTRUE(check$current)) {
      if (length(check$mismatches) > 0) {
        tg_cli_warning(sprintf("Generated tests are missing or out of date: %d", length(check$mismatches)))
        for (item in head(check$mismatches, 20)) {
          tg_cli_warning(sprintf("%s: %s", item$file, item$reason))
        }
      }
      if (!isTRUE(check$static$valid)) {
        tg_cli_warning("Static validation failed for generated tests")
        for (failure in check$static$failures) {
          tg_cli_warning(sprintf("%s: %s", failure$file, paste(failure$errors, collapse = "; ")))
        }
      }
      quit(save = "no", status = 1)
    }

    tg_cli_success("Generated tests are current and passed static validation")
    return(invisible(check))
  }

  scaffold <- tg_scaffold_generated_tests(specs, root = root, dry_run = FALSE, force = parsed$force)
  summary <- summarise_scaffold(scaffold)
  check <- tg_check_generated_tests_current(specs, root = root)
  status <- if (isTRUE(check$current)) "pass" else "fail"

  tg_cli_success(sprintf("Generated or updated %d test file(s)", summary$tests_generated))
  tg_cli_info(sprintf("Skipped %d hand-written test file(s)", summary$tests_skipped))
  tg_cli_info(sprintf("Removed %d retired generated test file(s)", summary$tests_removed))

  tg_write_github_outputs(c(
    tests_generated = summary$tests_generated,
    tests_created = summary$tests_created,
    tests_updated = summary$tests_updated,
    tests_skipped = summary$tests_skipped,
    tests_removed = summary$tests_removed,
    check_status = status,
    gaps_remaining = 0
  ))

  if (!isTRUE(check$current)) {
    tg_cli_abort(c(
      "x" = "Generated-test static validation failed after generation",
      "i" = "Run Rscript dev/generate_tests.R --check for details."
    ))
  }

  invisible(list(specs = specs, scaffold = scaffold, summary = summary, check = check))
}

generate_tests_is_entrypoint <- function() {
  file_args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(file_args) == 0) {
    return(FALSE)
  }

  identical(basename(sub("^--file=", "", file_args[[length(file_args)]])), "generate_tests.R")
}

if (generate_tests_is_entrypoint()) {
  generate_tests_main()
}
