# Tests for ct_classify
# Custom test - takes a dataframe with chemical compound information


test_that("ct_classify works with valid dataframe input", {
    # Create a sample dataframe with required columns
    df_example <- tibble::tibble(
        molFormula = c("C6H6", "C7H8"),
        preferredName = c("Benzene", "Toluene"),
        dtxsid = c("DTXSID7020182", "DTXSID5032381"),
        smiles = c("c1ccccc1", "Cc1ccccc1"),
        isMarkush = c(FALSE, FALSE),
        isotope = c(0L, 0L),
        multicomponent = c(0L, 0L)
    )
    
    result <- ct_classify(df = df_example)
    
    # Check return type
    expect_s3_class(result, "tbl_df")
    expect_true(ncol(result) > 0)
    
    # Should have classification columns
    expect_true("class" %in% colnames(result) || "super_class" %in% colnames(result))
})

test_that("ct_classify adds classification columns", {
    df_example <- tibble::tibble(
        molFormula = c("C6H6"),
        preferredName = c("Benzene"),
        dtxsid = c("DTXSID7020182"),
        smiles = c("c1ccccc1"),
        isMarkush = c(FALSE),
        isotope = c(0L),
        multicomponent = c(0L)
    )
    
    result <- ct_classify(df = df_example)
    
    # Should have more columns than input
    expect_true(ncol(result) > ncol(df_example))
})
