test_that("scalar descriptor wrappers build dedicated and aggregate GET requests", {
  withr::local_envvar(chemi_burl = "https://cim.sciencedataexperts.com/api")
  calls <- list()
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      calls[[length(calls) + 1L]] <<- spec
      if (identical(spec$engine, "rdkit")) {
        return(descriptor_contract_response(
          records = list(descriptor_contract_record(descriptors = 1:4))
        ))
      }
      descriptor_contract_response(
        records = list(descriptor_contract_record()),
        headers = c("upstream_a", "upstream_b")
      )
    },
    .package = "ComptoxR"
  )

  aggregate <- chemi_descriptors("CCO", type = "padel")
  padel <- chemi_padel("CCO", x2d = TRUE, x3d = TRUE, fp = TRUE)
  rdkit <- chemi_rdkit("CCO", type = "ecfp", radius = 2, bits = 4)
  mordred <- chemi_mordred("CCO", headers = FALSE, inchi = TRUE)
  webtest <- chemi_webtest("CCO")

  expect_equal(vapply(calls, `[[`, character(1), "method"), rep("GET", 5))
  expect_equal(
    vapply(calls, `[[`, character(1), "endpoint"),
    c("descriptors", "padel", "rdkit", "mordred", "webtest")
  )
  expect_identical(calls[[1]]$query$type, "padel")
  expect_true(calls[[1]]$query$headers)
  expect_true(calls[[2]]$query$`2d`)
  expect_true(calls[[2]]$query$`3d`)
  expect_true(calls[[2]]$query$fp)
  expect_identical(calls[[3]]$query$bits, 4L)
  expect_true(calls[[4]]$query$headers)

  expect_s3_class(aggregate, "tbl_df")
  expect_true(all(c("upstream_a", "upstream_b") %in% names(padel)))
  expect_true(all(sprintf("ecfp_%04d", 1:4) %in% names(rdkit)))
  expect_equal(nrow(mordred), 1L)
  expect_equal(nrow(webtest), 1L)
})

test_that("bulk descriptor wrappers build contract-correct POST bodies", {
  withr::local_envvar(chemi_burl = "https://cim.sciencedataexperts.com/api")
  calls <- list()
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      calls[[length(calls) + 1L]] <<- spec
      records <- lapply(seq_along(spec$body$chemicals), function(i) {
        descriptor_contract_record(
          smiles = as.character(spec$body$chemicals[[i]]),
          descriptors = if (identical(spec$engine, "rdkit")) 1:8 else c(1, 2),
          ordinal = if (identical(spec$mode, "aggregate")) i - 1L else NULL
        )
      })
      descriptor_contract_response(
        records = records,
        headers = if (identical(spec$engine, "rdkit")) character() else c("a", "b")
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

  expect_equal(vapply(calls, `[[`, character(1), "method"), rep("POST", 5))
  expect_equal(
    vapply(calls, `[[`, character(1), "endpoint"),
    c("descriptors", "padel", "rdkit", "mordred", "webtest")
  )
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
  withr::local_envvar(chemi_burl = "https://hcd.rtpnc.epa.gov/api")
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
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

  expect_equal(nrow(result), 4L)
  expect_identical(result$input_index, 1:4)
  expect_identical(result$query, c("CCO", "invalid[", "CCO", NA_character_))
  expect_identical(result$status, c("ok", "error", "ok", "error"))
  expect_equal(result$first[c(1, 3)], c(1, 1))
  expect_true(is.na(result$first[[2]]))
  expect_match(result$error[[2]], "No descriptor values")
  expect_match(result$error[[4]], "missing or empty")
})

test_that("all-invalid input skips HTTP and still returns one row per input", {
  called <- FALSE
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
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
})

test_that("header/value mismatches and empty 200 responses become explicit errors", {
  responses <- list(
    descriptor_contract_response(
      records = list(descriptor_contract_record(descriptors = 1)),
      headers = c("a", "b")
    ),
    list(status = 200L, content_type = "application/json", body = list())
  )
  call_index <- 0L
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
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

test_that("CSV and TSV descriptor responses use the same wide contract", {
  formats <- character()
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      formats <<- c(formats, spec$format)
      separator <- if (identical(spec$format, "TSV")) "\t" else ","
      text <- paste0(
        paste(c("Ordinal", "SMILES", "InChI", "InChIKey", "exact Header"), collapse = separator),
        "\n",
        paste(c("0", "CCO", "mock-inchi", "mock-key", "1.5"), collapse = separator)
      )
      list(
        status = 200L,
        content_type = if (identical(spec$format, "TSV")) {
          "text/tab-separated-values"
        } else {
          "text/csv"
        },
        body = text
      )
    },
    .package = "ComptoxR"
  )

  csv <- chemi_descriptors("CCO", type = "padel", format = "CSV")
  tsv <- chemi_descriptors("CCO", type = "padel", format = "TSV")

  expect_identical(formats, c("CSV", "TSV"))
  expect_true("exact Header" %in% names(csv))
  expect_equal(csv[["exact Header"]], 1.5)
  expect_equal(tsv[["exact Header"]], 1.5)
})

test_that("raw descriptor output retains source provenance", {
  withr::local_envvar(chemi_burl = "https://cim.sciencedataexperts.com/api")
  payload <- list(info = list(name = "padel"), chemicals = list())
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      list(status = 200L, content_type = "application/json", body = payload)
    },
    .package = "ComptoxR"
  )

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

test_that("known descriptor fallbacks are explicit and carry provenance", {
  production <- "https://hcd.rtpnc.epa.gov/api"
  staging <- "https://cim.sciencedataexperts.com/api"
  withr::local_envvar(chemi_burl = production)
  calls <- list()
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      calls[[length(calls) + 1L]] <<- spec
      descriptor_contract_response(
        records = list(descriptor_contract_record(
          descriptors = if (identical(spec$engine, "rdkit")) seq_len(1024) else c(1, 2)
        )),
        headers = if (identical(spec$engine, "mordred")) c("a", "b") else character()
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

  expect_identical(calls[[1]]$server, staging)
  expect_identical(calls[[1]]$endpoint, "mordred")
  expect_identical(calls[[2]]$server, staging)
  expect_identical(calls[[2]]$endpoint, "mordred")
  expect_identical(calls[[3]]$server, production)
  expect_identical(calls[[3]]$endpoint, "rdkit")
  expect_identical(calls[[3]]$query$bits, 1024L)
  expect_true(all(aggregate_mordred$fallback_used))
  expect_true(all(dedicated_mordred$fallback_used))
  expect_true(all(aggregate_rdkit$fallback_used))
})

test_that("staging and development aggregate RDKit route to dedicated 1024-bit ECFP", {
  for (server in c(
    "https://cim.sciencedataexperts.com/api",
    "https://cim-dev.sciencedataexperts.com/api"
  )) {
    withr::local_envvar(chemi_burl = server)
    captured <- NULL
    local_mocked_bindings(
      descriptor_perform_request = function(spec) {
        captured <<- spec
        descriptor_contract_response(
          records = list(descriptor_contract_record(descriptors = seq_len(1024)))
        )
      },
      .package = "ComptoxR"
    )

    expect_warning(
      result <- chemi_descriptors_bulk("CCO", type = "rdkit"),
      "dedicated RDKit"
    )
    expect_identical(captured$server, server)
    expect_identical(captured$endpoint, "rdkit")
    expect_identical(captured$body$options$type, "ecfp")
    expect_identical(captured$body$options$bits, 1024L)
    expect_equal(sum(grepl("^ecfp_", names(result))), 1024L)
  }
})

test_that("4xx responses do not trigger unlisted fallback routes", {
  withr::local_envvar(chemi_burl = "https://hcd.rtpnc.epa.gov/api")
  captured <- NULL
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      captured <<- spec
      list(
        status = 400L,
        content_type = "application/json",
        body = list(error = "Bad Request", message = "invalid structure")
      )
    },
    .package = "ComptoxR"
  )

  result <- chemi_descriptors("invalid[", type = "padel")

  expect_identical(captured$endpoint, "descriptors")
  expect_false(captured$fallback_used)
  expect_false(result$fallback_used)
  expect_identical(result$status, "error")
  expect_match(result$error, "HTTP 400")
})

test_that("identifier resolution preserves original queries and duplicate positions", {
  captured <- NULL
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      lapply(ids, function(id) {
        list(
          result = "FOUND",
          chemical = list(
            sid = id,
            canonicalSmiles = paste0("resolved-", id)
          )
        )
      })
    },
    descriptor_perform_request = function(spec) {
      captured <<- spec
      descriptor_contract_response(
        records = lapply(seq_along(spec$body$chemicals), function(i) {
          descriptor_contract_record(
            smiles = as.character(spec$body$chemicals[[i]]),
            descriptors = c(1, 2),
            ordinal = i - 1L
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

test_that("WebTEST scalar and bulk requests use required prediction bodies", {
  calls <- list()
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      lapply(ids, function(id) {
        list(
          result = "FOUND",
          chemical = list(sid = id, canonicalSmiles = "resolved-smiles")
        )
      })
    },
    descriptor_perform_request = function(spec) {
      calls[[length(calls) + 1L]] <<- spec
      descriptor_contract_response(
        records = list(webtest_contract_prediction()),
        extra = list(id = "response-id")
      )
    },
    .package = "ComptoxR"
  )

  scalar <- chemi_webtest_predict(
    "DTXSID7020182",
    endpoint = "LC50",
    method = "consensus"
  )
  bulk <- chemi_webtest_predict_bulk(
    "DTXSID7020182",
    endpoints = "LC50",
    methods = "consensus"
  )

  expect_identical(calls[[1]]$method, "GET")
  expect_identical(calls[[1]]$query$smiles, "resolved-smiles")
  expect_identical(calls[[1]]$query$endpoint, "LC50")
  expect_identical(calls[[1]]$query$format, "JSON")
  expect_identical(calls[[2]]$method, "POST")
  expect_identical(as.character(calls[[2]]$body$structures), "resolved-smiles")
  expect_identical(as.character(calls[[2]]$body$endpoints), "LC50")
  expect_identical(as.character(calls[[2]]$body$methods), "consensus")
  expect_identical(calls[[2]]$body$format, "JSON")
  expect_identical(scalar$endpoint, "LC50")
  expect_identical(scalar$method, "consensus")
  expect_identical(bulk$endpoint, "LC50")
  expect_identical(bulk$method, "consensus")
})

test_that("WebTEST output filters extra endpoints and methods and recovers failures", {
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      lapply(ids, function(id) {
        if (identical(id, "DTXSIDBAD")) {
          return(list(result = "NOT_FOUND"))
        }
        list(
          result = "FOUND",
          chemical = list(sid = id, canonicalSmiles = "resolved-smiles")
        )
      })
    },
    descriptor_perform_request = function(spec) {
      descriptor_contract_response(
        records = list(webtest_contract_prediction())
      )
    },
    .package = "ComptoxR"
  )

  result <- chemi_webtest_predict_bulk(
    c("DTXSID7020182", "DTXSIDBAD"),
    endpoints = "LC50",
    methods = "consensus"
  )

  expect_equal(nrow(result), 2L)
  expect_identical(result$input_index, 1:2)
  expect_identical(result$endpoint[[1]], "LC50")
  expect_identical(result$method[[1]], "consensus")
  expect_equal(result$predicted_value[[1]], 3.241)
  expect_equal(result$experimental_value[[1]], 4.651)
  expect_identical(result$status, c("ok", "error"))
  expect_true(is.na(result$endpoint[[2]]))
  expect_match(result$error[[2]], "Unable to resolve")
})

test_that("WebTEST embedded errors and raw non-JSON reports are explicit", {
  call_index <- 0L
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      call_index <<- call_index + 1L
      if (call_index == 1L) {
        return(descriptor_contract_response(
          records = list(list(
            chemicalId = "mock",
            error = list(code = "NO_MODEL", message = "No prediction available")
          ))
        ))
      }
      list(status = 200L, content_type = "text/html", body = "<html>report</html>")
    },
    .package = "ComptoxR"
  )

  embedded <- chemi_webtest_predict("CCO", endpoint = "LC50")
  raw <- chemi_webtest_predict(
    "CCO",
    endpoint = "LC50",
    format = "HTML",
    output = "raw"
  )

  expect_identical(embedded$status, "error")
  expect_match(embedded$error, "NO_MODEL")
  raw_payload <- raw
  attr(raw_payload, "source_server") <- NULL
  attr(raw_payload, "source_endpoint") <- NULL
  attr(raw_payload, "fallback_used") <- NULL
  attr(raw_payload, "input_map") <- NULL
  expect_identical(raw_payload, "<html>report</html>")
  expect_identical(attr(raw, "source_endpoint"), "webtest/predict")
  expect_error(
    chemi_webtest_predict("CCO", endpoint = "LC50", format = "PDF"),
    "output = \\\"raw\\\""
  )
})

test_that("prediction endpoint is required and arguments are validated before HTTP", {
  called <- FALSE
  local_mocked_bindings(
    descriptor_perform_request = function(spec) {
      called <<- TRUE
      stop("must not be called")
    },
    .package = "ComptoxR"
  )

  expect_error(chemi_webtest_predict("CCO"), "endpoint")
  expect_error(
    chemi_webtest_predict("CCO", endpoint = "LC50", method = "unknown"),
    "consensus"
  )
  expect_false(called)
})

test_that("run_hook passes the wrapper name into transform data", {
  registry <- get(".HookRegistry", envir = asNamespace("ComptoxR"))
  old_config <- registry$config
  restore_config <- function() {
    registry$config <- old_config
  }
  withr::defer(restore_config())
  registry$config$test_wrapper <- list(
    transform = "identity"
  )

  expect_identical(
    get("run_hook", envir = asNamespace("ComptoxR"))(
      "test_wrapper",
      "transform",
      list(params = list())
    ),
    list(params = list(), fn_name = "test_wrapper")
  )
})

test_that("generator emits descriptor transform wrappers with configured signatures", {
  dev_stub_generation <- testthat::test_path(
    "..",
    "..",
    "dev",
    "endpoint_eval",
    "07_stub_generation.R"
  )
  testthat::skip_if_not(
    file.exists(dev_stub_generation),
    "Maintainer-only test requires dev/endpoint_eval/"
  )
  source_pipeline_files()

  expect_identical(
    stubgen_apply_signature_overrides(
      "smiles, endpoint = NULL, format = NULL",
      list(
        endpoint = list(required = TRUE),
        format = list(default = '"JSON"')
      )
    ),
    'smiles, endpoint, format = "JSON"'
  )

  transform_text <- stubgen_build_transform_hook(
    "chemi_webtest_predict",
    'smiles, endpoint, format = "JSON", output = c("wide", "raw")'
  )
  expect_match(
    transform_text,
    'run_hook("chemi_webtest_predict", "transform"',
    fixed = TRUE
  )
  expect_match(transform_text, "`endpoint` = endpoint", fixed = TRUE)

  transform_fn <- get(
    "webtest_prediction_request_transform",
    envir = asNamespace("ComptoxR")
  )
  transform_body <- paste(deparse(body(transform_fn)), collapse = "\n")
  expect_match(transform_body, "descriptor_transform_request", fixed = TRUE)
  deep_body <- paste(
    deparse(body(get("descriptor_transform_request", envir = asNamespace("ComptoxR")))),
    collapse = "\n"
  )
  expect_match(deep_body, 'run_hook(fn_name, "pre_request"', fixed = TRUE)
  expect_match(deep_body, 'run_hook(fn_name, "post_response"', fixed = TRUE)
})
