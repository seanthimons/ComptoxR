# Tests for ct_chemical_file_image
# Generated using metadata-based test generator
# Return type: image
# Returns image data (raw bytes or magick image object)


test_that("ct_chemical_file_image works with single input", {
    vcr::use_cassette("ct_chemical_file_image_single", {
        result <- ct_chemical_file_image(dtxsid = "DTXSID7020182")
        {
            expect_true(inherits(result, "magick-image") || is.raw(result) || is.character(result))
        }
    })
})

test_that("ct_chemical_file_image works with documented example", {
    vcr::use_cassette("ct_chemical_file_image_example", {
        result <- ct_chemical_file_image(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_chemical_file_image handles batch requests", {
    vcr::use_cassette("ct_chemical_file_image_batch", {
        result <- ct_chemical_file_image(dtxsid = c("DTXSID7020182", "DTXSID5032381"
        ))
        {
            expect_true(inherits(result, "magick-image") || is.raw(result) || is.character(result))
        }
    })
})

test_that("ct_chemical_file_image handles invalid input gracefully", {
    vcr::use_cassette("ct_chemical_file_image_error", {
        result <- suppressWarnings(ct_chemical_file_image(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
