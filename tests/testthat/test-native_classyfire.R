test_that("Classyfire retains legacy columns after all requests are combined", {
  withr::local_envvar(ctx_api_key = NA_character_)
  cases <- readRDS(test_path("fixtures/native-classyfire.rds"))
  for (case in cases) {
    requests <- list()
    local({
      local_mocked_bindings(req_perform = function(req, ...) {
        requests[[length(requests) + 1L]] <<- req
        httr2::response(status_code = 200L,
          headers = list(`Content-Type` = "application/json"), body = charToRaw(case$json))
      }, .package = "httr2")
      expect_identical(chemi_classyfire(case$query), case$result, info = case$json)
      expect_identical(vapply(requests, function(req) req$url, ""), case$urls)
      expect_true(all(vapply(requests, function(req) identical(req$headers$Accept,
        "application/json") && !"x-api-key" %in% names(req$headers), logical(1))))
    })
  }
})

test_that("Classyfire formats once and guards empty input before HTTP", {
  count <- 0L
  requests <- 0L
  formatter <- format_classyfire_result
  local_mocked_bindings(format_classyfire_result = function(data) {
    count <<- count + 1L
    formatter(data)
  }, .package = "ComptoxR")
  local_mocked_bindings(req_perform = function(req, ...) {
    requests <<- requests + 1L
    httr2::response(status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"kingdom":"K","klass":"C"}'))
  }, .package = "httr2")
  result <- chemi_classyfire(list("one", "", "two", "one", NA_character_))
  expect_identical(result, tibble::tibble(dtxsid = c("one", "two"), kingdom = c("K", "K"),
                                        class = c("C", "C")))
  expect_identical(count, 1L)
  expect_identical(requests, 2L)
  expect_error(chemi_classyfire(c("", NA_character_)), "Query must be a character vector")
  expect_identical(requests, 2L)
})

test_that("post-combine hook execution returns the result and preserves error context", {
  data <- list(result = tibble::tibble(value = 1L), params = list(query = "one"))
  expect_identical(run_hook("unregistered", "post_combine", data), data$result)
  local_mocked_bindings(format_classyfire_result = function(data) stop("format failed"),
                        .package = "ComptoxR")
  error <- tryCatch(run_hook("chemi_classyfire", "post_combine", data), error = identity)
  expect_s3_class(error, "comptoxr_post_combine_hook_error")
  expect_identical(error$stage, "post_combine")
  expect_identical(error$function_name, "chemi_classyfire")
  expect_identical(conditionMessage(error$parent), "format failed")
})
