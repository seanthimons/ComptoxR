# Tests for ct_related
# Generated using metadata-based test generator
# Return type: list
# A list of data frames containing related substances.


test_that("ct_related works with single input", {
    vcr::use_cassette("ct_related_single", {
        result <- ct_related(query = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("ct_related works with documented example", {
    vcr::use_cassette("ct_related_example", {
        result <- ct_related(query = "DTXSID0024842")
        expect_true(!is.null(result))
    })
})

test_that("ct_related handles invalid input gracefully", {
    vcr::use_cassette("ct_related_error", {
        result <- suppressWarnings(ct_related(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) ==
            0) || (is.character(result) && length(result) == 0) || (is.list(result) &&
            length(result) == 0))
    })
})

test_that("ct_related restores server URL after execution", {
    # Save original server
    original_server <- Sys.getenv("ctx_burl")

    # Run ct_related (uses cassette from single test)
    vcr::use_cassette("ct_related_single", {
        result <- ct_related(query = "DTXSID7020182")
    })

    # Verify server was restored
    expect_equal(Sys.getenv("ctx_burl"), original_server)
})

test_that("ct_related validates empty query", {
    expect_error(
        ct_related(query = character(0)),
        "Query must be a character vector of DTXSIDs"
    )
})

test_that("ct_related validates inclusive with single query", {
    expect_error(
        ct_related(query = "DTXSID7020182", inclusive = TRUE),
        "Inclusive option only valid for multiple compounds"
    )
})
