test_that("explicit body builders preserve fields, NULL omission and falsy values", {
  captured <- NULL
  local_mocked_bindings(generic_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, .package = "ComptoxR")
  for (name in "epi_submit_batch") {
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
