#!/usr/bin/env Rscript
# ==============================================================================
# Hook Configuration Drift Detection (Phase 28)
# ==============================================================================
# CI validation script that ensures hook_config.yml references are valid:
#   1. All referenced hook functions exist in R/hooks/*.R
#   2. Declared extra_params exist in generated stub signatures
#   3. Hook function names resolve to actual R functions
#
# Run in CI: Rscript dev/check_hook_config.R
# Fails build if any drift detected
# ==============================================================================

library(yaml)
library(cli)

# Read hook config
hook_config_path <- here::here("inst", "hook_config.yml")

if (!file.exists(hook_config_path)) {
  cli::cli_abort("Hook config not found: {hook_config_path}")
}

hook_config <- yaml::read_yaml(hook_config_path)

# Source all hook files to make functions available
hook_files <- list.files(here::here("R", "hooks"), pattern = "\\.R$", full.names = TRUE)
for (hook_file in hook_files) {
  source(hook_file, local = FALSE)
}

# Collect errors
errors <- character()
hook_count <- 0
param_count <- 0

# Validate each function entry
for (fn_name in names(hook_config)) {
  fn_config <- hook_config[[fn_name]]

  # Validate hook function references
  for (hook_type in c("pre_request", "post_response", "transform")) {
    if (!is.null(fn_config[[hook_type]])) {
      hook_names <- fn_config[[hook_type]]

      for (hook_fn in hook_names) {
        hook_count <- hook_count + 1

        # Check if hook function exists
        if (!exists(hook_fn, mode = "function")) {
          errors <- c(errors, paste0(
            "Function ", fn_name, " references missing hook: ", hook_fn,
            " (type: ", hook_type, ")"
          ))
        }
      }
    }
  }

  # Validate extra_params exist in generated stubs
  if (!is.null(fn_config$extra_params)) {
    # Search for function definition in all R files (some stubs are multi-function)
    all_r_files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
    fn_found <- FALSE
    fn_file <- NULL

    for (r_file in all_r_files) {
      stub_content <- readLines(r_file, warn = FALSE)
      stub_text <- paste(stub_content, collapse = "\n")

      # Look for function definition: fn_name <- function(
      fn_def_pattern <- paste0("^", fn_name, "\\s*<-\\s*function\\(")
      if (any(grepl(fn_def_pattern, stub_content))) {
        fn_found <- TRUE
        fn_file <- r_file

        # Check each extra param
        for (param_name in names(fn_config$extra_params)) {
          param_count <- param_count + 1

          # Check if parameter appears in function signature
          # Pattern: param_name = <default_value>
          param_pattern <- paste0("\\b", param_name, "\\s*=")
          if (!grepl(param_pattern, stub_text)) {
            errors <- c(errors, paste0(
              "Function ", fn_name, " declares extra_param '", param_name,
              "' but it's not in generated stub signature (file: ", basename(fn_file), ")"
            ))
          }
        }
        break
      }
    }

    if (!fn_found) {
      # Stub doesn't exist yet - not an error (might be generated later)
      cli::cli_alert_info("Generated stub for {fn_name} not found (okay if not yet generated)")
    }
  }
}

# Report results
if (length(errors) > 0) {
  cli::cli_alert_danger("Hook config validation FAILED:")
  for (err in errors) {
    cli::cli_bullets(c("x" = err))
  }
  cli::cli_abort("Hook config drift detected: {length(errors)} error(s)")
} else {
  cli::cli_alert_success(
    "Hook config validation passed: {length(hook_config)} function(s), {hook_count} hook(s), {param_count} extra param(s)"
  )
}
