test_that("reviewed HTTP failures stop once and preserve empty results across requests", {
  withr::local_envvar(ctx_api_key = "local-failure-key", batch_limit = "1")
  routes <- c(
    ct_chemical_detail_search_by_dtxsid_bulk = "chemical/detail/search/by-dtxsid/",
    ct_chemical_detail_search_by_dtxcid = "chemical/detail/search/by-dtxcid/",
    ct_chemical_detail_search_by_dtxcid_bulk = "chemical/detail/search/by-dtxcid/",
    chemi_classyfire = "amos/get_classification_for_dtxsid/",
    ct_chemical_search_equal_bulk = "chemical/search/equal/",
    chemi_amos_get_info_by_id = "amos/get_info_by_id/"
  )
  for (status in c(404L, 500L)) local({
    local_mocked_bindings(req_perform = function(req, ...) {
      httr2::response(status_code = status,
        headers = list(`Content-Type` = "application/json"),
        body = charToRaw('{"error":"not found"}'))
    }, .package = "httr2")
    for (name in names(routes)) {
      fn <- get(name, asNamespace("ComptoxR"))
      expect_error(fn("bad"), paste("HTTP", status), info = name)
      warnings <- character()
      result <- withCallingHandlers(fn(c("bad", "bad2")), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
      endpoint <- routes[[name]]
      expected <- vapply(c("bad", "bad2"), function(label) cli::format_warning(
        "API request to {.val {endpoint}} failed for {.val {label}} with status {status}"
      ), "")
      expect_identical(warnings, unname(expected), info = name)
      empty <- if (name == "chemi_amos_get_info_by_id")
        list(NULL, NULL) else tibble::tibble()
      expect_identical(result, empty, info = name)
    }
  })
})

test_that("a dropped failed item preserves the successful table rows", {
  local_mocked_bindings(req_perform = function(req, ...) {
    failed <- endsWith(req$url, "/bad")
    httr2::response(status_code = if (failed) 404L else 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw(if (failed) '{"error":"not found"}' else '{"kingdom":"Organic"}'))
  }, .package = "httr2")
  expect_warning(result <- chemi_classyfire(c("good", "bad")), "failed")
  expect_identical(result, tibble::tibble(dtxsid = "good", kingdom = "Organic"))
})

test_that("transport errors follow effective request count and credentials stay hard", {
  withr::local_envvar(ctx_api_key = "local-failure-key", batch_limit = "2")
  local_mocked_bindings(req_perform = function(...) stop("transport sentinel"), .package = "httr2")
  expect_error(ct_chemical_detail_search_by_dtxsid_bulk(c("one", "two")), "HTTP request failed")
  withr::local_envvar(batch_limit = "1")
  expect_no_warning(expect_identical(ct_chemical_detail_search_by_dtxsid_bulk(c("one", "two")),
                                    tibble::tibble()))
  local_mocked_bindings(req_perform = function(...) httr2::response(status_code = 401L,
    headers = list(`Content-Type` = "application/json"), body = charToRaw('{}')),
    .package = "httr2")
  for (ids in list("one", c("one", "two"))) {
    expect_error(chemi_classyfire(ids), class = "specmill_call_error")
    expect_error(ct_chemical_search_equal_bulk(ids), class = "specmill_call_error")
  }
})

test_that("list facades retain successful attribution and missing input positions", {
  local_mocked_bindings(req_perform = function(req, ...) {
    httr2::response(status_code = if (endsWith(req$url, "/bad")) 404L else 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"kingdom":"Organic"}'))
  }, .package = "httr2")
  expected <- list(structure(list(kingdom = "Organic"), query = "good"), NULL)
  for (fn in list(chemi_amos_get_info_by_id)) {
    expect_warning(result <- fn(c("good", "bad")), "failed")
    expect_identical(result, expected)
  }
})
