if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

test_that("ct_chemical_list_all maps return_dtxsid to the DTXSID projection before request", {
  captured <- NULL
  local_mocked_bindings(
    generic_request = function(...) {
      captured <<- list(...)
      tibble::tibble(listName = "TEST", dtxsids = "DTXSID1,DTXSID2")
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(ComptoxR::ct_chemical_list_all(return_dtxsid = TRUE))

  expect_s3_class(result, "tbl_df")
  expect_identical(captured$endpoint, "chemical/list/all")
  expect_identical(captured$projection, "chemicallistwithdtxsids")
})

test_that("ct_chemical_list_all keeps explicit projection when return_dtxsid is FALSE", {
  captured <- NULL
  local_mocked_bindings(
    generic_request = function(...) {
      captured <<- list(...)
      tibble::tibble(listName = "TEST")
    },
    .package = "ComptoxR"
  )

  suppressMessages(ComptoxR::ct_chemical_list_all(projection = "chemicallistname"))

  expect_identical(captured$projection, "chemicallistname")
})

test_that("ct_chemical_list_all post hook coerces DTXSID strings when requested", {
  local_mocked_bindings(
    generic_request = function(...) {
      tibble::tibble(
        listName = c("LIST_A", "LIST_B"),
        dtxsids = c("DTXSID1,DTXSID2", "DTXSID3")
      )
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(ComptoxR::ct_chemical_list_all(return_dtxsid = TRUE, coerce = TRUE))

  expect_type(result, "list")
  expect_named(result, c("LIST_A", "LIST_B"))
  expect_identical(result$LIST_A$dtxsids, c("DTXSID1", "DTXSID2"))
  expect_identical(result$LIST_B$dtxsids, "DTXSID3")
})
