# Tests for ct_properties
# Custom test - requires search_param and query parameters


test_that("ct_properties works with compound search", {
    vcr::use_cassette("ct_properties_compound", {
        result <- ct_properties(search_param = "compound", query = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(length(result) > 0)
        }
    })
})

test_that("ct_properties handles batch compound requests", {
    vcr::use_cassette("ct_properties_batch", {
        result <- ct_properties(search_param = "compound", query = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_type(result, "list")
        expect_true(length(result) > 0)
    })
})

test_that("ct_properties requires search_param", {
    expect_error(ct_properties(query = "DTXSID7020182"),
        "Missing search type"
    )
})
