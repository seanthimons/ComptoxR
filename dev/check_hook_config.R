#!/usr/bin/env Rscript
# ==============================================================================
# Hook Configuration Drift Detection (Phase 28)
# ==============================================================================
# CI validation script that ensures hook_config.yml references are valid:
#   1. All referenced hook functions exist in R/hooks_*.R
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
hook_files <- list.files(here::here("R"), pattern = "^hooks_.*\\.R$", full.names = TRUE)
for (hook_file in hook_files) {
  source(hook_file, local = FALSE)
}

# Collect errors
errors <- character()
hook_count <- 0
param_count <- 0
all_r_files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)

find_generated_wrapper <- function(fn_name) {
  for (r_file in all_r_files) {
    stub_content <- readLines(r_file, warn = FALSE)
    fn_def_pattern <- paste0("^", fn_name, "\\s*<-\\s*function\\(")
    if (any(grepl(fn_def_pattern, stub_content))) {
      return(list(
        found = TRUE,
        file = r_file,
        text = paste(stub_content, collapse = "\n")
      ))
    }
  }

  list(found = FALSE, file = NULL, text = "")
}

# Validate each function entry
for (fn_name in names(hook_config)) {
  fn_config <- hook_config[[fn_name]]
  wrapper <- find_generated_wrapper(fn_name)

  # Validate hook function references
  for (hook_type in c("pre_request", "post_response", "transform")) {
    if (!is.null(fn_config[[hook_type]])) {
      hook_names <- fn_config[[hook_type]]

      for (hook_fn in hook_names) {
        hook_count <- hook_count + 1

        # Check if hook function exists
        if (!exists(hook_fn, mode = "function")) {
          errors <- c(
            errors,
            paste0(
              "Function ",
              fn_name,
              " references missing hook: ",
              hook_fn,
              " (type: ",
              hook_type,
              ")"
            )
          )
        }
      }

      if (isTRUE(wrapper$found)) {
        transform_configured <- !is.null(fn_config$transform) &&
          length(fn_config$transform) > 0
        stage_pattern <- paste0(
          "run_hook\\(\\s*['\"]",
          fn_name,
          "['\"]\\s*,\\s*['\"]",
          hook_type,
          "['\"]"
        )
        stage_is_deep <- hook_type %in% c("pre_request", "post_response") && isTRUE(transform_configured)
        if (!stage_is_deep && !grepl(stage_pattern, wrapper$text, perl = TRUE)) {
          errors <- c(
            errors,
            paste0(
              "Function ",
              fn_name,
              " configures hook stage '",
              hook_type,
              "' but generated wrapper does not emit that stage (file: ",
              basename(wrapper$file),
              ")"
            )
          )
        }
      } else {
        cli::cli_alert_info("Generated stub for {fn_name} not found (okay if not yet generated)")
      }
    }
  }

  # Validate extra_params exist in generated stubs
  if (!is.null(fn_config$extra_params)) {
    if (isTRUE(wrapper$found)) {
      for (param_name in names(fn_config$extra_params)) {
        param_count <- param_count + 1

        # Check if parameter appears in function signature
        param_spec <- fn_config$extra_params[[param_name]]
        param_pattern <- if (isTRUE(param_spec$required)) {
          paste0("\\b", param_name, "\\b")
        } else {
          paste0("\\b", param_name, "\\s*=")
        }
        if (!grepl(param_pattern, wrapper$text)) {
          errors <- c(
            errors,
            paste0(
              "Function ",
              fn_name,
              " declares extra_param '",
              param_name,
              "' but it's not in generated stub signature (file: ",
              basename(wrapper$file),
              ")"
            )
          )
        }
      }
    } else {
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
