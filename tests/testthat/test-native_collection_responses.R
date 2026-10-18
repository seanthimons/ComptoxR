collection_wrappers <- c("ct_chemical_file_image_search",
  "ct_chemical_file_image_search_by_dtxcid", "ct_chemical_file_image_search_by_gsid",
  "chemi_amos_get_info_by_id", "chemi_alerts_groups_by_id")

test_that("file and list projections preserve the real sequential executor's contracts", {
  withr::local_envvar(ctx_api_key = "local-collection-key")
  fixture <- readRDS(test_path("fixtures/native-collection-responses.rds"))
  expect_setequal(names(fixture$legacy), collection_wrappers)
  canonical <- function(x) {
    if (inherits(x, "magick-image")) return(list(attributes = attributes(x),
      info = as.data.frame(magick::image_info(x)), pixels = magick::image_data(x)))
    if (is.list(x)) {
      attrs <- attributes(x)
      x <- lapply(x, canonical)
      attributes(x) <- attrs
    }
    x
  }
  for (name in collection_wrappers) for (media in fixture$media)
    for (kind in c("success", "http", "transport"))
      for (ids in list("one", "bad", c("one", "bad"), c("bad", "two"))) local({
        wire <- list()
        # Keep httr2's real sequential executor: it returns unnamed responses.
        local_mocked_bindings(req_perform = function(req, ...) {
          key <- req$headers[["x-api-key"]]
          if (rlang::is_weakref(key)) key <- rlang::wref_value(key)
          wire[[length(wire) + 1L]] <<- list(method = req$method, url = req$url,
            accept = req$headers$Accept, body = req$body$data, key = key)
          bad <- startsWith(tail(strsplit(httr2::url_parse(req$url)$path, "/", fixed = TRUE)[[1L]], 1L), "bad")
          if (bad && kind == "transport")
            rlang::abort("transport sentinel", class = "httr2_error", resp = NULL)
          status <- if (bad && kind == "http") 500L else 200L
          response <- httr2::response(status_code = status,
            headers = list(`Content-Type` = media$type), body = media$body)
          policy <- req$policies$error_is_error
          if (status >= 400L && (is.null(policy) || isTRUE(policy(response))))
            rlang::abort("HTTP failure", class = c("httr2_http", "httr2_error"), resp = response)
          response
        }, .package = "httr2")
        invoke <- function(fn) {
          wire <<- list()
          warnings <- character()
          value <- withCallingHandlers(tryCatch(suppressMessages(fn(ids)), error = identity),
            warning = function(w) {
              warnings <<- c(warnings, conditionMessage(w))
              invokeRestart("muffleWarning")
            })
          list(error = inherits(value, "error"), final_error_class = if (inherits(value, "error") && kind == "success") class(value),
            value = if (inherits(value, "error")) NULL else canonical(value),
            warnings = warnings, wire = wire)
        }
        old <- eval(fixture$legacy[[name]][[3L]], asNamespace("ComptoxR"))
        expect_identical(invoke(get(name, asNamespace("ComptoxR"))), invoke(old),
                         info = paste(name, media$type, kind, paste(ids, collapse = ",")))
      })
})

test_that("collection credential failures stay hard before final formatting", {
  withr::local_envvar(ctx_api_key = "local-collection-key")
  local_mocked_bindings(req_perform = function(...) httr2::response(status_code = 401L,
    headers = list(`Content-Type` = "application/json"), body = charToRaw('{}')),
    .package = "httr2")
  for (name in collection_wrappers) for (ids in list("one", c("one", "two"))) {
    warnings <- character()
    result <- withCallingHandlers(tryCatch(get(name, asNamespace("ComptoxR"))(ids), error = identity),
      warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") })
    expect_true(inherits(result, "specmill_call_error"), info = name)
    expect_length(warnings, 0L)
  }
})
