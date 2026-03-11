# Hook Registry System
# Provides infrastructure for declarative hook-based function customization

.HookRegistry <- new.env(parent = emptyenv())

#' Load Hook Configuration from YAML
#'
#' Loads hook configuration from inst/hook_config.yml and populates the
#' .HookRegistry environment. Called automatically by .onLoad().
#'
#' @return Invisible NULL
#' @noRd
load_hook_config <- function() {
  config_path <- system.file("hook_config.yml", package = "ComptoxR")

  if (file.exists(config_path)) {
    .HookRegistry$config <- yaml::read_yaml(config_path)
  } else {
    .HookRegistry$config <- list()
  }

  invisible(NULL)
}

#' Run Hook Chain for Function
#'
#' Executes registered hooks for a given function and hook type.
#' Returns data unchanged if no hooks are registered.
#'
#' @param fn_name Character string naming the function
#' @param hook_type Character string: "pre_request", "post_response", or "transform"
#' @param data Data to pass through hook chain
#'
#' @return Transformed data after all hooks execute, or original data if no hooks registered
#' @noRd
run_hook <- function(fn_name, hook_type, data) {
  # Look up hook chain for this function and type
  hook_chain <- .HookRegistry$config[[fn_name]][[hook_type]]

  # If no hooks registered, return data unchanged
  if (is.null(hook_chain)) {
    return(data)
  }

  # Execute each hook in chain order
  result <- data
  for (hook_name in hook_chain) {
    hook_fn <- match.fun(hook_name)
    result <- hook_fn(result)
  }

  result
}
