#!/usr/bin/env Rscript
# ==============================================================================
# Hook Configuration Drift Detection (Phase 28)
# ==============================================================================
# CI validation script that ensures hook_config.yml references are valid:
#   1. All referenced hook functions exist in R/hooks_*.R
#   2. Declared parameters exist in each generated function's parsed formals
#   3. Hook function names resolve to actual R functions
#   4. Hook-driven request templates map to the configured generic helper
#
# Run in CI: Rscript dev/check_hook_config.R
# Fails build if any drift detected
# ==============================================================================

library(yaml)
library(cli)

# Read and merge manual and generated hook configs.
hook_config_path <- here::here("inst", "hook_config.yml")
generated_hook_config_path <- here::here("inst", "hook_config_generated.yml")

if (!file.exists(hook_config_path)) {
  cli::cli_abort("Hook config not found: {hook_config_path}")
}

source(here::here("R", "hook_registry.R"), local = FALSE)
hook_config <- read_hook_configs(hook_config_path, generated_hook_config_path)

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

collect_calls <- function(expression) {
  calls <- list()
  visit <- function(node) {
    if (!is.call(node)) {
      return(invisible(NULL))
    }
    calls[[length(calls) + 1L]] <<- node
    for (child in as.list(node)[-1L]) {
      visit(child)
    }
    invisible(NULL)
  }
  visit(expression)
  calls
}

call_name <- function(call) {
  if (!is.call(call) || !is.symbol(call[[1]])) {
    return(NA_character_)
  }
  as.character(call[[1]])
}

find_hook_call <- function(calls, fn_name, hook_type) {
  which(vapply(
    calls,
    function(call) {
      identical(call_name(call), "run_hook") &&
        length(call) >= 3L &&
        identical(call[[2]], fn_name) &&
        identical(call[[3]], hook_type)
    },
    logical(1)
  ))
}

find_generated_wrapper <- function(fn_name) {
  for (r_file in all_r_files) {
    expressions <- tryCatch(parse(r_file), error = function(error) expression())
    for (expression in expressions) {
      if (
        is.call(expression) &&
          identical(expression[[1]], as.name("<-")) &&
          identical(as.character(expression[[2]]), fn_name) &&
          is.call(expression[[3]]) &&
          identical(expression[[3]][[1]], as.name("function"))
      ) {
        definition <- expression[[3]]
        function_text <- paste(deparse(expression, width.cutoff = 500L), collapse = "\n")
        wrapper_fn <- eval(definition, envir = new.env(parent = baseenv()))
        body_text <- paste(deparse(body(wrapper_fn), width.cutoff = 500L), collapse = "\n")
        return(list(
          found = TRUE,
          file = r_file,
          text = function_text,
          body = body_text,
          formals = names(formals(wrapper_fn)),
          calls = collect_calls(body(wrapper_fn))
        ))
      }
    }
  }

  list(found = FALSE, file = NULL, text = "")
}

# Validate each function entry
for (fn_name in names(hook_config)) {
  fn_config <- hook_config[[fn_name]]
  wrapper <- find_generated_wrapper(fn_name)

  # Validate hook function references
  if (!is.null(fn_config$transform)) {
    errors <- c(
      errors,
      paste0("Function ", fn_name, " configures unsupported hook stage 'transform'")
    )
  }

  for (hook_type in c("pre_request", "post_response")) {
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
        if (length(find_hook_call(wrapper$calls, fn_name, hook_type)) == 0) {
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

        if (!param_name %in% wrapper$formals) {
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

  if (!is.null(fn_config$parameter_overrides) && isTRUE(wrapper$found)) {
    for (schema_name in names(fn_config$parameter_overrides)) {
      override <- fn_config$parameter_overrides[[schema_name]]
      public_name <- if (is.null(override$name)) make.names(schema_name) else override$name
      if (isTRUE(override$exclude)) {
        if (public_name %in% wrapper$formals) {
          errors <- c(
            errors,
            paste0(
              "Function ",
              fn_name,
              " excludes parameter '",
              public_name,
              "' but it remains in parsed formals"
            )
          )
        }
      } else if (!public_name %in% wrapper$formals) {
        errors <- c(
          errors,
          paste0(
            "Function ",
            fn_name,
            " maps parameter '",
            schema_name,
            "' to missing formal '",
            public_name,
            "'"
          )
        )
      }
    }
  }

  if (!is.null(fn_config$request_template)) {
    template <- fn_config$request_template
    helper <- template$helper
    if (!isTRUE(wrapper$found)) {
      next
    }
    helper_positions <- which(vapply(
      wrapper$calls,
      function(call) identical(call_name(call), helper),
      logical(1)
    ))
    pre_positions <- find_hook_call(wrapper$calls, fn_name, "pre_request")
    post_positions <- find_hook_call(wrapper$calls, fn_name, "post_response")
    if (length(helper_positions) == 0) {
      errors <- c(
        errors,
        paste0("Function ", fn_name, " does not call configured helper ", helper)
      )
    }
    if (
      length(pre_positions) == 0 ||
        length(post_positions) == 0 ||
        length(helper_positions) == 0 ||
        !(pre_positions[[1]] < helper_positions[[1]] &&
          helper_positions[[1]] < post_positions[[1]])
    ) {
      errors <- c(
        errors,
        paste0(
          "Function ",
          fn_name,
          " does not emit pre-request -> helper -> post-response order"
        )
      )
    }

    if (
      !is.list(template$args) ||
        length(template$args) == 0 ||
        is.null(names(template$args)) ||
        any(!nzchar(names(template$args)))
    ) {
      errors <- c(
        errors,
        paste0("Function ", fn_name, " has an invalid request-template argument mapping")
      )
    } else {
      helper_call <- if (length(helper_positions) > 0) {
        wrapper$calls[[helper_positions[[1]]]]
      } else {
        NULL
      }
      helper_args <- if (is.null(helper_call)) {
        list()
      } else {
        as.list(helper_call)[-1L]
      }
      for (argument_name in names(template$args)) {
        expression <- as.character(template$args[[argument_name]])
        parsed <- tryCatch(parse(text = expression), error = function(error) NULL)
        if (is.null(parsed)) {
          errors <- c(
            errors,
            paste0(
              "Function ",
              fn_name,
              " has invalid request expression for '",
              argument_name,
              "'"
            )
          )
        } else if (
          is.null(names(helper_args)) ||
            !argument_name %in% names(helper_args) ||
            !identical(helper_args[[argument_name]], parsed[[1]])
        ) {
          errors <- c(
            errors,
            paste0(
              "Function ",
              fn_name,
              " request argument '",
              argument_name,
              "' does not match configured expression ",
              expression
            )
          )
        }
      }
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
