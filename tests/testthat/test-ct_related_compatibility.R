test_that("ct_related uses the legacy ccdapp2 route and restores ctx server", {
  old_server <- "https://comptox.epa.gov/ctx-api/"
  withr::local_envvar(c(ctx_burl = old_server))

  called_server <- NULL
  testthat::local_mocked_bindings(
    generic_request = function(...) {
      # ct_related passes the legacy ccdapp2 route as an explicit `server` argument
      # (like ct_similar), not by mutating the ctx_burl env var.
      called_server <<- list(...)[["server"]]
      list(
        data = list(
          list(dtxsid = "DTXSID7020182", relationship = "self"),
          list(dtxsid = "DTXSID1020560", relationship = "related")
        )
      )
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(ComptoxR::ct_related(query = "DTXSID7020182"))

  expect_equal(called_server, "https://comptox.epa.gov/dashboard-api/ccdapp2/")
  expect_equal(Sys.getenv("ctx_burl"), old_server)
  expect_s3_class(result, "tbl_df")
  expect_equal(result$child, "DTXSID1020560")
})

test_that("ct_related extracts data from wrapped generic_request responses", {
  testthat::local_mocked_bindings(
    generic_request = function(...) {
      list(list(
        data = list(
          list(dtxsid = "DTXSID80109469", relationship = "Searched Chemical"),
          list(dtxsid = "DTXSID2021868", relationship = "Markush Child"),
          list(dtxsid = "DTXSID6026298", relationship = "Markush Child")
        )
      ))
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(ComptoxR::ct_related(query = "DTXSID80109469"))

  expect_equal(result$child, c("DTXSID2021868", "DTXSID6026298"))
  expect_equal(result$relationship, c("Markush Child", "Markush Child"))
})

test_that("ct_related gates payload header behind run_verbose", {
  testthat::local_mocked_bindings(
    generic_request = function(...) {
      list(
        data = list(
          list(dtxsid = "DTXSID1", relationship = "Searched Chemical"),
          list(dtxsid = "DTXSID2", relationship = "related")
        )
      )
    },
    .package = "ComptoxR"
  )

  withr::local_options(list(ComptoxR.run_verbose = FALSE))
  quiet_output <- capture.output(
    result <- ComptoxR::ct_related(query = "DTXSID1"),
    type = "message"
  )
  expect_equal(result$child, "DTXSID2")
  expect_false(any(grepl("Related substances payload options", quiet_output, fixed = TRUE)))

  withr::local_options(list(ComptoxR.run_verbose = TRUE))
  verbose_output <- capture.output(
    verbose_result <- ComptoxR::ct_related(query = "DTXSID1"),
    type = "message"
  )
  expect_equal(verbose_result$child, "DTXSID2")
  expect_true(any(grepl("Related substances payload options", verbose_output, fixed = TRUE)))
})
