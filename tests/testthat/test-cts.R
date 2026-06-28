test_that("cts_server sets and resets the CTS base URL", {
  old <- Sys.getenv("cts_burl")
  on.exit(Sys.setenv("cts_burl" = old), add = TRUE)

  suppressMessages(cts_server(1))
  expect_equal(Sys.getenv("cts_burl"), "https://qed.epa.gov/cts/rest")

  suppressMessages(cts_server(NULL))
  expect_equal(Sys.getenv("cts_burl"), "")
})

test_that("CTS blacklist excludes p-chem, metadata, and envipath routes", {
  routes <- c(
    "/cts",
    "/chemaxon/run",
    "/epi/inputs",
    "/test/run",
    "/testws/run",
    "/opera/run",
    "/measured/inputs",
    "/envipath/run",
    "/metabolizer",
    "/metabolizer/inputs",
    "/metabolizer/run"
  )

  excluded <- .cts_endpoint_blacklisted(routes)

  expect_true(all(excluded[1:8]))
  expect_false(any(excluded[9:11]))
})

test_that("generic_cts_request dry run sends an unauthenticated JSON object body", {
  withr::local_envvar(c(
    run_debug = "TRUE",
    cts_burl = "https://example.test/cts/rest",
    ctx_api_key = "logic_test_key"
  ))

  output <- capture_output(
    generic_cts_request(
      endpoint = "metabolizer/run",
      body = list(
        structure = "CCCC",
        generationLimit = 1,
        transformationLibraries = list("hydrolysis")
      )
    )
  )

  expect_match(output, "POST /cts/rest/metabolizer/run")
  expect_match(output, "\"structure\"\\s*:\\s*\"CCCC\"")
  expect_match(output, "\"generationLimit\"\\s*:\\s*1")
  expect_match(output, "\"transformationLibraries\"\\s*:\\s*\\[")
  expect_false(grepl("x-api-key", output, ignore.case = TRUE))
})

test_that("generic_cts_request sends an empty JSON object for empty bodies", {
  withr::local_envvar(c(
    run_debug = "TRUE",
    cts_burl = "https://example.test/cts/rest"
  ))

  output <- capture_output(
    generic_cts_request(endpoint = "metabolizer/inputs", body = list())
  )

  expect_match(output, "\\{\\s*\\}")
  expect_false(grepl("\\[\\s*\\]", output))
})

test_that("cts_resolve_smiles passes through SMILES when resolve is FALSE", {
  result <- cts_resolve_smiles(c("CCCC", "CCO"), resolve = FALSE)

  expect_equal(unname(result), c("CCCC", "CCO"))
  expect_equal(names(result), c("CCCC", "CCO"))
})

test_that("cts_resolve_smiles resolves identifiers to one SMILES per query", {
  local_mocked_bindings(
    generic_request = function(query, endpoint = NULL, ...) {
      expect_equal(endpoint, "resolver/lookup")
      tibble::tibble(
        query = query,
        smiles = if (query == "DTXSID7020182") "c1ccccc1" else "CCO"
      )
    },
    .package = "ComptoxR"
  )

  result <- cts_resolve_smiles(c("DTXSID7020182", "ethanol"))

  expect_equal(unname(result), c("c1ccccc1", "CCO"))
  expect_equal(names(result), c("DTXSID7020182", "ethanol"))
})

test_that("cts_resolve_smiles extracts SMILES from compact resolver chemical field", {
  local_mocked_bindings(
    generic_request = function(query, endpoint = NULL, ...) {
      expect_equal(endpoint, "resolver/lookup")
      tibble::tibble(
        chemical = paste(
          query,
          "DTXCID30182",
          query,
          "80-05-7",
          "Bisphenol A",
          "CC(C)(c1ccc(O)cc1)c1ccc(O)cc1",
          sep = "; "
        ),
        result = "FOUND",
        query = query
      )
    },
    .package = "ComptoxR"
  )

  result <- cts_resolve_smiles("DTXSID7020182")

  expect_equal(unname(result), "CC(C)(c1ccc(O)cc1)c1ccc(O)cc1")
})

test_that("cts_resolve_smiles aborts on unresolved or missing SMILES", {
  testthat::with_mocked_bindings(
    generic_request = function(query, endpoint = NULL, ...) {
      expect_equal(endpoint, "resolver/lookup")
      tibble::tibble(query = query, smiles = NA_character_)
    },
    .package = "ComptoxR",
    {
      expect_error(
        cts_resolve_smiles("missing"),
        "Could not resolve"
      )
    }
  )

  testthat::with_mocked_bindings(
    generic_request = function(query, endpoint = NULL, ...) {
      expect_equal(endpoint, "resolver/lookup")
      tibble::tibble(query = query)
    },
    .package = "ComptoxR",
    {
      expect_error(
        cts_resolve_smiles("no-smiles-column"),
        "Could not resolve"
      )
    }
  )
})

test_that("cts_resolve_smiles aborts on ambiguous SMILES", {
  local_mocked_bindings(
    generic_request = function(query, endpoint = NULL, ...) {
      expect_equal(endpoint, "resolver/lookup")
      tibble::tibble(
        query = query,
        smiles = c("CCC", "CCO")
      )
    },
    .package = "ComptoxR"
  )

  expect_error(
    cts_resolve_smiles("ambiguous"),
    "multiple SMILES"
  )
})

test_that("cts_flatten_metabolizer_tree preserves hierarchy and chemistry fields", {
  tree <- list(
    data = list(
      data = list(
        id = 1,
        data = list(
          smiles = "CCO",
          routes = "",
          generation = 0,
          accumulation = 0,
          production = 100,
          globalAccumulation = 0,
          likelihood = "ROOT"
        ),
        children = list(
          list(
            id = 2,
            data = list(
              smiles = "CC=O",
              routes = "oxidation",
              generation = 1,
              accumulation = 5,
              production = 30,
              globalAccumulation = 5,
              likelihood = "LIKELY"
            ),
            children = list()
          ),
          list(
            id = 3,
            data = list(
              smiles = "C=C",
              routes = c("dehydration", "hydrolysis"),
              generation = 1,
              accumulation = 1,
              production = 10,
              globalAccumulation = 1,
              likelihood = "POSSIBLE"
            ),
            children = list()
          )
        )
      )
    )
  )

  flat <- cts_flatten_metabolizer_tree(tree, query = "ethanol")

  expect_s3_class(flat, "tbl_df")
  expect_equal(nrow(flat), 3)
  expect_equal(flat$node_id, c("1", "2", "3"))
  expect_equal(flat$parent_id, c(NA_character_, "1", "1"))
  expect_equal(flat$child_ids[[1]], c("2", "3"))
  expect_equal(flat$generation, c(0, 1, 1))
  expect_equal(flat$routes[[3]], "dehydration; hydrolysis")
  expect_equal(flat$likelihood[[2]], "LIKELY")
  expect_equal(flat$production[[1]], 100)
  expect_equal(flat$accumulation[[2]], 5)
  expect_equal(flat$smiles, c("CCO", "CC=O", "C=C"))
})

test_that("cts_metabolizer_run can return tidy flattened output", {
  response <- list(
    data = list(
      data = list(
        id = 1,
        data = list(
          smiles = "CCCC",
          routes = "",
          generation = 0,
          accumulation = 0,
          production = 100,
          likelihood = "ROOT"
        ),
        children = list()
      )
    )
  )

  local_mocked_bindings(
    generic_cts_request = function(endpoint, body = list(), method = "POST", tidy = FALSE) {
      expect_equal(endpoint, "metabolizer/run")
      expect_equal(body$structure, "CCCC")
      expect_equal(body$generationLimit, 1L)
      expect_equal(body$transformationLibraries, list("hydrolysis"))
      response
    }
  )

  result <- cts_metabolizer_run("CCCC", resolve = FALSE, tidy = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(result$smiles, "CCCC")
})

test_that("cts_metabolizer_inputs live smoke test", {
  skip_if(Sys.getenv("RUN_LIVE_CTS") != "true", "Set RUN_LIVE_CTS=true to run live CTS tests")
  skip_if_offline()

  result <- cts_metabolizer_inputs()

  expect_type(result, "list")
  expect_true("inputs" %in% names(result))
})

test_that("cts_metabolizer_run live smoke test", {
  skip_if(Sys.getenv("RUN_LIVE_CTS") != "true", "Set RUN_LIVE_CTS=true to run live CTS tests")
  skip_if_offline()

  result <- cts_metabolizer_run("CCCC", resolve = FALSE, tidy = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 1)
  expect_true("smiles" %in% names(result))
})
