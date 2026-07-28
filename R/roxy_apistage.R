# Custom `@apiStage` roxygen2 tag
#
# Records the deployment stage (public / staging / development) of the API schema
# a generated wrapper was built from, and renders it as its own section in the
# rendered `.Rd` help page. Generated stubs emit `#' @apiStage <stage>` (see
# dev/endpoint_eval/07_stub_generation.R); this file teaches roxygen2 how to parse
# and render that tag.
#
# The S3 methods below are registered against roxygen2 generics in .onLoad() via
# rlang::s3_register(), so they only become active when roxygen2 is loaded (i.e.
# during devtools::document()). ComptoxR therefore gains no hard dependency on
# roxygen2 at load or run time.

roxy_tag_parse.roxy_tag_apiStage <- function(x) {
  roxygen2::tag_value(x)
}

roxy_tag_rd.roxy_tag_apiStage <- function(x, base_path, env) {
  roxygen2::rd_section("apiStage", x$val)
}

format.rd_section_apiStage <- function(x, ...) {
  stage <- utils::tail(x$value, 1)
  paste0(
    "\\section{API stage}{\n",
    "  This wrapper was generated from the \\strong{",
    stage,
    "} API schema.\n",
    "}\n"
  )
}
