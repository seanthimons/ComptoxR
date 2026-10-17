test_that("list-all preserves legacy response shapes and projection/coercion options", {
  withr::local_envvar(ctx_api_key = "local-list-key")
  cases <- readRDS(test_path("fixtures/native-ctx-list-all.rds"))
  for (case in cases) {
    requests <- list()
    warnings <- character()
    local({
      local_mocked_bindings(req_perform = function(req, ...) {
        requests[[length(requests) + 1L]] <<- req
        httr2::response(status_code = 200L,
          headers = list(`Content-Type` = "application/json"), body = charToRaw(case$json))
      }, .package = "httr2")
      result <- withCallingHandlers(suppressMessages(do.call(ct_chemical_list_all, case$args)),
        warning = function(warning) {
          warnings <<- c(warnings, conditionMessage(warning))
          invokeRestart("muffleWarning")
        })
      expect_identical(result, case$result, info = case$json)
      expect_identical(warnings, case$warnings, info = case$json)
      expect_length(requests, 1L)
      expect_identical(requests[[1L]]$url, case$url)
      expect_identical(requests[[1L]]$headers$Accept, "application/json")
      expect_true("x-api-key" %in% names(requests[[1L]]$headers))
    })
  }
})

test_that("list-all preserves early hook skips and partial parameter updates", {
  sentinel <- list(skipped = TRUE)
  local_mocked_bindings(run_hook = function(name, stage, data) {
    if (stage == "pre_request") return(list(skip_request = TRUE, result = sentinel))
    stop("post hook called after skip")
  }, .ct_request = function(...) stop("HTTP called after skip"), .package = "ComptoxR")
  withr::local_envvar(ctx_api_key = NA_character_)
  expect_identical(ct_chemical_list_all(), sentinel)
})

test_that("list-all post hooks receive retained options after a partial update", {
  captured <- NULL
  post_params <- NULL
  local_mocked_bindings(run_hook = function(name, stage, data) {
    if (stage == "pre_request") return(list(params = list(projection = "chemicallistwithdtxsids")))
    post_params <<- data$params
    data$result
  }, .ct_request = function(...) {
    captured <<- list(...)
    tibble::tibble(listName = "A")
  }, .package = "ComptoxR")
  expect_identical(ct_chemical_list_all(coerce = TRUE), tibble::tibble(listName = "A"))
  expect_identical(captured$query$projection, "chemicallistwithdtxsids")
  expect_identical(post_params, list(projection = "chemicallistwithdtxsids",
                                    return_dtxsid = FALSE, coerce = TRUE))
})
