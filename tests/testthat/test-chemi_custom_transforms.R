# Original #337 behavior: mock transport; retain current defects without correction.
if (!exists('generated_contract_ensure_package', mode = 'function')) {
  source(file.path('tests', 'testthat', 'helper-generated-contracts.R'))
}
generated_contract_ensure_package()
custom_json_response <- function(body) {
  httr2::response(200L, headers = list('content-type' = 'application/json'), body = charToRaw(body))
}
custom_safety_json <- '{"swr":[{"section":{"Section":[{"TOCHeading":"Hazards","Information":[{"Value":{"StringWithMarkup":[{"String":"Danger","Markup":[{"start":0}]}]}}]}]}}]}'

test_that('ToxPrint keeps ordered NULL options, defaults, falsy values and helper visibility', {
  call <- NULL
  local_mocked_bindings(
    generic_chemi_request = function(...) {
      call <<- list(...)
      invisible(list(score = 0, flag = FALSE))
    },
    run_hook = function(...) stop('no hooks'),
    .package = 'ComptoxR'
  )
  value <- withVisible(chemi_toxprint('one'))
  expect_false(value$visible)
  expect_identical(value$value, list(score = 0, flag = FALSE))
  expect_identical(
    call,
    list(query = 'one', endpoint = 'toxprints/calculate', options = list(OR = 3L, PV1 = .05, TP = 3))
  )
  for (x in list(NULL, FALSE, 0, list(), 'unknown')) {
    chemi_toxprint(x, odds_ratio = x, p_val = x, true_pos = x)
    expect_identical(call, list(query = x, endpoint = 'toxprints/calculate', options = list(OR = x, PV1 = x, TP = x)))
  }
  expect_error(chemi_toxprint(), 'argument "query" is missing', fixed = TRUE)
})

test_that('ToxPrint rejects queries before forcing options and propagates helper failures', {
  for (q in list(NULL, character(), '', NA_character_)) {
    expect_error(
      chemi_toxprint(q, odds_ratio = stop('option evaluated')),
      'Either query or chemicals parameter must be provided.',
      fixed = TRUE
    )
  }
  expect_error(chemi_toxprint(odds_ratio = stop('option evaluated')), 'argument "query" is missing', fixed = TRUE)
  local_mocked_bindings(generic_chemi_request = function(...) stop('transport sentinel'), .package = 'ComptoxR')
  expect_error(chemi_toxprint('one'), 'transport sentinel', fixed = TRUE)
})

test_that('direct wrappers retain request ordering, duplicates, policies and all-failed results', {
  withr::local_envvar(c(chemi_burl = 'http://127.0.0.1:9999/chemi', run_debug = 'FALSE'))
  captured <- NULL
  local_mocked_bindings(
    req_perform_sequential = function(...) {
      captured <<- list(...)
      rep(list(simpleError('failed')), length(captured[[1]]))
    },
    run_hook = function(...) stop('no hooks'),
    .package = 'ComptoxR'
  )
  expect_identical(suppressMessages(chemi_functional_use(c('one', 'one', 'two'))), data.frame())
  expect_identical(names(captured), c('', 'on_error', 'progress'))
  expect_identical(captured$on_error, 'continue')
  expect_true(captured$progress)
  expect_identical(
    vapply(captured[[1]], `[[`, '', 'url'),
    paste0('http://127.0.0.1:9999/chemi/amos/functional_uses_for_dtxsid/', c('one', 'one', 'two'))
  )
  for (req in captured[[1]]) {
    expect_null(req$method)
    expect_null(req$body)
    expect_identical(req$headers, list())
    expect_null(req$policies$retry)
  }
  expect_null(suppressMessages(chemi_safety_section(c('one', 'one'), 'GHS Classification')))
  expect_identical(
    vapply(captured[[1]], `[[`, '', 'url'),
    rep('http://127.0.0.1:9999/chemi/resolver/pubchem-section?query=one&idType=DTXSID&section=GHS%20Classification', 2L)
  )
  expect_identical(captured$on_error, 'continue')
  expect_true(captured$progress)
  for (q in list(FALSE, 0, character())) {
    expect_null(suppressMessages(chemi_safety_section(q, 'GHS Classification')))
    expect_length(captured[[1]], length(q))
  }
  for (q in list('', NA_character_, c('one', 'one'))) {
    expect_identical(suppressMessages(chemi_functional_use(q)), data.frame())
    expect_length(captured[[1]], length(q))
  }
})

test_that('direct wrappers preserve validation order, missing arguments and messages', {
  reached <- FALSE
  local_mocked_bindings(
    req_perform_sequential = function(...) {
      reached <<- TRUE
      stop('transport sentinel')
    },
    .package = 'ComptoxR'
  )
  for (q in list(NULL, character(), FALSE, 0, list())) {
    expect_error(chemi_functional_use(q), 'non-empty character vector')
  }
  expect_error(chemi_functional_use(), 'argument "query" is missing', fixed = TRUE)
  expect_false(reached)
  for (s in list(NULL, FALSE, 0, 'invalid')) {
    expect_error(
      chemi_safety_section(query = stop('query must not be forced'), section = s),
      if (is.null(s)) 'Missing section!' else 'Improper section request!',
      fixed = TRUE
    )
  }
  expect_error(chemi_safety_section(), 'Missing section!', fixed = TRUE)
  expect_error(chemi_safety_section(section = 'GHS Classification'), 'argument "query" is missing', fixed = TRUE)
  expect_error(chemi_safety_section(NULL, 'GHS Classification'), 'Request missing', fixed = TRUE)
  expect_error(chemi_safety_section('one', character()), 'argument is of length zero')
  expect_false(reached)
  withr::local_envvar(c(chemi_burl = 'http://127.0.0.1:9999/chemi', run_debug = 'FALSE'))
  expect_message(expect_error(chemi_functional_use('one'), 'transport sentinel'), 'Functional Use options')
  expect_message(
    expect_error(chemi_safety_section('one', 'GHS Classification'), 'transport sentinel'),
    'Safety section payload options'
  )
})

test_that('functional-use debug returns the first dry run; safety ignores debug mode', {
  settings <- get('.ComptoxREnv', asNamespace('ComptoxR'))
  rlang::local_bindings(run_debug = TRUE, .env = settings)
  withr::local_envvar(c(chemi_burl = 'http://127.0.0.1:9999/chemi', run_debug = 'TRUE'))
  request <- NULL
  local_mocked_bindings(
    req_dry_run = function(req) {
      request <<- req
      list(dry = TRUE)
    },
    req_perform_sequential = function(...) stop('transport still runs'),
    .package = 'ComptoxR'
  )
  expect_identical(suppressMessages(chemi_functional_use(c('one', 'two'))), list(dry = TRUE))
  expect_match(request$url, '/one$', fixed = FALSE)
  expect_error(
    suppressMessages(chemi_safety_section('one', 'GHS Classification')),
    'transport still runs',
    fixed = TRUE
  )
})

test_that('real JSON retains current functional-use and safety aggregation errors', {
  withr::local_envvar(c(chemi_burl = 'http://127.0.0.1:9999/chemi', run_debug = 'FALSE'))
  body <- '[{"functionalClass":"solvent"}]'
  local_mocked_bindings(
    req_perform_sequential = function(reqs, ...) rep(list(custom_json_response(body)), length(reqs)),
    .package = 'ComptoxR'
  )
  expect_error(suppressMessages(chemi_functional_use('one')), 'is.data.frame(x) is not TRUE', fixed = TRUE)
  body <- custom_safety_json
  expect_error(
    suppressMessages(chemi_safety_section('one', 'GHS Classification')),
    "Can't merge the outer name",
    fixed = TRUE
  )
})

test_that('latent transformations retain named aggregation, sections and falsy data with mocked utilities', {
  # Supply unavailable collaborators only in a copy of the original closure.
  # This deliberately does not add bindings to the client namespace.
  withr::local_envvar(c(chemi_burl = 'http://127.0.0.1:9999/chemi', run_debug = 'FALSE'))
  env <- new.env(parent = asNamespace('ComptoxR'))
  response <- custom_json_response(custom_safety_json)
  env$req_perform_sequential <- function(reqs, ...) rep(list(response), length(reqs))
  env$resps_data <- function(resps, resp_data) lapply(resps, resp_data)
  env$list_c <- function(x) purrr::list_c(as.list(x))
  env$keep_at <- purrr::keep_at
  env$discard_at <- purrr::discard_at
  fun <- ComptoxR::chemi_safety_section
  environment(fun) <- env
  result <- suppressMessages(fun(c('one', 'one'), 'GHS Classification'))
  expect_identical(names(result), c('one', 'one'))
  expect_identical(names(result[[1]]), 'Hazards')
  expect_identical(result[[1]]$Hazards, list(String = 'Danger'))
  for (value in list(FALSE, 0)) {
    env$resp_body_json <- function(...) list(swr = list(list(section = list(Section = list(
      list(TOCHeading = 'Hazards', Information = list(list(Value = list(StringWithMarkup = list(list(Flag = value, Markup = list(start = 0)))))))
    )))))
    expect_identical(suppressMessages(fun('one', 'GHS Classification'))[[1]]$Hazards, list(Flag = value))
  }
  env$resp_body_json <- function(...) data.frame(functionalClass = c('solvent', 'intermediate'))
  fun <- ComptoxR::chemi_functional_use
  environment(fun) <- env
  expect_identical(
    suppressMessages(fun(c('one', 'two'))),
    tibble::tibble(dtxsid = rep(c('one', 'two'), each = 2), functional_classes = rep(c('solvent', 'intermediate'), 2))
  )
  for (value in list(FALSE, 0)) {
    env$resp_body_json <- function(...) data.frame(functionalClass = value)
    expect_identical(suppressMessages(fun('one'))$functional_classes, value)
  }
})
