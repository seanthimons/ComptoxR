local_stage_hook_config <- function(config) {
  old <- .HookRegistry$config
  withr::defer(.HookRegistry$config <- old, envir = parent.frame())
  .HookRegistry$config <- config
}

test_that("stage routing preserves supported production, staging, and development servers", {
  local_stage_hook_config(list(
    example = list(
      supported_schema_stages = c("public", "staging", "development"),
      preferred_fallback_stage = "public"
    )
  ))

  for (server in c("chemi_burl", chemi_server(2, TRUE), chemi_server(3, TRUE))) {
    data <- list(fn_name = "example", params = list(server = server))
    expect_identical(enforce_stage_server(data)$params$server, server)
  }
})

test_that("stage routing falls back by public staging development priority", {
  local_stage_hook_config(list(
    public_only = list(
      supported_schema_stages = "public",
      preferred_fallback_stage = "public"
    ),
    preview = list(
      supported_schema_stages = c("staging", "development"),
      preferred_fallback_stage = "staging"
    )
  ))

  expect_warning(
    public <- enforce_stage_server(list(
      fn_name = "public_only",
      params = list(server = chemi_server(3, TRUE))
    )),
    "using public"
  )
  expect_identical(public$params$server, chemi_server(1, TRUE))

  expect_warning(
    preview <- enforce_stage_server(list(
      fn_name = "preview",
      params = list(server = "chemi_burl")
    )),
    "using staging"
  )
  expect_identical(preview$params$server, chemi_server(2, TRUE))
})

test_that("stage routing preserves custom URLs and updates request templates", {
  local_stage_hook_config(list(
    example = list(
      supported_schema_stages = "staging",
      preferred_fallback_stage = "staging"
    )
  ))

  custom <- list(fn_name = "example", params = list(server = "https://custom.example/api"))
  expect_identical(enforce_stage_server(custom), custom)

  template <- list(
    fn_name = "example",
    params = list(server = "chemi_burl"),
    request = list(server = "chemi_burl", endpoint = "demo")
  )
  expect_warning(routed <- enforce_stage_server(template), "using staging")
  expect_identical(routed$params$server, chemi_server(2, TRUE))
  expect_identical(routed$request$server, chemi_server(2, TRUE))
})

test_that("generated stage hooks run after manual pre-request hooks", {
  merged <- merge_hook_configs(
    list(example = list(pre_request = c("first_hook", "second_hook"))),
    list(
      example = list(
        supported_schema_stages = "public",
        preferred_fallback_stage = "public",
        pre_request = "enforce_stage_server"
      )
    )
  )

  expect_identical(
    merged$example$pre_request,
    c("first_hook", "second_hook", "enforce_stage_server")
  )
})
