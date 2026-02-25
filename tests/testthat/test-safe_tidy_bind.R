test_that("safe_tidy_bind returns empty tibble for empty list", {
  res <- safe_tidy_bind(list())
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0)
})

test_that("safe_tidy_bind handles all-NULL records", {
  res <- safe_tidy_bind(list(NULL, NULL, NULL))
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0)
})

test_that("safe_tidy_bind handles uniform records", {
  input <- list(
    list(a = 1L, b = "hello"),
    list(a = 2L, b = "world")
  )
  res <- safe_tidy_bind(input)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 2)
  expect_equal(res$a, c(1L, 2L))
  expect_equal(res$b, c("hello", "world"))
})

test_that("safe_tidy_bind handles mixed types in same field", {
  # year_published is integer in one record, character in another
  input <- list(
    list(id = "A", year = 2020L),
    list(id = "B", year = "2020-2021")
  )
  res <- safe_tidy_bind(input)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 2)

  # Both should be character since "2020-2021" can't be integer
  expect_type(res$year, "character")
  expect_equal(res$year, c("2020", "2020-2021"))
})

test_that("safe_tidy_bind recovers numeric types", {
  input <- list(
    list(name = "alpha", weight = 100.5),
    list(name = "beta", weight = 200.3)
  )
  res <- safe_tidy_bind(input)
  expect_type(res$weight, "double")
  expect_equal(res$weight, c(100.5, 200.3))
})

test_that("safe_tidy_bind recovers integer types", {
  input <- list(
    list(name = "a", count = 1L),
    list(name = "b", count = 2L)
  )
  res <- safe_tidy_bind(input)
  expect_type(res$count, "integer")
})

test_that("safe_tidy_bind recovers logical types", {
  input <- list(
    list(id = 1, active = TRUE),
    list(id = 2, active = FALSE)
  )
  res <- safe_tidy_bind(input)
  expect_type(res$active, "logical")
})

test_that("safe_tidy_bind handles NULL fields within records", {
  input <- list(
    list(a = 1, b = "x"),
    list(a = 2, b = NULL)
  )
  res <- safe_tidy_bind(input)
  expect_equal(nrow(res), 2)
  expect_true(is.na(res$b[2]))
})

test_that("safe_tidy_bind handles nested lists as list-columns", {
  input <- list(
    list(id = "A", tags = list("x", "y")),
    list(id = "B", tags = list("z"))
  )
  res <- safe_tidy_bind(input)
  expect_s3_class(res, "tbl_df")
  expect_true(is.list(res$tags))
  expect_equal(res$tags[[1]], list("x", "y"))
  expect_equal(res$tags[[2]], list("z"))
})

test_that("safe_tidy_bind handles primitive (non-list) values", {
  input <- list("foo", "bar", "baz")
  res <- safe_tidy_bind(input)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 3)
  expect_true("value" %in% colnames(res))
  expect_equal(res$value, c("foo", "bar", "baz"))
})

test_that("safe_tidy_bind preserves query attributes", {
  rec1 <- list(a = 1, b = "x")
  attr(rec1, "query") <- "DTXSID001"
  rec2 <- list(a = 2, b = "y")
  attr(rec2, "query") <- "DTXSID002"

  res <- safe_tidy_bind(list(rec1, rec2))
  expect_true("query" %in% colnames(res))
  expect_equal(res$query, c("DTXSID001", "DTXSID002"))
})

test_that("safe_tidy_bind handles names_to for named outer list", {
  input <- list(
    group_a = list(id = 1, val = "x"),
    group_b = list(id = 2, val = "y")
  )
  res <- safe_tidy_bind(input, names_to = "group")
  expect_true("group" %in% colnames(res))
  expect_equal(res$group, c("group_a", "group_b"))
})

test_that("safe_tidy_bind respects type_convert = FALSE", {
  input <- list(
    list(a = "123", b = "TRUE")
  )
  res <- safe_tidy_bind(input, type_convert = FALSE)
  expect_type(res$a, "character")
  expect_type(res$b, "character")
  expect_equal(res$a, "123")
  expect_equal(res$b, "TRUE")
})

test_that("safe_tidy_bind handles single record", {
  input <- list(list(x = 42, y = "hello"))
  res <- safe_tidy_bind(input)
  expect_equal(nrow(res), 1)
  expect_equal(res$x, 42L)
  expect_equal(res$y, "hello")
})

test_that("safe_tidy_bind handles records with different columns", {
  input <- list(
    list(a = 1, b = "x"),
    list(a = 2, c = "y")
  )
  res <- safe_tidy_bind(input)
  expect_equal(nrow(res), 2)
  expect_true(all(c("a", "b", "c") %in% colnames(res)))
  expect_true(is.na(res$b[2]))
  expect_true(is.na(res$c[1]))
})

test_that("safe_tidy_bind handles mix of NULL and valid records", {
  input <- list(
    list(a = 1),
    NULL,
    list(a = 3)
  )
  res <- safe_tidy_bind(input)
  expect_equal(nrow(res), 2)
  expect_equal(res$a, c(1L, 3L))
})

test_that("safe_tidy_bind handles field that is list in some rows, scalar in others", {
  # Reproduces: Can't combine `..1$methodologies` <list> and `..93$methodologies` <character>
  input <- list(
    list(id = "A", methodologies = list("method1", "method2")),
    list(id = "B", methodologies = "single_method"),
    list(id = "C", methodologies = NULL)
  )
  res <- safe_tidy_bind(input)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 3)
  # All should be list-column since at least one record has a list value
  expect_true(is.list(res$methodologies))
  expect_equal(res$methodologies[[1]], list("method1", "method2"))
  expect_equal(res$methodologies[[2]], "single_method")
  expect_null(res$methodologies[[3]])
})
