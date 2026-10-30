test_that("EPI batch submission sends one declared estimate without CTX authentication", {
  withr::local_envvar(ctx_api_key = NA_character_)
  withr::local_options(list(ComptoxR.epi_burl = "https://epi.example.invalid/api",
                           ComptoxR.ctx_burl = "https://ctx.example.invalid"))
  requests <- list()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('[{"value":0,"flag":false}]'))
  }, .package = "httr2")
  result <- epi_submit_batch(modules = c("logKow", "physicalProperties"),
    smiles = "CCO", chemicalName = "café /+&", removeMetals = FALSE, ethoxylate = 0L)
  expect_identical(result, tibble::tibble(value = 0L, flag = FALSE))
  expect_identical(requests[[1L]]$url, "https://epi.example.invalid/api/submit/batch")
  expect_false("x-api-key" %in% names(requests[[1L]]$headers))
  expect_identical(requests[[1L]]$headers$Accept, "application/json")
  body <- requests[[1L]]$body$data
  expect_null(names(body))
  expect_length(body, 1L)
  expect_identical(body[[1L]]$modules, list("logKow", "physicalProperties"))
  expect_identical(body[[1L]]$chemicalName, "café /+&")
  expect_identical(body[[1L]]$removeMetals, FALSE)
  expect_identical(body[[1L]]$ethoxylate, 0L)
  expect_identical(body[[1L]]$vaporPressureTemperatureC, 25)
  expect_null(body[[1L]]$waterSolubilityProvider)
  epi_submit_batch("logKow", smiles = "CCO")
  expect_identical(requests[[2L]]$body$data[[1L]]$modules, list("logKow"))
  expect_error(epi_submit_batch("invalid-module", smiles = "CCO"), "Invalid|enum")
  expect_error(epi_submit_batch(character(), smiles = "CCO"), "Invalid|items")
  expect_length(requests, 2L)
})

test_that("EPI batch preserves its formals and captured production response", {
  fixture <- readRDS(test_path("fixtures/native-epi-batch.rds"))
  expect_identical(formals(epi_submit_batch), fixture$formals)
  withr::local_envvar(ctx_api_key = NA_character_)
  local_mocked_bindings(req_perform = function(req, ...) {
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = fixture$production_response)
  }, .package = "httr2")
  expect_identical(epi_submit_batch(modules = "logKow", smiles = "CCO"), fixture$production_result)
})

test_that("native EPI calculation wrappers expose declared inputs and unwrap results", {
  requests <- list()
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- req
    httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"result":{"value":0,"missing":null,"flag":false}}'))
  }, .package = "httr2")
  result <- list(result = list(value = 0L, missing = NULL, flag = FALSE))
  expect_identical(epi_ecosar_dye(molecularWeight = 300, waterSolubility = 100), result)
  expect_identical(epi_ecosar_polymer_nonionic("INSOLUBLE", averageMolecularWeight = 5000,
    mw500Percentage = 5, mw1000Percentage = 10), result)
  expect_identical(epi_ecosar_surfactant_nonionic(12L, branches = 0L,
    waterSolubility = 100, logKow = 3, molecularWeight = 250), result)
  queries <- lapply(requests, function(req) httr2::url_parse(req$url)$query)
  expect_identical(queries[[1]]$molecularWeight, "300")
  expect_identical(queries[[1]]$ethoxylate, "0")
  expect_identical(queries[[2]]$solubilityType, "INSOLUBLE")
  expect_identical(queries[[3]]$mainCarbons, "12")
  expect_identical(queries[[3]]$branches, "0")
  expect_identical(queries[[3]]$useSmiles, "false")
  expect_true(all(vapply(requests, function(req) is.null(req$body), logical(1))))
  expect_false(any(vapply(requests, function(req) "x-api-key" %in% names(req$headers), logical(1))))
  expect_error(epi_ecosar_polymer_nonionic(), "solubilityType")
  expect_error(epi_ecosar_polymer_nonionic("invalid"), "Invalid")
  expect_error(epi_ecosar_surfactant_nonionic(0), "Invalid")
  expect_error(epi_ecosar_dye(waterSolubility = 0), "Invalid")
  expect_length(requests, 3L)
})

test_that("native EPI submit preserves its existing query defaults and false/zero values", {
  request <- NULL
  testthat::local_mocked_bindings(req_perform = function(req, ...) {
    request <<- req
    httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"logKow":{"value":0,"flag":false}}'))
  }, .package = "httr2")
  result <- epi_submit(smiles = "CCO", modules = "logKow", chemicalName = "café /+&",
    removeMetals = FALSE, tspUgPerM3 = 0, waterSolubilityProvider = NULL)
  expect_identical(result, list(logKow = list(value = 0L, flag = FALSE)))
  query <- httr2::url_parse(request$url)$query
  expect_identical(query$smiles, "CCO")
  expect_identical(query$modules, "logKow")
  expect_identical(query$chemicalName, "café /+&")
  expect_identical(query$removeMetals, "FALSE")
  expect_identical(query$tspUgPerM3, "0")
  expect_identical(query$vaporPressureTemperatureC, "25")
  expect_null(query$waterSolubilityProvider)
  expect_null(request$body)
  expect_identical(request$headers$Accept, "application/json")
})
