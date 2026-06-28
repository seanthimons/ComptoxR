source(here::here("dev", "generate_tests.R"))
source_test_generation_pipeline(here::here())

make_generation_repo <- function() {
  root <- tempfile("test-generation-")
  dir.create(file.path(root, "R"), recursive = TRUE)
  dir.create(file.path(root, "tests", "testthat"), recursive = TRUE)
  writeLines(c(
    "export(alpha)",
    "export(beta)",
    "export(gamma)",
    "export(\"%>%\")"
  ), file.path(root, "NAMESPACE"), useBytes = TRUE)
  writeLines(c(
    "alpha <- function(query, projection = \"all\") {",
    "  generic_request(",
    "    query = query,",
    "    endpoint = \"chemical/detail\",",
    "    method = \"GET\",",
    "    batch_limit = 1,",
    "    projection = projection",
    "  )",
    "}",
    "",
    "beta <- function() {",
    "  generic_request(",
    "    endpoint = \"chemical/list/type\",",
    "    method = \"GET\",",
    "    batch_limit = 0",
    "  )",
    "}",
    "",
    "gamma <- function() TRUE"
  ), file.path(root, "R", "wrappers.R"), useBytes = TRUE)
  root
}

test_that("generator inventories exported wrappers, not endpoint slugs", {
  root <- make_generation_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  wrappers <- tg_inventory_wrappers(root)

  expect_equal(names(wrappers), c("alpha", "beta"))
  expect_equal(wrappers$alpha$file, "R/wrappers.R")
  expect_false("chemical-detail" %in% names(wrappers))
  expect_false("gamma" %in% names(wrappers))
})

test_that("generator selects required arguments and handles no-parameter wrappers", {
  root <- make_generation_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  metadata <- tg_collect_wrapper_metadata(root)
  alpha_args <- tg_build_wrapper_call_args(metadata$alpha)
  beta_args <- tg_build_wrapper_call_args(metadata$beta)

  expect_equal(names(alpha_args$args), "query")
  expect_equal(alpha_args$args$query, "\"DTXSID7020182\"")
  expect_equal(tg_render_wrapper_call("alpha", alpha_args), "alpha(query = \"DTXSID7020182\")")
  expect_equal(tg_render_wrapper_call("beta", beta_args), "beta()")
})

test_that("renderer emits offline mocked contract tests", {
  root <- make_generation_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  metadata <- tg_collect_wrapper_metadata(root)
  text <- tg_render_contract_test(metadata$alpha)

  expect_match(text, "local_mocked_bindings")
  expect_match(text, "generated_contract_ensure_package()", fixed = TRUE)
  expect_match(text, "generic_request = mock_helper", fixed = TRUE)
  expect_match(text, ".package = \"ComptoxR\"", fixed = TRUE)
  expect_match(text, "alpha\\(query = \"DTXSID7020182\"\\)")
  expect_match(text, "expect_equal\\(call\\[\\[\"endpoint\"\\]\\], \"chemical/detail\"\\)")
  cassette_call <- paste0("use_", "cassette")
  expect_false(grepl(cassette_call, text, fixed = TRUE))
  expect_false(grepl("`chemical-detail`", text, fixed = TRUE))
})

test_that("static validation rejects retired generated-test patterns", {
  root <- make_generation_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  metadata <- tg_collect_wrapper_metadata(root)
  valid_text <- tg_render_contract_test(metadata$beta)
  cassette_call <- paste0("use_", "cassette")
  invalid_text <- paste(
    "# Generated using metadata-based test generator",
    "test_that('old generated shape works without parameters', {",
    sprintf("  vcr::%s('bad', { `ct_chemical_by-dtxcid`() })", cassette_call),
    "})",
    sep = "\n"
  )

  expect_true(tg_validate_generated_text(valid_text)$valid)
  invalid <- tg_validate_generated_text(invalid_text)
  expect_false(invalid$valid)
  expect_true(any(grepl("VCR cassette", invalid$errors)))
  expect_true(any(grepl("backticked", invalid$errors)))
})

test_that("generated-test check tolerates terminal newline differences", {
  root <- make_generation_repo()
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  metadata <- tg_collect_wrapper_metadata(root)
  specs <- tg_render_all_tests(metadata)
  alpha_idx <- which(vapply(specs, function(spec) identical(spec$function_name, "alpha"), logical(1)))
  alpha <- specs[[alpha_idx]]
  path <- file.path(root, alpha$file)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(tg_without_terminal_newline(alpha$text), path, useBytes = TRUE)

  check <- tg_check_generated_tests_current(list(alpha), root = root)

  expect_true(check$current)
  expect_length(check$mismatches, 0)
})

test_that("token preflight rejects empty placeholder and redacted-looking values", {
  expect_false(ctx_api_key_status("")$valid)
  expect_false(ctx_api_key_status("dummy_ctx_key")$valid)
  expect_false(ctx_api_key_status("<<<API_KEY>>>")$valid)
  expect_false(ctx_api_key_status("xxxxxxxx")$valid)
  expect_true(ctx_api_key_status("realistic-token-value-123")$valid)
})
