# Tests for ct_chemical_property_predicted
# Active signature: ct_chemical_property_predicted(dtxsid, propName) - GET summary

test_that("ct_chemical_property_predicted works with single input", {
  vcr::use_cassette("ct_chemical_property_predicted_single", {
    result <- ct_chemical_property_predicted(
      dtxsid = "DTXSID7020182",
      propName = "MolWeight"
    )
    expect_type(result, "list")
  })
})
test_that("ct_chemical_property_predicted handles errors gracefully", {
  expect_error(ct_chemical_property_predicted())
})
