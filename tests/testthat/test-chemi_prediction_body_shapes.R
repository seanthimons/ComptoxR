test_that("bulk predictions preserve both body shapes and reject ambiguous bodies", {
  captured <- NULL
  testthat::local_mocked_bindings(
    generic_chemi_request = function(...) {
      captured <<- list(...)
      list(result = "unchanged")
    },
    .package = "ComptoxR"
  )
  chemicals <- list(list(id = 1L, smiles = "CCO"), list(id = "ext-2", smiles = "CCCC"))
  for (name in c("chemi_opera_bulk", "chemi_predictor_models_predict_bulk")) {
    fun <- getExportedValue("ComptoxR", name)
    inputs <- if (name == "chemi_opera_bulk") list() else list(model_id = 1065L)
    defaults <- if (name == "chemi_opera_bulk") list(cache_only = FALSE) else inputs
    for (shape in c("smiles", "chemicals")) {
      for (value in list(if (shape == "smiles") c("CCO", "CCCC") else chemicals, list(), FALSE, 0)) {
        supplied <- inputs
        supplied[[shape]] <- value
        supplied[setdiff(c("smiles", "chemicals"), shape)] <- list(NULL)
        expect_identical(do.call(fun, supplied), list(result = "unchanged"))
        expect_identical(captured$body, c(defaults, setNames(list(value), shape)))
        expect_identical(captured$endpoint, if (name == "chemi_opera_bulk") "opera" else "predictor_models/predict")
        expect_identical(captured$tidy, FALSE)
        expect_null(captured$query)
        expect_null(captured$options)
      }
    }
    for (invalid in list(inputs, c(inputs, list(smiles = NULL, chemicals = NULL)),
      c(inputs, list(smiles = "CCO", chemicals = chemicals)))) {
      captured <- NULL
      expect_error(do.call(fun, invalid), "Supply exactly one supported request-body shape.", fixed = TRUE)
      expect_null(captured)
    }
    captured <- NULL
    if (name == "chemi_predictor_models_predict_bulk") {
      expect_error(fun(smiles = "CCO"), 'argument "model_id" is missing', fixed = TRUE)
      expect_error(fun(model_id = NULL, smiles = "CCO"), "Supply exactly one supported request-body shape.", fixed = TRUE)
      expect_error(fun(model_id = NULL, chemicals = chemicals), "Supply exactly one supported request-body shape.", fixed = TRUE)
    } else {
      expect_error(fun(), "Supply exactly one supported request-body shape.", fixed = TRUE)
    }
    expect_null(captured)
  }
  chemi_opera_bulk(smiles = "CCO", cache_only = TRUE, format = "csv", standardize = TRUE)
  expect_identical(captured, list(endpoint = "opera", body = list(cache_only = TRUE, smiles = "CCO"),
    tidy = FALSE, format = "csv", standardize = TRUE))
  chemi_opera_bulk(chemicals = chemicals, cache_only = NULL, format = NULL, standardize = NULL)
  expect_identical(captured, list(endpoint = "opera", body = list(chemicals = chemicals),
    tidy = FALSE, format = NULL, standardize = NULL))
})

test_that("prediction GET siblings keep query options and transport settings", {
  captured <- NULL
  testthat::local_mocked_bindings(
    generic_request = function(...) {
      captured <<- list(...)
      list(result = "unchanged")
    },
    .package = "ComptoxR"
  )
  expect_identical(chemi_opera("CCO"), list(result = "unchanged"))
  expect_identical(captured, list(endpoint = "opera", method = "GET", batch_limit = 0,
    server = "chemi_burl", auth = FALSE, tidy = FALSE,
    options = list(smiles = "CCO", format = "json", standardize = FALSE)))
  expect_identical(chemi_predictor_models_predict(1065L, identifier = "DTXSID7020182"), list(result = "unchanged"))
  expect_identical(captured, list(endpoint = "predictor_models/predict", method = "GET", batch_limit = 0,
    server = "chemi_burl", auth = FALSE, tidy = FALSE,
    options = list(identifier = "DTXSID7020182", model_id = 1065L, report_format = "json")))
  chemi_opera("CCO", format = NULL, standardize = NULL)
  expect_identical(captured$options, list(smiles = "CCO"))
  chemi_predictor_models_predict(1065L, report_format = NULL)
  expect_identical(captured$options, list(model_id = 1065L))
})
