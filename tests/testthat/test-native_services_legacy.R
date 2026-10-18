legacy_services_wrappers <- c('chemi_services_convert', 'chemi_services_collated_report')

test_that('legacy service formals, corrected bodies and actual HTTP conditions are explicit', {
  directory <- tempfile('services-legacy-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  response <- list(status = 200L, media = 'application/json', body = charToRaw('{"ok":true,"items":[1,2]}'))
  saveRDS(response, file.path(directory, 'response.rds'))
  server <- callr::r_bg(function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      count <<- count + 1L
      saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, query = req$QUERY_STRING,
        content_type = req$CONTENT_TYPE, body = req$rook.input$read()), file.path(directory, paste0(count, '.rds')))
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
  origin <- paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')))
  withr::local_options(list(ComptoxR.chemi_burl = paste0(origin, '/api'),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  count <- 0L
  invoke <- function(fn, args) {
    previous <- count
    value <- tryCatch(do.call(fn, args), error = identity)
    count <<- length(list.files(directory, pattern = '^[0-9]+[.]rds$'))
    expect_identical(count - previous, if (identical(fn, old) && response$status == 500L) 3L else 1L)
    list(value = value, wire = readRDS(file.path(directory, paste0(count, '.rds'))))
  }
  for (name in legacy_services_wrappers) {
    old_env <- new.env(parent = asNamespace('ComptoxR'))
    old_file <- testthat::test_path('../..', 'dev/search-services/legacy-before', paste0(name, '.R'))
    skip_if_not(file.exists(old_file), 'Maintainer fixture is excluded from the CRAN source tarball.')
    sys.source(old_file, old_env)
    old <- old_env[[name]]
    native <- get(name, asNamespace('ComptoxR'))
    expect_identical(formals(native), formals(old))
    # The original sources do not invoke hooks, skip_request or partial-update state.
    expect_false(any(grepl('run_hook|skip_request|state\\$params', deparse(body(old)))))
    args <- if (name == 'chemi_services_convert') list(content = 'localhost input', type = 'mol2smiles') else
      list(alertRequest = '{"localhost":true}', chemicals = '[{"sid":"localhost"}]', exportAlerts = FALSE,
        exportHazard = FALSE, exportHazard2 = TRUE, exportPrediction = FALSE, exportSafety = TRUE,
        hazardRequest = '{"hazard":true}', predictionRequest = '{"prediction":true}')
    before <- invoke(old, args)
    after <- invoke(native, args)
    expect_identical(after$wire$method, 'POST')
    expect_identical(after$wire$path, paste0('/api/services/', if (name == 'chemi_services_convert') 'convert' else 'collated_report'))
    expect_identical(after$wire$query, '')
    expect_match(after$wire$content_type, '^application/json')
    sent <- jsonlite::fromJSON(rawToChar(after$wire$body), simplifyVector = FALSE)
    expect_identical(sent, args)
    old_sent <- jsonlite::fromJSON(rawToChar(before$wire$body), simplifyVector = FALSE)
    first <- names(args)[[1L]]
    expect_identical(old_sent$chemicals, list(list(sid = args[[first]])))
    expect_identical(old_sent$options, args[setdiff(names(args), first)])
    if (name == 'chemi_services_collated_report') expect_identical(after$value, before$value) else {
      # Deliberate correction: convert returns text, including when media says JSON.
      expect_identical(after$value, rawToChar(response$body))
      expect_identical(before$value, list(ok = TRUE, items = list(1L, 2L)))
    }
    for (field in names(args)) {
      invalid <- args
      invalid[[field]] <- list('bad scalar')
      expect_error(do.call(native, invalid))
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
    }
    expect_error(native(), 'Either query or chemicals parameter must be provided')
    expect_error(old(), 'Either query or chemicals parameter must be provided')
    expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
    if (name == 'chemi_services_collated_report') {
      invalid <- args
      invalid$exportSafety <- 'true'
      expect_error(do.call(native, invalid))
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
    }
    for (bad in list(list(timeout = -1), list(max_retries = 0.5), list(preserve_errors = 'yes'))) {
      withr::with_options(list(comptoxr_native.request = bad), expect_error(do.call(native, args), class = 'specmill_call_error'))
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
    }
    for (status in c(404L, 500L, 401L)) {
      response$status <- status
      response$body <- charToRaw('{"error":"legacy services sentinel"}')
      saveRDS(response, file.path(directory, 'response.rds'))
      before <- invoke(old, args)$value
      after <- invoke(native, args)$value
      if (status == 401L) {
        expect_s3_class(before, 'httr2_http_401')
        expect_s3_class(after, 'specmill_call_error')
        expect_match(conditionMessage(after), 'HTTP 401 application/json')
      } else {
        expect_identical(class(after), class(before))
        expect_identical(class(after$parent), class(before$parent))
        expect_identical(conditionMessage(after), conditionMessage(before))
        expect_identical(httr2::resp_status(after$resp), httr2::resp_status(before$resp))
        expect_identical(httr2::resp_body_raw(after$resp), httr2::resp_body_raw(before$resp))
      }
    }
    response$status <- 200L
    if (name == 'chemi_services_convert') {
      evidence <- jsonlite::read_json(test_path('../..', 'dev/search-services/calculation-evidence.json'))
      response$media <- 'application/json'
      response$body <- charToRaw(evidence$probes[[1L]]$body)
      saveRDS(response, file.path(directory, 'response.rds'))
      expect_s3_class(invoke(old, args)$value, 'error')
      expect_identical(invoke(native, args)$value, evidence$probes[[1L]]$body)
      for (invalid in list(list(type = 'mol2smiles'), list(content = '', type = 'mol2smiles'))) {
        expect_error(do.call(native, invalid))
        expect_error(do.call(old, invalid))
        expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))))
      }
    }
    for (sample in list(
      list(media = 'text/plain', body = charToRaw('report sentinel'), value = 'report sentinel'),
      list(media = 'application/octet-stream', body = as.raw(c(80, 75, 0, 255)), value = as.raw(c(80, 75, 0, 255)))
    )) {
      if (name == 'chemi_services_convert' && is.raw(sample$value)) next
      response$media <- sample$media
      response$body <- sample$body
      saveRDS(response, file.path(directory, 'response.rds'))
      expect_identical(invoke(native, args)$value, sample$value)
    }
    response$media <- 'application/json'
    response$body <- charToRaw('{"ok":true,"items":[1,2]}')
    saveRDS(response, file.path(directory, 'response.rds'))
  }
})
