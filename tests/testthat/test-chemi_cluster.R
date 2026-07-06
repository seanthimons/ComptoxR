chemi_cluster_similarity_payload <- function(chemicals) {
  list(
    order = purrr::map(chemicals, ~ list(chemical = .x)),
    similarity = list(
      list(list(value = 1, cl = "same"), list(value = 0.25, cl = "low")),
      list(list(value = 0.25, cl = "low"), list(value = 1, cl = "same"))
    )
  )
}

test_that("chemi_cluster keeps DTXSIDs when all similarity-map records provide sid", {
  captured <- NULL
  payload <- chemi_cluster_similarity_payload(list(
    list(sid = "DTXSID1", name = "Chemical A"),
    list(sid = "DTXSID2", name = "Chemical B")
  ))

  testthat::local_mocked_bindings(
    chemi_resolver_getsimilaritymap = function(...) {
      captured <<- list(...)
      payload
    },
    .package = "ComptoxR"
  )

  result <- suppressMessages(ComptoxR::chemi_cluster(c("DTXSID1", "DTXSID2"), sort = FALSE))

  expect_equal(captured$query, c("DTXSID1", "DTXSID2"))
  expect_equal(captured$idType, "DTXSID")
  expect_false(captured$sort)
  expect_s3_class(result$mol_names, "tbl_df")
  expect_equal(result$mol_names$dtxsid, c("DTXSID1", "DTXSID2"))
  expect_equal(result$mol_names$name, c("Chemical A", "Chemical B"))
  expect_equal(result$similarity, list(c(1, 0.25), c(0.25, 1)))
  expect_s3_class(result$hc, "hclust")
})

test_that("chemi_cluster fills missing DTXSIDs with NA when similarity-map records are mixed", {
  payload <- chemi_cluster_similarity_payload(list(
    list(sid = "DTXSID1", name = "Chemical A"),
    list(name = "Chemical B")
  ))

  testthat::local_mocked_bindings(
    chemi_resolver_getsimilaritymap = function(...) payload,
    .package = "ComptoxR"
  )

  result <- suppressMessages(ComptoxR::chemi_cluster(c("DTXSID1", "missing"), sort = TRUE))

  expect_equal(result$mol_names$dtxsid, c("DTXSID1", NA_character_))
  expect_equal(result$mol_names$name, c("Chemical A", "Chemical B"))
})

test_that("chemi_cluster returns NULL when no chemicals resolve", {
  testthat::local_mocked_bindings(
    chemi_resolver_getsimilaritymap = function(...) NULL,
    .package = "ComptoxR"
  )

  expect_null(suppressMessages(ComptoxR::chemi_cluster("not found")))
})
