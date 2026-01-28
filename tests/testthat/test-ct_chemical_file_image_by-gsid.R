# Tests for ct_chemical_file_image_by-gsid
# Generated using metadata-based test generator
# Return type: image
# Returns image data (raw bytes or magick image object)


test_that("ct_chemical_file_image_by-gsid works without parameters", {
    vcr::use_cassette("ct_chemical_file_image_by-gsid_basic", {
        result <- `ct_chemical_file_image_by-gsid`()
        {
            expect_true(inherits(result, "magick-image") || is.raw(result) || is.character(result))
        }
    })
})
