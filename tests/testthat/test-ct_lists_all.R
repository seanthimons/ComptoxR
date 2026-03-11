# Tests for ct_lists_all (updated for Phase 28 migration)
# ct_lists_all() wrapper removed - now calls ct_chemical_list_all() via transform hook

test_that("ct_chemical_list_all works with default projection", {
  vcr::use_cassette("ct_lists_all_single", {
    result <- ct_chemical_list_all(projection = "chemicallistall")
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_chemical_list_all works with dtxsids projection", {
  vcr::use_cassette("ct_lists_all_with_dtxsids", {
    result <- ct_chemical_list_all(projection = "chemicallistwithdtxsids")
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_chemical_list_all handles invalid projection", {
  expect_error(ct_chemical_list_all(projection = "invalid"))
})
