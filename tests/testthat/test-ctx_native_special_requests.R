test_that("native CTX lookups preserve query values and paired mass bounds", {
  withr::local_envvar(ctx_api_key = "local-test-key")
  requests <- list()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      requests[[length(requests) + 1L]] <<- req
      httr2::response(status_code = 200, headers = list(`Content-Type` = "application/json"),
                      body = charToRaw('[{"id":1}]'))
    },
    .package = "httr2"
  )
  ct_bioactivity_assay_search_by_endpoint("café +/&")
  expect_identical(httr2::url_parse(requests[[1]]$url)$query$endpoint, "café +/&")
  expect_true("x-api-key" %in% names(requests[[1]]$headers))

  result <- ct_chemical_msready_search_by_mass(c(200.9, 201), 201.1)
  expect_equal(nrow(result), 2)
  expect_true(endsWith(requests[[2]]$url, "/by-mass/200.9/201.1"))
  expect_true(endsWith(requests[[3]]$url, "/by-mass/201/201.1"))
  count <- length(requests)
  expect_error(ct_chemical_msready_search_by_mass(200.9), "end")
  expect_error(ct_chemical_msready_search_by_mass("200.9", 201), "Invalid")
  expect_error(ct_chemical_msready_search_by_mass(200.9, c(201, 202)), "Invalid")
  expect_length(requests, count)

  result <- ct_chemical_detail_search(c("DTXSID7020182", "DTXSID9020112"), "compact")
  expect_equal(nrow(result), 2)
  expect_true(endsWith(httr2::url_parse(requests[[4]]$url)$path, "/DTXSID7020182"))
  expect_true(endsWith(httr2::url_parse(requests[[5]]$url)$path, "/DTXSID9020112"))
  expect_identical(httr2::url_parse(requests[[4]]$url)$query$projection, "compact")
})

test_that("native mass POST validates and preserves singleton JSON arrays", {
  withr::local_envvar(ctx_api_key = "local-test-key")
  requests <- list()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      requests[[length(requests) + 1L]] <<- req
      httr2::response(status_code = 200, headers = list(`Content-Type` = "application/json"),
                      body = charToRaw('{"201":[{"id":1}]}'))
    },
    .package = "httr2"
  )
  result <- ct_chemical_msready_search_by_mass_bulk(list(error = 5L, masses = 201))
  expect_s3_class(result, "tbl_df")
  expect_identical(requests[[1]]$body$data, list(error = 5L, masses = list(201)))
  expect_identical(as.character(jsonlite::toJSON(requests[[1]]$body$data, auto_unbox = TRUE)),
                   '{"error":5,"masses":[201]}')
  ct_chemical_msready_search_by_mass_bulk(list(error = 5L, masses = c(200.9, 201)))
  expect_identical(requests[[2]]$body$data$masses, list(200.9, 201))
  expect_error(ct_chemical_msready_search_by_mass_bulk(list(error = 0.5, masses = 201)), "Invalid")
  expect_error(ct_chemical_msready_search_by_mass_bulk(list(error = 5L, masses = numeric())), "Invalid")
  expect_error(ct_chemical_msready_search_by_mass_bulk(list(error = 5L)), "Invalid")
  expect_length(requests, 2)
})
