# Tests for ct_bioactivity_data
# Active signature: ct_bioactivity_data(dtxsid) - single GET by DTXSID

test_that("ct_bioactivity_data works with single input", {
  vcr::use_cassette("ct_bioactivity_data_single", {
    result <- ct_bioactivity_data(dtxsid = "DTXSID7020182")
    expect_type(result, "list")
  })
})
test_that("ct_bioactivity_data handles errors gracefully", {
  expect_error(ct_bioactivity_data())
})
