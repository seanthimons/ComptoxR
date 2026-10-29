native_pager_names <- c(
  "chemi_amos_analytical_qc_keyset_pagination",
  "chemi_amos_analytical_qc_keyset_pagination_bulk",
  "chemi_amos_fact_sheet_keyset_pagination",
  "chemi_amos_fact_sheet_keyset_pagination_bulk",
  "chemi_amos_method_keyset_pagination",
  "chemi_amos_method_keyset_pagination_bulk",
  "chemi_amos_product_declaration_keyset_pagination",
  "chemi_amos_product_declaration_keyset_pagination_bulk",
  "chemi_amos_safety_data_sheet_keyset_pagination",
  "chemi_amos_safety_data_sheet_keyset_pagination_bulk",
  "chemi_chet_chemicals_counts",
  "chemi_chet_chemicals_database",
  "chemi_chet_reaction_database",
  "chemi_resolver_classyfire"
)

test_that("keyset pagers preserve captured manual and automatic contracts", {
  fixture <- readRDS(test_path("fixtures/native-pagers.rds"))
  cases <- fixture$keyset
  for (case in cases) local({
    requests <- list()
    warnings <- character()
    local_mocked_bindings(req_perform = function(req, ...) {
      requests[[length(requests) + 1L]] <<- req
      httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"),
        body = if (length(requests) == 1L) case$first else case$second)
    }, .package = "httr2")
    value <- withCallingHandlers(do.call(get(case$wrapper, asNamespace("ComptoxR")), case$args),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    wire <- lapply(requests, function(req) list(method = req$method, url = req$url,
      accept = req$headers$Accept, body = req$body$data))
    expect_identical(value, case$result, info = case$wrapper)
    native_warnings <- warnings
    requests <- list()
    warnings <- character()
    old <- eval(fixture$legacy[[case$wrapper]][[3L]], asNamespace("ComptoxR"))
    withCallingHandlers(do.call(old, case$args), warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
    expect_identical(native_warnings, warnings, info = case$wrapper)
    expect_identical(wire, case$wire, info = case$wrapper)
  })
})

test_that("all pagers preserve partial failures and hard client errors", {
  legacy <- readRDS(test_path("fixtures/native-pagers.rds"))$legacy
  ns <- asNamespace("ComptoxR")
  for (name in names(legacy)) local({
    keyset <- grepl("keyset_pagination", name, fixed = TRUE)
    spring <- name == "chemi_resolver_classyfire"
    args <- list(all_pages = TRUE, max_pages = 3L)
    if (keyset) args$limit <- 1L
    calls <- 0L
    status <- 500L
    local_mocked_bindings(req_perform = function(req, ...) {
      calls <<- calls + 1L
      code <- if (calls == 2L) status else 200L
      body <- if (keyset) '{"results":[{"id":1}],"pagination":{"hasNext":true,"nextCursor":"two"}}'
        else if (spring) '{"content":[{"id":1}],"last":false}' else '{"data":[{"id":1}]}'
      response <- httr2::response(status_code = code,
        headers = list(`Content-Type` = "application/json"), body = charToRaw(body))
      policy <- req$policies$error_is_error
      if (code >= 400L && (is.null(policy) || isTRUE(policy(response))))
        rlang::abort("HTTP failure", class = c("httr2_http", "httr2_error"), resp = response)
      response
    }, .package = "httr2")
    invoke <- function(fn) {
      calls <<- 0L
      warnings <- character()
      value <- withCallingHandlers(tryCatch(do.call(fn, args), error = identity), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
      list(value = value, warnings = warnings, calls = calls)
    }
    old <- eval(legacy[[name]][[3L]], ns)
    native <- get(name, ns)
    expect_identical(invoke(native), invoke(old), info = name)
    status <- 401L
    result <- invoke(native)
    expect_true(inherits(result$value, "specmill_call_error"), info = name)
  })
})

test_that("GET and POST keysets continue after an empty nonterminal page", {
  for (fn in list(chemi_amos_method_keyset_pagination, chemi_amos_method_keyset_pagination_bulk)) local({
    calls <- 0L
    local_mocked_bindings(req_perform = function(req, ...) {
      calls <<- calls + 1L
      httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"),
        body = charToRaw(if (calls == 1L)
          '{"results":[],"pagination":{"hasNext":true,"nextCursor":"two"}}'
          else '{"results":[{"id":"found"}],"pagination":{"hasNext":false}}'))
    }, .package = "httr2")
    expect_identical(fn(1L, max_pages = 3L), list(list(id = "found")))
    expect_identical(calls, 2L)
  })
})

test_that("pager signatures retain cursor and manual-control defaults", {
  legacy <- readRDS(test_path("fixtures/native-pagers.rds"))$legacy
  expect_setequal(names(legacy), native_pager_names)
  ns <- asNamespace("ComptoxR")
  for (name in names(legacy)) {
    old <- formals(eval(legacy[[name]][[3L]], ns))
    current <- formals(get(name, ns))
    expect_identical(names(current), names(old), info = name)
    for (field in setdiff(names(old), "max_pages"))
      expect_equal(current[field], old[field], info = paste(name, field))
    expect_equal(current$max_pages, old$max_pages, info = name)
    if (grepl("keyset_pagination", name, fixed = TRUE))
      expect_identical(current$cursor, if (endsWith(name, "_bulk")) "" else NULL, info = name)
  }
})
