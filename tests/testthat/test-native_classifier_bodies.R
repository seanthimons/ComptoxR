test_that("native classifier bodies preserve identifier normalization and options", {
  captured <- NULL
  testthat::local_mocked_bindings(.ct_request = function(...) {
    captured <<- list(...)
    list(result = "unchanged")
  }, .package = "ComptoxR")
  names <- c("chemi_amnb_nate_bulk", "chemi_arn_cats_bulk", "chemi_ncc_cats_bulk",
    "chemi_pfas_atlas_bulk", "chemi_pfas_cats_bulk")
  records <- list(list(sid = "one"), list(sid = "two"))
  for (name in names) {
    fun <- getExportedValue("ComptoxR", name)
    expect_identical(fun(chemicals = c("one", "two", "one", "", NA_character_)),
      list(result = "unchanged"))
    if (name == "chemi_ncc_cats_bulk") {
      expect_identical(captured$body, records)
    } else {
      expect_identical(captured$body$chemicals, records)
      expect_identical(captured$body$options,
        if (name == "chemi_arn_cats_bulk") list(model = "RF") else structure(list(), names = character()))
    }
    for (empty in list(NULL, character(), c("", NA_character_))) {
      captured <- NULL
      expect_error(fun(chemicals = empty), "Either query or chemicals parameter must be provided.", fixed = TRUE)
      expect_null(captured)
    }
  }
  chemi_arn_cats_bulk(chemicals = FALSE, model = NULL, smiles = 0)
  expect_identical(captured$body, list(chemicals = list(list(sid = FALSE)), options = list(smiles = 0)))
  chemi_pfas_cats_bulk(chemicals = 0, smiles = list(flag = FALSE, missing = NULL))
  expect_identical(captured$body,
    list(chemicals = list(list(sid = 0)), options = list(smiles = list(flag = FALSE, missing = NULL))))
})
