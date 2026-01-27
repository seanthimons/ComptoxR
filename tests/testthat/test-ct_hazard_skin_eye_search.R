# Tests for ct_hazard_skin_eye_search and ct_hazard_skin_eye_search_bulk
# Testing JSON body encoding fix for bulk POST requests

test_that("ct_hazard_skin_eye_search returns data for single DTXSID", {
  skip_if(Sys.getenv("ctx_api_key") == "" || Sys.getenv("ctx_api_key") == "dummy_ctx_key",
          "API key not set")

  vcr::use_cassette("ct_hazard_skin_eye_search_single", {
    result <- ct_hazard_skin_eye_search(dtxsid = "DTXSID7020182")

    expect_type(result, "list")
  })
})

test_that("ct_hazard_skin_eye_search_bulk returns data for multiple DTXSIDs", {
  skip_if(Sys.getenv("ctx_api_key") == "" || Sys.getenv("ctx_api_key") == "dummy_ctx_key",
          "API key not set")

  vcr::use_cassette("ct_hazard_skin_eye_search_bulk", {
    result <- ct_hazard_skin_eye_search_bulk(
      query = c("DTXSID7020182", "DTXSID9020112")
    )

    expect_type(result, "list")
    expect_true(length(result) > 0 || nrow(result) > 0)
  })
})

test_that("ct_hazard_skin_eye_search_bulk handles single DTXSID", {
  skip_if(Sys.getenv("ctx_api_key") == "" || Sys.getenv("ctx_api_key") == "dummy_ctx_key",
          "API key not set")

  vcr::use_cassette("ct_hazard_skin_eye_search_bulk_single", {
    result <- ct_hazard_skin_eye_search_bulk(
      query = "DTXSID7020182"
    )

    expect_type(result, "list")
  })
})
