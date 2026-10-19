chet_admin_auth_wrappers <- c(
  'chemi_chet_auth_login_post',
  'chemi_chet_auth_register_post',
  'chemi_chet_auth_report_post',
  'chemi_chet_admin_database',
  'chemi_chet_admin_errorreport_post',
  'chemi_chet_admin_login_post',
  'chemi_chet_admin_register_post',
  'chemi_chet_admin_resolve_post',
  'chemi_chet_auth_errorpage',
  'chemi_chet_auth_errorpage_post',
  'chemi_chet_auth_errorpage_complete_idnum',
  'chemi_chet_auth_errorpage_complete_idnum_post',
  'chemi_chet_auth_errorpage_showhide',
  'chemi_chet_auth_errorpage_showhide_post',
  'chemi_chet_auth_logout',
  'chemi_chet_auth_testpage',
  'chemi_chet_auth_testpage_post')

test_that('chet_admin_auth bindings validate inputs and preserve actual localhost wire contracts', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  cases <- readRDS(test_path('fixtures/native-chet-admin-auth.rds'))
  expect_setequal(names(cases), chet_admin_auth_wrappers)
  directory <- tempfile('chet_admin_auth-http-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  response <- list(status = 200L, media = 'application/json', body = charToRaw('{"ok":true,"items":[1,2]}'))
  saveRDS(response, file.path(directory, 'response.rds'))
  server <- callr::r_bg(function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      count <<- count + 1L
      body <- req$rook.input$read()
      saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO,
        query = req$QUERY_STRING, content_type = req$CONTENT_TYPE,
        accept = req$HTTP_ACCEPT, body = body), file.path(directory, paste0(count, '.rds')))
      result <- readRDS(file.path(directory, 'response.rds'))
      list(status = result$status, headers = list(`Content-Type` = result$media), body = result$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(50)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  count <- 0L
  invoke <- function(fn, args) {
    count <<- count + 1L
    value <- do.call(fn, args)
    list(value = value, wire = readRDS(file.path(directory, paste0(count, '.rds'))))
  }
  for (name in names(cases)) {
    case <- cases[[name]]
    fn <- get(name, asNamespace('ComptoxR'))
    if (file.exists(test_path('..', '..', 'specmill.yml'))) {
      expect_identical(digest::digest(file = test_path('../..', case$source), algo = 'sha256'), case$source_sha256)
    }
    result <- invoke(fn, case$args)
    expect_identical(result$value, list(ok = TRUE, items = list(1L, 2L)), info = name)
    expect_identical(result$wire$method, case$method, info = name)
    expect_identical(result$wire$path, case$path, info = name)
    expect_identical(result$wire$accept, '*/*', info = name)
    query <- httr2::url_parse(paste0('http://localhost/?', sub('^\\?', '', result$wire$query)))$query
    expected <- lapply(case$query, function(x) if (is.logical(x)) tolower(as.character(x)) else as.character(x))
    expect_equal(query, if (length(expected)) expected else NULL, info = name)
    if (is.null(case$body_media)) {
      expect_length(result$wire$body, 0L)
    } else if (case$body_media == 'application/json') {
      expect_match(result$wire$content_type, '^application/json', info = name)
      expect_identical(jsonlite::fromJSON(rawToChar(result$wire$body), simplifyVector = FALSE), case$args$body, info = name)
    } else {
      expect_match(result$wire$content_type, '^application/x-www-form-urlencoded', info = name)
      fields <- httr2::url_parse(paste0('http://localhost/?', rawToChar(result$wire$body)))$query
      expect_identical(fields, case$args$body, info = name)
    }
    if (name %in% c('chemi_chet_auth_login_post', 'chemi_chet_auth_register_post', 'chemi_chet_auth_report_post')) {
      expect_identical(names(formals(fn)), 'body', info = name)
      expect_identical(formals(fn)$body, quote(expr = ), info = name)
      body <- list(
        text = 'a&b=+/?',
        integer = 2L,
        fraction = 1.5,
        yes = TRUE,
        no = FALSE,
        blank = '',
        `field &` = 'caf\u00e9'
      )
      scalar <- invoke(fn, list(body = body))
      expect_identical(
        rawToChar(scalar$wire$body),
        'text=a%26b%3D%2B%2F%3F&integer=2&fraction=1.5&yes=true&no=false&blank=&field%20%26=caf%C3%A9',
        info = name
      )
      expect_identical(invoke(fn, list(body = list()))$wire$body, raw(), info = name)
      for (bad in list(
        NULL,
        NA_character_,
        NA_real_,
        NA,
        NaN,
        Inf,
        -Inf,
        character(),
        c('a', 'b'),
        list('a'),
        list(nested = 'a'),
        as.raw(1),
        as.Date('2026-01-01')
      )) {
        expect_error(fn(body = list(field = bad)), info = name)
        expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
      }
    }
    # A malformed declared input must fail before the localhost server sees it.
    if (length(case$args)) {
      invalid <- case$args
      field <- if ('body' %in% names(invalid)) 'body' else names(invalid)[[1L]]
      invalid[[field]] <- if (field == 'body') 'invalid object' else list('invalid scalar')
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    for (field in setdiff(names(case$args), 'body')) {
      missing <- case$args
      missing[[field]] <- NULL
      expect_error(do.call(fn, missing), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    if ('body' %in% names(case$args)) {
      invalid <- case$args
      invalid$body <- NULL
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    for (bad in list(list(timeout = -1), list(max_retries = 0.5), list(preserve_errors = 'yes'))) {
      withr::with_options(list(comptoxr_native.request = bad), {
        expect_error(do.call(fn, case$args), class = 'specmill_call_error', info = name)
      })
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    for (status in c(400L, 401L, 404L, 500L)) {
      response$status <- status
      response$body <- charToRaw('{"error":"chet_admin_auth sentinel"}')
      saveRDS(response, file.path(directory, 'response.rds'))
      count <- count + 1L
      error <- tryCatch(do.call(fn, case$args), error = identity)
      expect_s3_class(error, if (status == 401L) 'specmill_call_error' else paste0('httr2_http_', status))
      if (status == 401L) {
        expect_match(conditionMessage(error), 'HTTP 401 application/json', info = name)
      } else {
        expect_identical(httr2::resp_status(error$resp), status)
        expect_identical(httr2::resp_body_json(error$resp), list(error = 'chet_admin_auth sentinel'))
      }
      expect_true(file.exists(file.path(directory, paste0(count, '.rds'))), info = name)
    }
    response$status <- 200L
    for (sample in list(
      list(media = 'image/svg+xml', body = charToRaw('<svg>sentinel</svg>'), value = '<svg>sentinel</svg>'),
      list(media = 'image/png', body = as.raw(c(137, 80, 78, 71, 0, 255)), value = as.raw(c(137, 80, 78, 71, 0, 255))),
      list(media = 'text/plain', body = charToRaw('report sentinel'), value = 'report sentinel'),
      list(media = 'application/json', body = charToRaw('{}'), value = stats::setNames(list(), character()))
    )) {
      response$media <- sample$media
      response$body <- sample$body
      saveRDS(response, file.path(directory, 'response.rds'))
      expect_identical(invoke(fn, case$args)$value, sample$value, info = name)
    }
    response$media <- 'application/json'
    response$body <- charToRaw('{"ok":true,"items":[1,2]}')
    saveRDS(response, file.path(directory, 'response.rds'))
  }
})
