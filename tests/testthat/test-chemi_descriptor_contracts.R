descriptor_public_signatures <- list(
  chemi_descriptors = c("smiles", "type", "headers", "format", "timeout", "output"),
  chemi_descriptors_bulk = c(
    "query",
    "type",
    "chemIdType",
    "headers",
    "format",
    "timeout",
    "output"
  ),
  chemi_padel = c("smiles", "x2d", "x3d", "fp", "headers", "timeout", "output"),
  chemi_padel_bulk = c("query", "x2d", "x3d", "fp", "headers", "timeout", "output"),
  chemi_rdkit = c("smiles", "type", "radius", "bits", "output"),
  chemi_rdkit_bulk = c("chemicals", "options", "type", "radius", "bits", "output"),
  chemi_mordred = c("smiles", "headers", "inchi", "output"),
  chemi_mordred_bulk = c("chemicals", "options", "headers", "inchi", "output"),
  chemi_webtest = c("smiles", "headers", "output"),
  chemi_webtest_bulk = c("query", "chemIdType", "headers", "format", "output")
)

test_that("descriptor wrappers retain their public signatures", {
  for (fn_name in names(descriptor_public_signatures)) {
    fn <- get(fn_name, envir = asNamespace("ComptoxR"))
    expect_identical(
      names(formals(fn)),
      descriptor_public_signatures[[fn_name]],
      info = fn_name
    )
  }

  expect_identical(formals(chemi_descriptors_bulk)$chemIdType, "AnyId")
  expect_identical(formals(chemi_descriptors_bulk)$format, "JSON")
  expect_identical(formals(chemi_webtest_bulk)$chemIdType, "AnyId")
  expect_identical(formals(chemi_webtest_bulk)$format, "JSON")
})

test_that("scalar descriptor wrappers call generic_request with prepared GET state", {
  withr::local_envvar(chemi_burl = "https://cim.sciencedataexperts.com/api")
  calls <- list()
  local_mocked_bindings(
    generic_request = function(...) {
      call <- list(...)
      calls[[length(calls) + 1L]] <<- call
      descriptors <- if (identical(call$endpoint, "rdkit")) 1:4 else c(1, 2)
      descriptor_contract_response(
        records = list(descriptor_contract_record(descriptors = descriptors)),
        headers = if (identical(call$endpoint, "rdkit")) character() else c("a", "b")
      )
    },
    .package = "ComptoxR"
  )

  aggregate <- chemi_descriptors("CCO", type = "padel")
  padel <- chemi_padel("CCO", x2d = TRUE, x3d = TRUE, fp = TRUE)
  rdkit <- chemi_rdkit("CCO", type = "ecfp", radius = 2, bits = 4)
  mordred <- chemi_mordred("CCO", headers = FALSE, inchi = TRUE)
  webtest <- chemi_webtest("CCO")

  expect_identical(
    vapply(calls, `[[`, character(1), "endpoint"),
    c("descriptors", "padel", "rdkit", "mordred", "webtest")
  )
  expect_true(all(vapply(calls, `[[`, character(1), "method") == "GET"))
  expect_true(all(vapply(calls, `[[`, numeric(1), "batch_limit") == 0))
  expect_identical(calls[[1]]$options$type, "padel")
  expect_true(calls[[1]]$options$headers)
  expect_true(calls[[2]]$options$`2d`)
  expect_true(calls[[2]]$options$`3d`)
  expect_true(calls[[2]]$options$fp)
  expect_identical(calls[[3]]$options$bits, 4L)
  expect_true(calls[[4]]$options$headers)
  expect_true(all(vapply(list(aggregate, padel, rdkit, mordred, webtest), nrow, integer(1)) == 1L))
})

test_that("bulk descriptor wrappers call generic_chemi_request with exact bodies", {
  withr::local_envvar(chemi_burl = "https://cim.sciencedataexperts.com/api")
  calls <- list()
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      call <- list(...)
      calls[[length(calls) + 1L]] <<- call
      records <- lapply(seq_along(call$body$chemicals), function(index) {
        descriptor_contract_record(
          smiles = as.character(call$body$chemicals[[index]]),
          descriptors = if (identical(call$endpoint, "rdkit")) 1:8 else c(1, 2),
          ordinal = if (identical(call$endpoint, "descriptors")) index - 1L else NULL
        )
      })
      descriptor_contract_response(
        records = records,
        headers = if (identical(call$endpoint, "rdkit")) character() else c("a", "b")
      )
    },
    .package = "ComptoxR"
  )

  chemi_descriptors_bulk(c("CCO", "CCC"), type = "padel")
  chemi_padel_bulk(c("CCO", "CCC"), x2d = FALSE, x3d = TRUE, fp = TRUE)
  chemi_rdkit_bulk(
    c("CCO", "CCC"),
    options = list(bits = 16L, radius = 7L, custom = "kept"),
    radius = 2L,
    bits = 8L
  )
  chemi_mordred_bulk(
    c("CCO", "CCC"),
    options = list(headers = FALSE, inchi = FALSE, custom = "kept"),
    headers = TRUE
  )
  chemi_webtest_bulk(c("CCO", "CCC"), chemIdType = "SMILES")

  expect_identical(
    vapply(calls, `[[`, character(1), "endpoint"),
    c("descriptors", "padel", "rdkit", "mordred", "webtest")
  )
  expect_true(all(vapply(calls, function(call) is.null(call$query), logical(1))))
  expect_identical(as.character(calls[[1]]$body$chemicals), c("CCO", "CCC"))
  expect_identical(calls[[1]]$body$type, "padel")
  expect_identical(calls[[1]]$body$chemIdType, "AnyId")
  expect_false(calls[[2]]$body$options$compute2D)
  expect_true(calls[[2]]$body$options$compute3D)
  expect_true(calls[[2]]$body$options$computeFingerprints)
  expect_identical(calls[[3]]$body$options$radius, 2L)
  expect_identical(calls[[3]]$body$options$bits, 8L)
  expect_identical(calls[[3]]$body$options$custom, "kept")
  expect_true(calls[[4]]$body$options$headers)
  expect_false(calls[[4]]$body$options$inchi)
  expect_identical(calls[[4]]$body$options$custom, "kept")
  expect_identical(calls[[5]]$body$chemIdType, "SMILES")
  expect_identical(calls[[5]]$body$format, "JSON")
})

test_that("bulk wide output preserves duplicates, invalid inputs, and ordinals", {
  captured <- NULL
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured <<- list(...)
      descriptor_contract_response(
        records = list(
          descriptor_contract_record("CCO", c(1, 2), ordinal = 0L),
          descriptor_contract_record("invalid[", numeric(), ordinal = 1L),
          descriptor_contract_record("CCO", c(1, 2), ordinal = 2L)
        ),
        headers = c("first", "second")
      )
    },
    .package = "ComptoxR"
  )

  result <- chemi_descriptors_bulk(
    c("CCO", "invalid[", "CCO", NA_character_),
    type = "padel",
    chemIdType = "SMILES"
  )

  expect_identical(as.character(captured$body$chemicals), c("CCO", "invalid[", "CCO"))
  expect_equal(nrow(result), 4L)
  expect_identical(result$input_index, 1:4)
  expect_identical(result$query, c("CCO", "invalid[", "CCO", NA_character_))
  expect_identical(result$status, c("ok", "error", "ok", "error"))
  expect_equal(result$first[c(1, 3)], c(1, 1))
  expect_match(result$error[[2]], "No descriptor values")
  expect_match(result$error[[4]], "missing or empty")
})

test_that("all-invalid input skips HTTP but still runs descriptor post-hooks", {
  called <- FALSE
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      called <<- TRUE
      stop("must not be called")
    },
    .package = "ComptoxR"
  )

  result <- chemi_rdkit_bulk(c(NA_character_, ""))

  expect_false(called)
  expect_equal(nrow(result), 2L)
  expect_true(all(result$status == "error"))
  expect_identical(result$input_index, 1:2)
  expect_true(all(result$source_endpoint == "rdkit"))
})

test_that("header mismatches and empty successful responses become explicit rows", {
  responses <- list(
    descriptor_contract_response(
      records = list(descriptor_contract_record(descriptors = 1)),
      headers = c("a", "b")
    ),
    list()
  )
  call_index <- 0L
  local_mocked_bindings(
    generic_request = function(...) {
      call_index <<- call_index + 1L
      responses[[call_index]]
    },
    .package = "ComptoxR"
  )

  mismatch <- chemi_padel("CCO")
  empty <- chemi_padel("CCO")

  expect_identical(mismatch$status, "error")
  expect_match(mismatch$error, "count mismatch")
  expect_true(is.na(mismatch$a))
  expect_true(is.na(mismatch$b))
  expect_identical(empty$status, "error")
  expect_match(empty$error, "empty response")
})

test_that("CSV and TSV successful responses use the same wide contract", {
  content_types <- character()
  local_mocked_bindings(
    generic_request = function(...) {
      call <- list(...)
      content_types <<- c(content_types, call$content_type)
      separator <- if (identical(call$content_type, "text/tab-separated-values")) "\t" else ","
      paste0(
        paste(c("Ordinal", "SMILES", "InChI", "InChIKey", "exact Header"), collapse = separator),
        "\n",
        paste(c("0", "CCO", "mock-inchi", "mock-key", "1.5"), collapse = separator)
      )
    },
    .package = "ComptoxR"
  )

  csv <- chemi_descriptors("CCO", type = "padel", format = "CSV")
  tsv <- chemi_descriptors("CCO", type = "padel", format = "TSV")

  expect_identical(content_types, c("text/csv", "text/tab-separated-values"))
  expect_true("exact Header" %in% names(csv))
  expect_equal(csv[["exact Header"]], 1.5)
  expect_equal(tsv[["exact Header"]], 1.5)
})

test_that("raw descriptor output retains actual route provenance", {
  payload <- list(info = list(name = "padel"), chemicals = list())
  local_mocked_bindings(
    generic_request = function(...) payload,
    .package = "ComptoxR"
  )
  withr::local_envvar(chemi_burl = "https://cim.sciencedataexperts.com/api")

  result <- chemi_padel("CCO", output = "raw")

  result_payload <- result
  attr(result_payload, "source_server") <- NULL
  attr(result_payload, "source_endpoint") <- NULL
  attr(result_payload, "fallback_used") <- NULL
  attr(result_payload, "input_map") <- NULL
  expect_identical(result_payload, payload)
  expect_identical(attr(result, "source_server"), "https://cim.sciencedataexperts.com/api")
  expect_identical(attr(result, "source_endpoint"), "padel")
  expect_false(attr(result, "fallback_used"))
})

test_that("known descriptor fallbacks are independent and carry provenance", {
  production <- "https://hcd.rtpnc.epa.gov/api"
  staging <- "https://cim.sciencedataexperts.com/api"
  withr::local_envvar(chemi_burl = production)
  calls <- list()
  local_mocked_bindings(
    generic_request = function(...) {
      call <- list(...)
      calls[[length(calls) + 1L]] <<- call
      descriptor_contract_response(
        records = list(descriptor_contract_record(
          descriptors = if (identical(call$endpoint, "rdkit")) seq_len(1024) else c(1, 2)
        )),
        headers = if (identical(call$endpoint, "mordred")) c("a", "b") else character()
      )
    },
    .package = "ComptoxR"
  )

  expect_warning(
    aggregate_mordred <- chemi_descriptors("CCO", type = "mordred"),
    "staging dedicated Mordred"
  )
  expect_warning(
    dedicated_mordred <- chemi_mordred("CCO"),
    "Production dedicated Mordred"
  )
  expect_warning(
    aggregate_rdkit <- chemi_descriptors("CCO", type = "rdkit"),
    "dedicated RDKit"
  )

  expect_identical(vapply(calls, `[[`, character(1), "server"), c(staging, staging, production))
  expect_identical(vapply(calls, `[[`, character(1), "endpoint"), c("mordred", "mordred", "rdkit"))
  expect_identical(calls[[3]]$options$bits, 1024L)
  expect_true(all(aggregate_mordred$fallback_used))
  expect_true(all(dedicated_mordred$fallback_used))
  expect_true(all(aggregate_rdkit$fallback_used))
})

test_that("successful embedded service failures become descriptor status rows", {
  local_mocked_bindings(
    generic_request = function(...) {
      descriptor_contract_response(
        records = list(list(smiles = "invalid[", error = list(message = "invalid structure"))),
        headers = c("a")
      )
    },
    .package = "ComptoxR"
  )

  result <- chemi_padel("invalid[")

  expect_identical(result$status, "error")
  expect_match(result$error, "invalid structure")
})

test_that("generic-helper failures propagate without descriptor conversion", {
  local_mocked_bindings(
    generic_request = function(...) {
      rlang::abort("transport failure", class = "sentinel_http_error")
    },
    .package = "ComptoxR"
  )

  condition <- rlang::catch_cnd(chemi_padel("CCO"))

  expect_s3_class(condition, "sentinel_http_error")
  expect_false(inherits(condition, "comptoxr_post_response_hook_error"))
})

test_that("identifier resolution preserves original queries and duplicate positions", {
  captured <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      lapply(ids, function(id) {
        list(
          result = "FOUND",
          chemical = list(sid = id, canonicalSmiles = paste0("resolved-", id))
        )
      })
    },
    generic_chemi_request = function(...) {
      captured <<- list(...)
      descriptor_contract_response(
        records = lapply(seq_along(captured$body$chemicals), function(index) {
          descriptor_contract_record(
            smiles = as.character(captured$body$chemicals[[index]]),
            descriptors = c(1, 2),
            ordinal = index - 1L
          )
        }),
        headers = c("a", "b")
      )
    },
    .package = "ComptoxR"
  )

  result <- chemi_descriptors_bulk(
    c("DTXSID7020182", "DTXSID7020182"),
    type = "padel"
  )

  expect_identical(
    as.character(captured$body$chemicals),
    rep("resolved-DTXSID7020182", 2)
  )
  expect_identical(result$query, rep("DTXSID7020182", 2))
  expect_identical(result$input_index, 1:2)
  expect_true(all(result$status == "ok"))
})

test_that("run_hook is identity when unconfigured and provides active context", {
  registry <- get(".HookRegistry", envir = asNamespace("ComptoxR"))
  old_config <- registry$config
  withr::defer(registry$config <- old_config)

  input <- list(params = list(value = 1))
  expect_identical(
    get("run_hook", envir = asNamespace("ComptoxR"))(
      "unconfigured_wrapper",
      "pre_request",
      input
    ),
    input
  )
  expect_error(
    get("run_hook", envir = asNamespace("ComptoxR"))(
      "unconfigured_wrapper",
      "transform",
      input
    ),
    "Unsupported hook stage"
  )

  registry$config$test_wrapper <- list(pre_request = "identity")
  expect_identical(
    get("run_hook", envir = asNamespace("ComptoxR"))(
      "test_wrapper",
      "pre_request",
      input
    ),
    c(input, list(fn_name = "test_wrapper", hook_type = "pre_request"))
  )
})

test_that("unexpected hook failures are stage-specific and retain parents", {
  registry <- get(".HookRegistry", envir = asNamespace("ComptoxR"))
  old_config <- registry$config
  withr::defer(registry$config <- old_config)
  registry$config$test_wrapper <- list(
    pre_request = "descriptor_test_failure",
    post_response = "descriptor_test_failure"
  )
  descriptor_test_failure <- function(data) {
    rlang::abort("hook failed", class = "sentinel_hook_error")
  }

  for (stage in c("pre_request", "post_response")) {
    condition <- rlang::catch_cnd(
      get("run_hook", envir = asNamespace("ComptoxR"))(
        "test_wrapper",
        stage,
        list()
      )
    )
    expect_s3_class(condition, paste0("comptoxr_", stage, "_hook_error"))
    expect_s3_class(condition$parent, "sentinel_hook_error")
    expect_identical(condition$function_name, "test_wrapper")
    expect_identical(condition$hook_name, "descriptor_test_failure")
  }
})
