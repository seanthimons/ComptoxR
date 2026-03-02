# Tests for ct_chemical_fate
# Active signature: ct_chemical_fate(dtxsid) - single GET by DTXSID

test_that("ct_chemical_fate works with single input", {
  vcr::use_cassette("ct_chemical_fate_single", {
    result <- ct_chemical_fate(dtxsid = "DTXSID7020182")
    expect_type(result, "list")
  })
})
test_that("ct_chemical_fate handles errors gracefully", {
  expect_error(ct_chemical_fate())
})
