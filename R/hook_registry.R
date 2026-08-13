# Hook Registry System
# Provides infrastructure for declarative hook-based function customization

.HookRegistry <- new.env(parent = emptyenv())

merge_hook_configs <- function(manual, generated) {
  result <- if (is.null(manual)) list() else manual
  generated <- if (is.null(generated)) list() else generated

  for (fn_name in names(generated)) {
    manual_entry <- if (is.null(result[[fn_name]])) list() else result[[fn_name]]
    generated_entry <- if (is.null(generated[[fn_name]])) list() else generated[[fn_name]]
    merged_entry <- utils::modifyList(manual_entry, generated_entry)
    merged_entry$pre_request <- unique(c(
      if (is.null(manual_entry$pre_request)) character() else manual_entry$pre_request,
      if (is.null(generated_entry$pre_request)) character() else generated_entry$pre_request
    ))
    result[[fn_name]] <- merged_entry
  }

  result
}

read_hook_configs <- function(manual_path, generated_path) {
  read_one <- function(path) {
    value <- if (file.exists(path)) yaml::read_yaml(path) else list()
    if (is.null(value)) list() else value
  }
  merge_hook_configs(read_one(manual_path), read_one(generated_path))
}

#' Load Hook Configuration from YAML
#'
#' Loads hook configuration from inst/hook_config.yml and populates the
#' .HookRegistry environment. Called automatically by .onLoad().
#'
#' @return Invisible NULL
#' @noRd
load_hook_config <- function() {
  .HookRegistry$config <- read_hook_configs(
    system.file("hook_config.yml", package = "ComptoxR"),
    system.file("hook_config_generated.yml", package = "ComptoxR")
  )

  invisible(NULL)
}

#' Run Hook Chain for Function
#'
#' Executes registered hooks for a given function and hook type.
#' Returns data unchanged if no hooks are registered.
#'
#' @param fn_name Character string naming the function
#' @param hook_type Character string: "pre_request" or "post_response"
#' @param data Data to pass through hook chain
#'
#' @return Transformed data after all hooks execute, or original data if no hooks registered
#' @noRd
run_hook <- function(fn_name, hook_type, data) {
  if (!hook_type %in% c("pre_request", "post_response")) {
    cli::cli_abort("Unsupported hook stage {.val {hook_type}}.")
  }

  # Look up hook chain for this function and type
  hook_chain <- .HookRegistry$config[[fn_name]][[hook_type]]

  # If no hooks registered, return data unchanged
  if (is.null(hook_chain) || length(hook_chain) == 0) {
    return(data)
  }

  if (is.list(data)) {
    data$fn_name <- fn_name
    data$hook_type <- hook_type
  }

  # Execute each hook in chain order
  # Look up in package namespace first (hook functions are internal/not exported),

  # then fall back to parent environments for testability
  ns <- asNamespace("ComptoxR")
  result <- data
  for (hook_name in hook_chain) {
    if (is.list(result)) {
      result$fn_name <- fn_name
      result$hook_type <- hook_type
    }
    if (exists(hook_name, envir = ns, mode = "function")) {
      hook_fn <- get(hook_name, envir = ns, mode = "function")
    } else {
      hook_fn <- match.fun(hook_name)
    }
    result <- tryCatch(
      hook_fn(result),
      error = function(parent) {
        error_class <- paste0("comptoxr_", hook_type, "_hook_error")
        if (inherits(parent, error_class)) {
          stop(parent)
        }
        cli::cli_abort(
          "{.fn {fn_name}} failed in {gsub('_', '-', hook_type, fixed = TRUE)} hook {.fn {hook_name}}.",
          class = error_class,
          parent = parent,
          function_name = fn_name,
          hook_name = hook_name,
          stage = hook_type
        )
      }
    )
  }

  result
}
