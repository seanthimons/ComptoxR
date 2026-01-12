# Tests for chemi_resolver
# Custom test - chemical name/identifier resolver

test_that("chemi_resolver resolves chemical names to DTXSIDs", {
  vcr::use_cassette("chemi_resolver_names", {
    result <- chemi_resolver(
      c("benzene", "formaldehyde"),
      id_type = "DTXSID"
    )

    # Should return character vector of DTXSIDs
    expect_type(result, "character")
    expect_true(length(result) == 2)

    # DTXSIDs should match pattern
    expect_true(all(grepl("^DTXSID", result)))
  })
})

test_that("chemi_resolver handles single chemical", {
  vcr::use_cassette("chemi_resolver_single", {
    result <- chemi_resolver("benzene", id_type = "DTXSID")

    expect_type(result, "character")
    expect_equal(length(result), 1)
    expect_match(result, "^DTXSID")
  })
})

test_that("chemi_resolver resolves CAS numbers", {
  vcr::use_cassette("chemi_resolver_cas", {
    result <- chemi_resolver("50-00-0", id_type = "DTXSID")

    expect_type(result, "character")
    expect_match(result, "^DTXSID")
  })
})

test_that("chemi_resolver with mol=TRUE returns molecular data", {
  vcr::use_cassette("chemi_resolver_with_mol", {
    result <- chemi_resolver(
      "benzene",
      id_type = "DTXSID",
      mol = TRUE
    )

    # When mol=TRUE, returns more detailed data
    expect_type(result, "list")
  })
})

test_that("chemi_resolver handles unrecognized chemicals", {
  vcr::use_cassette("chemi_resolver_invalid", {
    expect_warning(
      result <- chemi_resolver(
        "NOTAREALCHEMICAL12345",
        id_type = "DTXSID"
      ),
      "failed|error|No results"
    )

    # Should handle gracefully
    expect_true(is.null(result) || length(result) == 0)
  })
})

test_that("chemi_resolver handles batch resolution", {
  vcr::use_cassette("chemi_resolver_batch", {
    chemicals <- c("benzene", "toluene", "xylene", "formaldehyde")
    result <- chemi_resolver(chemicals, id_type = "DTXSID")

    expect_type(result, "character")
    expect_equal(length(result), length(chemicals))
    expect_true(all(grepl("^DTXSID", result)))
  })
})
