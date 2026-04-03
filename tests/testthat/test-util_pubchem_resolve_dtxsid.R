test_that("util_pubchem_resolve_dtxsid finds DTXSID for aspirin", {
  vcr::use_cassette("pubchem_resolve_dtxsid_2244", {
    result <- util_pubchem_resolve_dtxsid(2244, cache = FALSE)
  })
  expect_type(result, "character")
  expect_named(result, "2244")
  expect_match(result[["2244"]], "^DTXSID")
})

test_that("util_pubchem_resolve_dtxsid returns named vector for multiple CIDs", {
  vcr::use_cassette("pubchem_resolve_dtxsid_multi", {
    result <- util_pubchem_resolve_dtxsid(c(2244, 6623), cache = FALSE)
  })
  expect_type(result, "character")
  expect_length(result, 2)
  expect_named(result, c("2244", "6623"))
})

test_that("CAS validation uses existing is_cas() function", {
  # Valid CAS numbers
  expect_true(is_cas("50-78-2"))     # aspirin
  expect_true(is_cas("80-05-7"))     # BPA
  expect_true(is_cas("7732-18-5"))   # water

  # Invalid check digits
  expect_false(is_cas("50-78-3"))
  expect_false(is_cas("80-05-8"))

  # Malformed
  expect_false(is_cas("not-a-cas"))
  expect_false(is_cas("12345"))
})

test_that("util_pubchem_resolve_dtxsid returns NA for unresolvable CID", {
  vcr::use_cassette("pubchem_resolve_dtxsid_unresolvable", {
    expect_warning(
      result <- util_pubchem_resolve_dtxsid(999999999, cache = FALSE),
      "could not be resolved|PubChem"
    )
  })
  expect_true(is.na(result[[1]]))
})

test_that("session cache works for repeated calls", {
  # First call populates cache
  vcr::use_cassette("pubchem_resolve_dtxsid_cache_warmup", {
    result1 <- util_pubchem_resolve_dtxsid(2244, cache = TRUE)
  })

  # Second call should hit cache (no HTTP request needed)
  result2 <- util_pubchem_resolve_dtxsid(2244, cache = TRUE)
  expect_equal(result1, result2)

  # Clean up session cache
  if (exists("pubchem_cid_map", envir = .ComptoxREnv)) {
    rm("pubchem_cid_map", envir = .ComptoxREnv)
  }
})

test_that("util_pubchem_resolve_dtxsid rejects empty input", {
  expect_error(util_pubchem_resolve_dtxsid(integer(0)))
})
