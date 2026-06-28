# Render generated offline contract tests.

tg_quote_chr <- function(x) {
  tg_r_literal(as.character(x))
}

tg_assertion_for_helper_arg <- function(arg, call_values) {
  access <- sprintf("call[[%s]]", tg_quote_chr(arg$name))

  if (isTRUE(arg$literal)) {
    if (is.null(arg$literal_value)) {
      return(sprintf("  expect_null(%s)", access))
    }
    return(sprintf("  expect_equal(%s, %s)", access, tg_r_literal(arg$literal_value)))
  }

  if (!is.null(arg$symbol) && arg$symbol %in% names(call_values)) {
    return(sprintf("  expect_equal(%s, %s)", access, tg_r_literal(call_values[[arg$symbol]])))
  }

  if (arg$name %in% c("query", "body", "options", "chemicals", "params", "path_params")) {
    return(c(
      sprintf("  expect_true(%s %%in%% names(call))", tg_quote_chr(arg$name)),
      sprintf("  expect_true(is.null(%s) || length(%s) >= 0)", access, access)
    ))
  }

  NULL
}

tg_render_assertions <- function(metadata, call_values) {
  helper_args <- metadata$helper_args
  assertions <- c(
    sprintf("  expect_equal(call$.helper, %s)", tg_quote_chr(metadata$helper_name))
  )

  for (arg_name in names(helper_args)) {
    assertion <- tg_assertion_for_helper_arg(helper_args[[arg_name]], call_values)
    if (!is.null(assertion)) {
      assertions <- c(assertions, assertion)
    }
  }

  # Every generated contract should assert at least endpoint when the wrapper
  # passes one. This catches accidental endpoint-slug/file-name mismatches.
  if (!"endpoint" %in% names(helper_args)) {
    assertions <- c(assertions, "  expect_true(\"endpoint\" %in% names(call) || \"operation\" %in% names(call))")
  }

  unique(assertions)
}

tg_mock_bindings_for <- function(metadata) {
  bindings <- c(sprintf("%s = mock_helper", metadata$helper_name))
  if ("chemi_resolver_lookup" %in% metadata$resolver_helpers) {
    bindings <- c(bindings, "chemi_resolver_lookup = generated_contract_resolver_lookup")
  }
  if ("chemi_resolver_lookup_bulk" %in% metadata$resolver_helpers) {
    bindings <- c(bindings, "chemi_resolver_lookup_bulk = generated_contract_resolver_lookup_bulk")
  }
  bindings
}

tg_render_contract_test <- function(metadata) {
  call_args <- tg_build_wrapper_call_args(metadata)
  wrapper_call <- paste0(tg_config$package_name, "::", tg_render_wrapper_call(metadata$function_name, call_args))
  assertions <- tg_render_assertions(metadata, call_args$values)
  bindings <- paste(sprintf("    %s,", tg_mock_bindings_for(metadata)), collapse = "\n")

  lines <- c(
    sprintf("# Tests for %s", metadata$function_name),
    tg_config$generated_header,
    "# Generator: offline wrapper contract tests",
    "",
    sprintf("test_that(%s, {", tg_quote_chr(paste(metadata$function_name, "passes request metadata to helper"))),
    "  if (!exists(\"generated_contract_response\", mode = \"function\")) {",
    "    source(file.path(\"tests\", \"testthat\", \"helper-generated-contracts.R\"))",
    "  }",
    "  generated_contract_ensure_package()",
    "",
    "  calls <- list()",
    "  mock_helper <- function(...) {",
    "    captured <- list(...)",
    sprintf("    captured$.helper <- %s", tg_quote_chr(metadata$helper_name)),
    "    calls[[length(calls) + 1L]] <<- captured",
    "    generated_contract_response(...)",
    "  }",
    "",
    "  testthat::local_mocked_bindings(",
    bindings,
    sprintf("    .package = %s", tg_quote_chr(tg_config$package_name)),
    "  )",
    "",
    sprintf("  result <- try(suppressWarnings(suppressMessages(%s)), silent = TRUE)", wrapper_call),
    "  expect_gt(length(calls), 0L)",
    "  call <- calls[[1L]]",
    "  expect_true(is.list(call))",
    assertions,
    "})",
    ""
  )

  paste(lines, collapse = "\n")
}

tg_render_all_tests <- function(metadata) {
  lapply(metadata, function(item) {
    list(
      function_name = item$function_name,
      file = file.path(tg_config$test_dir, paste0("test-", item$function_name, ".R")),
      text = tg_render_contract_test(item),
      metadata = item
    )
  })
}
