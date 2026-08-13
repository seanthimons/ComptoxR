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

#' @exportS3Method base::format
format.rd_section_apiStage <- function(x, ...) {
  stage <- utils::tail(x$value, 1)
  paste0(
    "\\section{API stage}{\n",
    "  This wrapper was generated from the \\strong{",
    stage,
    "} API schema.\n",
    "}"
  )
}

# Vendored copy of rlang::s3_register() (MIT-licensed). Registers an S3 method
# for a generic owned by another package without a hard dependency: it hooks the
# owning package's load event and only registers when that namespace is present.
# Used in .onLoad() to attach the roxy_tag_* / format methods to roxygen2 solely
# during devtools::document(). Vendored because rlang does not export it.
s3_register <- function(generic, class, method = NULL) {
  stopifnot(is.character(generic), length(generic) == 1)
  stopifnot(is.character(class), length(class) == 1)
  pieces <- strsplit(generic, "::")[[1]]
  stopifnot(length(pieces) == 2)
  package <- pieces[[1]]
  generic <- pieces[[2]]
  caller <- parent.frame()
  get_method_env <- function() {
    top <- topenv(caller)
    if (isNamespace(top)) asNamespace(environmentName(top)) else caller
  }
  get_method <- function(method) {
    if (is.null(method)) {
      get(paste0(generic, ".", class), envir = get_method_env())
    } else {
      method
    }
  }
  register <- function(...) {
    envir <- asNamespace(package)
    method_fn <- get_method(method)
    stopifnot(is.function(method_fn))
    if (exists(generic, envir)) {
      registerS3method(generic, class, method_fn, envir = envir)
    }
  }
  setHook(packageEvent(package, "onLoad"), function(...) register())
  if (isNamespaceLoaded(package)) {
    register()
  }
  invisible()
}
