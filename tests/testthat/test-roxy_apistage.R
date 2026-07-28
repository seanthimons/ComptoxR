# Tests for the custom @apiStage roxygen2 tag (R/roxy_apistage.R).
# The S3 methods are registered against roxygen2 generics in .onLoad(); here we
# confirm a roxygen block carrying @apiStage renders an "API stage" .Rd section.

test_that("@apiStage renders an API stage section in generated Rd", {
  skip_if_not_installed("roxygen2")

  txt <- paste(
    "#' Title",
    "#'",
    "#' @description Desc.",
    "#'",
    "#' @apiStage staging",
    "#' @export",
    "foo <- function() NULL",
    sep = "\n"
  )

  out <- roxygen2::roc_proc_text(roxygen2::rd_roclet(), txt)
  rendered <- format(out[[1]])

  expect_match(rendered, "\\section{API stage}", fixed = TRUE)
  expect_match(rendered, "staging", fixed = TRUE)
})
