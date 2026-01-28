# Tests for chemi_amos_mass_spectra_for_substances
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_mass_spectra_for_substances works without parameters", {
    vcr::use_cassette("chemi_amos_mass_spectra_for_substances_basic", {
        result <- chemi_amos_mass_spectra_for_substances()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_mass_spectra_for_substances works with documented example", 
    {
        vcr::use_cassette("chemi_amos_mass_spectra_for_substances_example", {
            result <- chemi_amos_mass_spectra_for_substances()
            expect_true(!is.null(result))
        })
    })
