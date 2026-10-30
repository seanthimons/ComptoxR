# Frozen public functions are the oracle; native calls still use the real executor.
static_media_legacy <- function(name) {
  fixture <- readRDS(test_path('fixtures/native-static-media-contracts.rds'))
  eval(fixture[[name]][[3L]], asNamespace('ComptoxR'))
}
static_media_capture <- function(fn, args) {
  warnings <- character()
  value <- withCallingHandlers(tryCatch(suppressMessages(do.call(fn, args)), error = identity),
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning') })
  canonical <- function(x) {
    if (inherits(x, 'magick-image')) return(list(info = as.data.frame(magick::image_info(x)), pixels = magick::image_data(x)))
    if (is.list(x)) { a <- attributes(x); x <- lapply(x, canonical); attributes(x) <- a }
    x
  }
  list(value = if (!inherits(value, 'error')) canonical(value),
    error = if (inherits(value, 'error')) list(class = class(value), location = value$location, parent = class(value$parent)),
    warnings = warnings)
}

test_that('static GET projections preserve records, empty values and parse conditions', {
  requests <- list(); payload <- NULL
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- list(url = req$url, accept = req$headers$Accept)
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'), body = charToRaw(payload))
  }, .package = 'httr2')
  for (name in c('chemi_resolver_safety_flags', 'chemi_resolver_pubchem_section', 'chemi_toxprints_calculate')) {
    old <- static_media_legacy(name); native <- get(name, asNamespace('ComptoxR'))
    expect_identical(formals(native), formals(old))
    for (payload in c('{"value":1}', '[{"value":1}]', '[]', 'null', '{', '{"value":null}')) {
      for (args in list(list('one'), list('one', NULL), list(NULL))) {
        requests <- list(); a <- static_media_capture(old, args); old_wire <- requests
        requests <- list(); b <- static_media_capture(native, args)
        expect_identical(b, a, info = name)
        expect_identical(requests, old_wire, info = name)
      }
    }
    requests <- list()
    expect_error(native(c('one', 'two')))
    expect_length(requests, 0L)
  }
})

test_that('ChET image requests preserve media handling and public input behavior', {
  content <- NULL; requests <- list()
  png <- magick::image_write(magick::image_blank(1L, 1L, color = 'white'), format = 'png')
  media <- list(list(type = 'image/png', body = png),
    list(type = 'image/svg+xml', body = charToRaw('<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>')),
    list(type = 'application/pdf', body = charToRaw('%PDF-test\n')),
    list(type = 'text/plain', body = charToRaw('TEXT')),
    list(type = 'application/json', body = charToRaw('{"value":1}')),
    list(type = 'application/json', body = charToRaw('{')),
    list(type = 'image/png', body = charToRaw('bad image')),
    list(type = 'image/png', body = raw()))
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- list(url = req$url, accept = req$headers$Accept)
    httr2::response(status_code = 200L, headers = list(`Content-Type` = content$type), body = content$body)
  }, .package = 'httr2')
  old <- static_media_legacy('chemi_chet_chemicals_image')
  expect_identical(formals(chemi_chet_chemicals_image), formals(old))
  for (content in media) for (args in list(list(1), list(1, width = 100, height = 200, format = 'svg'),
    list(1, format = 'pdf'), list(c(1, 2)), list(NULL), list(c(1, 1, NA)))) {
    requests <- list(); a <- static_media_capture(old, args); old_wire <- requests
    requests <- list(); b <- static_media_capture(chemi_chet_chemicals_image, args)
    expect_identical(b, a)
    expect_identical(requests, old_wire)
  }
  content <- media[[1L]]; requests <- list()
  chemi_chet_chemicals_image('one/two')
  expect_match(requests[[1L]]$url, '/one%2Ftwo/image', fixed = TRUE)
})

test_that('ChET batch search preserves normalized identifiers and flat body options', {
  requests <- list()
  local_mocked_bindings(req_perform = function(req, ...) {
    requests[[length(requests) + 1L]] <<- list(url = req$url, accept = req$headers$Accept, body = req$body$data)
    httr2::response(status_code = 200L, headers = list(`Content-Type` = 'application/json'), body = charToRaw('{"data":[]}'))
  }, .package = 'httr2')
  old <- static_media_legacy('chemi_chet_reaction_batchsearch')
  expect_identical(formals(chemi_chet_reaction_batchsearch), formals(old))
  for (ids in list('one', c('one', 'one', NA, ''), NULL, character(), list('one', 'two'), 1L, TRUE)) {
    for (level in list('chemical', 'reaction', NULL)) {
      requests <- list(); a <- static_media_capture(old, list(ids, level)); old_wire <- requests
      requests <- list(); b <- static_media_capture(chemi_chet_reaction_batchsearch, list(ids, level))
      expect_identical(b, a)
      expect_identical(requests, old_wire)
    }
  }
  expect_error(chemi_chet_reaction_batchsearch(), class = 'missingArgError')
})

test_that('static and ChET requests preserve transport and ordinary HTTP failures with hard 401', {
  for (name in names(readRDS(test_path('fixtures/native-static-media-contracts.rds')))) {
    for (mode in c('transport', '404', '500', '401')) local({
      original <- structure(list(message = 'transport sentinel', call = NULL, resp = NULL),
        class = c('httr2_failure', 'httr2_error', 'rlang_error', 'error', 'condition'))
      local_mocked_bindings(req_perform = function(req, ...) {
        if (mode == 'transport') stop(original)
        response <- httr2::response(status_code = as.integer(mode), headers = list(`Content-Type` = 'application/json'), body = charToRaw('{"error":"failed"}'))
        policy <- req$policies$error_is_error
        if (is.null(policy) || isTRUE(policy(response))) httr2::resp_check_status(response)
        response
      }, .package = 'httr2')
      args <- if (name == 'chemi_chet_reaction_batchsearch') list('one', 'chemical') else list('one')
      native <- get(name, asNamespace('ComptoxR'))
      if (mode == '401') {
        expect_error(do.call(native, args), class = 'specmill_call_error')
      } else {
        expect_identical(static_media_capture(native, args), static_media_capture(static_media_legacy(name), args), info = name)
      }
    })
  }
})
