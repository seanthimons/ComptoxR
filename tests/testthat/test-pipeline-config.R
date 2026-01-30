# Test configuration helpers from 00_config.R

describe("%||%", {
  test_that("returns right side for NULL", {
    skip_on_cran()
    source_pipeline_files()
    expect_equal(NULL %||% "default", "default")
    expect_equal(NULL %||% 42, 42)
  })

  test_that("returns right side for single NA", {
    skip_on_cran()
    source_pipeline_files()
    expect_equal(NA %||% "default", "default")
    expect_equal(NA %||% 99, 99)
  })

  test_that("returns left side for non-NULL non-NA values", {
    skip_on_cran()
    source_pipeline_files()
    # 0, FALSE, and empty string are valid values (not NULL/NA)
    expect_equal(0 %||% 10, 0)
    expect_equal(FALSE %||% TRUE, FALSE)
    expect_equal("" %||% "default", "")
    expect_equal("value" %||% "default", "value")
  })

  test_that("handles vectors correctly", {
    skip_on_cran()
    source_pipeline_files()
    # Length > 1 should return left side (not NA)
    expect_equal(c(1, 2, 3) %||% 99, c(1, 2, 3))
    expect_equal(c("a", "b") %||% "default", c("a", "b"))
  })

  test_that("handles NA vector edge case", {
    skip_on_cran()
    source_pipeline_files()
    # NA vector with length > 1 should return left side
    expect_equal(c(NA, NA) %||% "default", c(NA, NA))
  })
})

describe("ensure_cols()", {
  test_that("adds missing columns with scalar defaults", {
    skip_on_cran()
    source_pipeline_files()
    df <- data.frame(a = 1:3)
    result <- ensure_cols(df, list(b = 0, c = "default"))

    expect_true("b" %in% names(result))
    expect_true("c" %in% names(result))
    expect_equal(result$b, c(0, 0, 0))
    expect_equal(result$c, c("default", "default", "default"))
  })

  test_that("adds missing columns with list-column defaults", {
    skip_on_cran()
    source_pipeline_files()
    df <- data.frame(a = 1:3)
    default_list <- list(x = 1, y = 2)
    result <- ensure_cols(df, list(metadata = list(default_list)))

    expect_true("metadata" %in% names(result))
    expect_equal(length(result$metadata), 3)
    # Each row should have the same list structure
    expect_equal(result$metadata[[1]], default_list)
    expect_equal(result$metadata[[2]], default_list)
  })

  test_that("preserves existing columns", {
    skip_on_cran()
    source_pipeline_files()
    df <- data.frame(a = 1:3, b = c("x", "y", "z"))
    result <- ensure_cols(df, list(b = "default", c = 0))

    # Existing column should not be overwritten
    expect_equal(result$b, c("x", "y", "z"))
    # New column should be added
    expect_equal(result$c, c(0, 0, 0))
  })

  test_that("handles empty data frame", {
    skip_on_cran()
    source_pipeline_files()
    df <- data.frame()
    result <- ensure_cols(df, list(a = 1, b = "test"))

    expect_equal(nrow(result), 0)
    expect_true("a" %in% names(result))
    expect_true("b" %in% names(result))
  })

  test_that("handles multiple missing columns at once", {
    skip_on_cran()
    source_pipeline_files()
    df <- data.frame(id = 1:2)
    result <- ensure_cols(df, list(
      name = "unknown",
      count = 0,
      active = TRUE,
      tags = list(character(0))
    ))

    expect_equal(ncol(result), 5)  # id + 4 new columns
    expect_equal(result$name, c("unknown", "unknown"))
    expect_equal(result$count, c(0, 0))
    expect_equal(result$active, c(TRUE, TRUE))
  })
})

describe("CHEMICAL_SCHEMA_PATTERNS", {
  test_that("contains expected patterns", {
    skip_on_cran()
    source_pipeline_files()

    # Should be a character vector with length > 0
    expect_true(is.character(CHEMICAL_SCHEMA_PATTERNS))
    expect_true(length(CHEMICAL_SCHEMA_PATTERNS) > 0)

    # Should include key patterns
    expect_true("#/components/schemas/Chemical" %in% CHEMICAL_SCHEMA_PATTERNS)
    expect_true("#/components/schemas/ChemicalRecord" %in% CHEMICAL_SCHEMA_PATTERNS)
  })

  test_that("each pattern starts with #/components/schemas/", {
    skip_on_cran()
    source_pipeline_files()

    all_start_correctly <- all(grepl("^#/components/schemas/", CHEMICAL_SCHEMA_PATTERNS))
    expect_true(all_start_correctly)
  })
})

describe("ENDPOINT_PATTERNS_TO_EXCLUDE", {
  test_that("contains expected exclusion patterns", {
    skip_on_cran()
    source_pipeline_files()

    # Should be a single regex string
    expect_true(is.character(ENDPOINT_PATTERNS_TO_EXCLUDE))
    expect_equal(length(ENDPOINT_PATTERNS_TO_EXCLUDE), 1)
  })

  test_that("pattern matches expected keywords", {
    skip_on_cran()
    source_pipeline_files()

    # Should match common exclusion keywords
    expect_true(grepl("preflight", ENDPOINT_PATTERNS_TO_EXCLUDE))
    expect_true(grepl("metadata", ENDPOINT_PATTERNS_TO_EXCLUDE))
    expect_true(grepl("version", ENDPOINT_PATTERNS_TO_EXCLUDE))
  })
})
