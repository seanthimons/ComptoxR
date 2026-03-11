# Tests for property name endpoints
# Tests migrated from test-ct_prop.R after ct_properties deletion

test_that("ct_chemical_property_experimental_name returns tibble", {
  vcr::use_cassette("ct_chemical_property_experimental_name_basic", {
    result <- ct_chemical_property_experimental_name()
    expect_s3_class(result, "data.frame")
    expect_true(nrow(result) > 0)
    expect_true("propertyId" %in% names(result) || "name" %in% names(result))
  })
})

test_that("ct_chemical_property_predicted_name returns tibble", {
  vcr::use_cassette("ct_chemical_property_predicted_name_basic", {
    result <- ct_chemical_property_predicted_name()
    expect_s3_class(result, "data.frame")
    expect_true(nrow(result) > 0)
    expect_true("propertyId" %in% names(result) || "name" %in% names(result))
  })
})
