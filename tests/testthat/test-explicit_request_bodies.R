test_that("explicit body builders preserve fields, NULL omission and falsy values", {
  captured <- NULL
  local_mocked_bindings(generic_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, .package = "ComptoxR")
  for (name in c("ct_chemical_msready_search_by_mass_bulk", "epi_submit_batch")) {
    fun <- getExportedValue("ComptoxR", name)
    fields <- names(formals(fun))
    required <- if (name == "epi_submit_batch") "modules" else fields
    minimal <- setNames(rep(list("value"), length(required)), required)
    default_body <- if (name == "epi_submit_batch") c(minimal, list(vaporPressureTemperatureC = 25)) else minimal
    expect_identical(do.call(fun, minimal), list(result = "unchanged"))
    expect_identical(captured$body, default_body)
    expect_identical(captured$endpoint, if (name == "epi_submit_batch") "submit/batch" else "chemical/msready/search/by-mass/")
    expect_identical(captured$method, "POST")
    expect_null(captured$query)
    expect_false(any(c("auth", "server", "tidy") %in% names(captured)))
    for (value in list("caf\u00e9 +/&", FALSE, 0, list(), NULL)) {
      supplied <- setNames(rep(list(value), length(fields)), fields)
      do.call(fun, supplied)
      expected <- Filter(Negate(is.null), supplied)
      expect_identical(captured$body, if (length(expected)) expected else list())
    }
    for (field in required) {
      supplied <- minimal
      supplied[[field]] <- NULL
      captured <- NULL
      expect_error(do.call(fun, supplied), paste0('argument "', field, '" is missing'), fixed = TRUE)
      expect_null(captured)
    }
    expect_error(fun(), paste0('argument "', required[[1]], '" is missing'), fixed = TRUE)
    for (setting in c(NA_character_, "2", "0", "1001", "invalid")) {
      withr::with_envvar(c(batch_limit = setting), {
        suppressWarnings(do.call(fun, minimal))
        expect_identical(captured$batch_limit, suppressWarnings(as.numeric(if (is.na(setting)) "1000" else setting)))
      })
    }
  }
})

test_that("mass-range GET keeps optional end and vector path semantics", {
  captured <- NULL
  local_mocked_bindings(generic_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, .package = "ComptoxR")
  expect_identical(formals(ct_chemical_msready_search_by_mass), formals(function(start, end = NULL) NULL))
  expect_identical(ct_chemical_msready_search_by_mass(200.9), list(result = "unchanged"))
  expect_null(captured$path_params)
  for (end in list(NULL, 200.95, FALSE, 0, character(), c(201, 202))) {
    ct_chemical_msready_search_by_mass(200.9, end)
    expect_identical(captured, list(query = 200.9, endpoint = "chemical/msready/search/by-mass/",
      method = "GET", batch_limit = 1, path_params = c(end = end)))
  }
  ct_chemical_msready_search_by_mass(NULL)
  expect_null(captured$query)
  expect_error(ct_chemical_msready_search_by_mass(), 'argument "start" is missing', fixed = TRUE)
})
