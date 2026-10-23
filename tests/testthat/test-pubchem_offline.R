# Public validation remains independent of native transport.
test_that("pubchem_properties aborts on invalid (path-injection) property name",
    {
        expect_error(ComptoxR::pubchem_properties(2244L, properties = c("XLogP",
            "../etc/passwd")), "Invalid PubChem property")
    })
test_that("pubchem_properties aborts when no valid integer CID remains",
    {
        expect_error(ComptoxR::pubchem_properties(NA_integer_,
            cache = FALSE), "at least one valid integer CID")
        expect_error(suppressWarnings(ComptoxR::pubchem_properties(c("foo",
            "bar"), cache = FALSE)), "at least one valid integer CID")
    })
test_that("pubchem_search aborts on non-character or empty query",
    {
        expect_error(ComptoxR::pubchem_search(123, cache = FALSE),
            "single non-empty character")
        expect_error(ComptoxR::pubchem_search("", cache = FALSE),
            "single non-empty character")
        expect_error(ComptoxR::pubchem_search(character(0), cache = FALSE),
            "single non-empty character")
    })
