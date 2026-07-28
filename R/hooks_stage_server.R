# Non-production server-swap hook
#
# Generated wrappers for endpoints that only exist on a non-production API schema
# (staging / development) default to the production base URL and therefore fail.
# This pre_request hook redirects such calls to the server where the endpoint
# actually lives, based on the per-function `endpoint_stage` field in
# inst/hook_config.yml (written when the stub is generated from a non-public
# schema). It warns on redirect, mirroring descriptor_apply_fallback().
#
# Scope: attached ONLY to non-descriptor functions. Descriptor wrappers
# (chemi_mordred/rdkit/padel/webtest/descriptors) manage their own server via
# `params$.route` and must not receive this hook.

enforce_stage_server <- function(data) {
  cfg <- .HookRegistry$config[[data$fn_name]]
  stage <- cfg$endpoint_stage
  if (is.null(stage) || identical(stage, "public")) {
    return(data)
  }

  target <- switch(
    stage,
    staging = chemi_server(2, url_only = TRUE),
    development = chemi_server(3, url_only = TRUE),
    NULL
  )
  if (is.null(target) || !nzchar(target)) {
    # Unknown stage or unconfigured server: leave the request untouched.
    return(data)
  }

  data$params$server <- target
  cli::cli_warn(c(
    "{.fn {data$fn_name}} targets a {stage}-only endpoint; using its {stage} server.",
    "i" = "Server: {.url {target}}"
  ))
  data
}
