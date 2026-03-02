# Tests for ct_chemical_property_experimental
# Active signature: ct_chemical_property_experimental(dtxsid, propName) - GET summary

test_that("ct_chemical_property_experimental works with single input", {
  vcr::use_cassette("ct_chemical_property_experimental_single", {
    result <- ct_chemical_property_experimental(
      dtxsid = "DTXSID7020182",
      propName = "MolWeight"
    )
    expect_type(result, "list")
  })
})
test_that("ct_chemical_property_experimental handles errors gracefully", {
  expect_error(ct_chemical_property_experimental())
})
