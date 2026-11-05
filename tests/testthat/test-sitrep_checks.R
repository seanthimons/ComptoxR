local_sitrep_checks <- function(discover, probe = function(req) 200L, .env = parent.frame()) {
  state <- getFromNamespace(".ComptoxREnv", "ComptoxR")
  old <- state$sitrep_endpoints
  state$sitrep_endpoints <- NULL
  withr::defer(state$sitrep_endpoints <- old, envir = .env)
  response <- function(code, body = '{}') {
    httr2::response(
      status_code = code,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw(body)
    )
  }
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) discover(req),
    req_perform_parallel = function(reqs, ...) {
      lapply(reqs, function(req) {
        code <- probe(req)
        if (is.na(code)) {
          return(NULL)
        }
        response(code)
      })
    },
    .package = "httr2",
    .env = .env
  )
  response
}

test_that("Chemi probes named components even when discovery reports them healthy", {
  response <- local_sitrep_checks(
    discover = function(req) {
      response(200L, '[{"name":"rdkit","is_available":true},{"name":"opera","is_available":true}]')
    },
    probe = function(req) if (grepl("/opera/version$", req$url)) 503L else 200L
  )
  result <- .sitrep_chemi("https://example.invalid/api/")
  expect_identical(result$endpoint_list$status, "OK")
  expect_identical(result$source, "live")
  expect_identical(result$status, "WARNING")
  down <- result$endpoints[result$endpoints$status != "OK", ]
  expect_identical(down$name, "opera")
  expect_identical(down$message, "HTTP 503")
})

test_that("discovery outages use shipped probes and retain the list failure", {
  for (failure in c("http", "connection", "json", "empty", "invalid")) {
    response <- local_sitrep_checks(
      discover = function(req) {
        switch(
          failure,
          http = response(503L),
          connection = stop("timeout with secret URL"),
          json = response(200L, "not json"),
          empty = response(200L, "[]"),
          invalid = response(200L, '[{"name":"../unsafe","is_available":true}]')
        )
      },
      probe = function(req) if (grepl("/rdkit/version$", req$url)) NA_integer_ else 200L
    )
    result <- .sitrep_chemi("https://example.invalid/api")
    expect_identical(result$source, "shipped")
    expect_identical(result$endpoint_list$status, "ERROR")
    expect_match(result$message, "Endpoint list unavailable")
    expect_identical(result$endpoints$name[result$endpoints$status == "ERROR"], "rdkit")
    expect_false(grepl("secret", result$endpoint_list$message))
  }
})

test_that("list outage with healthy components stays a warning", {
  response <- local_sitrep_checks(discover = function(req) response(503L))
  result <- .sitrep_chemi("https://example.invalid/api")
  expect_identical(result$status, "WARNING")
  expect_true(all(result$endpoints$status == "OK"))
  expect_identical(result$endpoint_list$message, "HTTP 503")
})

test_that("last-known discovery is scoped to the server and ignores stale availability", {
  available <- TRUE
  urls <- character()
  response <- local_sitrep_checks(
    discover = function(req) {
      if (available) response(200L, '[{"name":"opera","is_available":false}]') else response(503L)
    },
    probe = function(req) {
      urls <<- c(urls, req$url)
      200L
    }
  )
  first <- .sitrep_chemi("https://first.invalid/api/")
  expect_identical(first$status, "ERROR")
  expect_match(first$endpoints$message, "Reported unavailable")
  available <- FALSE
  urls <- character()
  result <- .sitrep_chemi("https://first.invalid/api")
  expect_identical(result$source, "last-known")
  expect_identical(result$endpoints$name, "opera")
  expect_identical(result$endpoints$status, "OK")
  expect_identical(urls, "https://first.invalid/api/opera/version")
  other <- .sitrep_chemi("https://second.invalid/api")
  expect_identical(other$source, "shipped")
  expect_gt(nrow(other$endpoints), 1L)
})

test_that("unknown components are explicitly unverified without guessed URLs", {
  urls <- character()
  response <- local_sitrep_checks(
    discover = function(req) response(200L, '[{"name":"new_component","is_available":true}]'),
    probe = function(req) {
      urls <<- c(urls, req$url)
      200L
    }
  )
  result <- .sitrep_chemi("https://example.invalid/api")
  expect_identical(result$endpoints$name, "new_component")
  expect_identical(result$endpoints$status, "UNKNOWN")
  expect_length(urls, 0L)
})

test_that("shipped Chemi probes match checked-in schema GET operations", {
  probes <- .sitrep_probes()
  directory <- testthat::test_path("..", "..", "schema")
  skip_if_not(dir.exists(directory), "Schema alignment is checked in the source checkout")
  shipped_names <- sub("_prod.json$", "", sub("^chemi_", "", list.files(directory, pattern = "^chemi_.*_prod[.]json$")))
  expect_setequal(names(probes), shipped_names)
  for (name in names(probes)) {
    schema <- jsonlite::read_json(testthat::test_path("..", "..", "schema", paste0("chemi_", name, "_prod.json")))
    path <- paste0("/api/", probes[[name]])
    if (name == "chet") {
      path <- sub("/api/chet", "", path, fixed = TRUE)
    }
    expect_true("get" %in% names(schema$paths[[path]]), info = name)
  }
})


test_that("authorization failures do not claim the endpoint is down", {
  response <- local_sitrep_checks(discover = function(req) response(503L), probe = function(req) 401L)
  result <- .sitrep_summary("CTX", .sitrep_probe("https://example.invalid/", c(chemical = "chemical/health")))
  expect_identical(result$status, "UNKNOWN")
  expect_identical(result$endpoints$status, "UNKNOWN")
  expect_match(result$endpoints$message, "authentication required")
})

test_that("a total component outage lists every failed component", {
  response <- local_sitrep_checks(discover = function(req) response(503L), probe = function(req) 503L)
  result <- .sitrep_chemi("https://example.invalid/api")
  expect_identical(result$status, "ERROR")
  expect_setequal(result$endpoints$name, names(.sitrep_probes()))
  expect_true(all(result$endpoints$message == "HTTP 503"))
})
