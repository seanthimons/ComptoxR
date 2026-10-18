test_that('resolved native wrappers preserve actual HTTP response conditions', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  directory <- tempfile('received-http-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(404L, file.path(directory, 'status.rds'))
  server <- callr::r_bg(
    function(directory) {
      port <- httpuv::randomPort()
      httpuv::startServer(
        '127.0.0.1',
        port,
        list(call = function(request) {
          saveRDS(request$rook.input$read(), file.path(directory, 'request.rds'))
          list(
            status = readRDS(file.path(directory, 'status.rds')),
            headers = list(`Content-Type` = 'application/json'),
            body = if (readRDS(file.path(directory, 'status.rds')) == 200L) {
              '[{"value":1}]'
            } else {
              '{"error":"received sentinel"}'
            }
          )
        })
      )
      saveRDS(port, file.path(directory, 'ready.rds'))
      repeat {
        httpuv::service(100)
      }
    },
    args = list(directory),
    supervise = TRUE
  )
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(100L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) {
      break
    }
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)
  ))
  # Avoid backoff delays while retaining real transport and httr2 status checks.
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(list(result = 'FOUND', chemical = list(chemId = 'ONE', canonicalSmiles = 'C')))
    },
    .package = 'ComptoxR'
  )
  cases <- list(
    chemi_hazard = list('one', format = 'raw'),
    chemi_hazard_bulk = list('one', format = 'raw'),
    chemi_alerts = list('one'),
    chemi_resolver_getsimilaritymap = list('one', format = 'raw'),
    chemi_resolver_orderBySimilarity = list('one'),
    chemi_resolver_pubchem_section_bulk = list('one'),
    chemi_stdizer_chemicals = list('one'),
    chemi_toxprints_calculate_bulk = list('one')
  )
  saveRDS(200L, file.path(directory, 'status.rds'))
  for (name in setdiff(names(cases), 'chemi_hazard')) {
    args <- cases[[name]]
    if (name == 'chemi_alerts') {
      args$options <- list(alerts = 'group')
    }
    if (name == 'chemi_stdizer_chemicals') {
      args$options <- list(workflow = 'ms-ready')
    }
    if (name == 'chemi_resolver_orderBySimilarity') {
      args$main <- list(sid = 'REF', smiles = 'CC')
    }
    expect_identical(do.call(get(name, asNamespace('ComptoxR')), args), list(list(value = 1L)))
    body <- jsonlite::fromJSON(rawToChar(readRDS(file.path(directory, 'request.rds'))), simplifyVector = FALSE)
    expect_length(body$chemicals, 1L)
    flat <- name %in%
      c(
        'chemi_alerts',
        'chemi_resolver_getsimilaritymap',
        'chemi_resolver_pubchem_section_bulk',
        'chemi_stdizer_chemicals',
        'chemi_toxprints_calculate_bulk'
      )
    expect_identical(if (flat) body$chemicals[[1L]]$sid else body$chemicals[[1L]]$chemical$sid, 'ONE')
    if (name == 'chemi_alerts') {
      expect_identical(body$options$alerts, list('group'))
    }
    if (name == 'chemi_stdizer_chemicals') {
      expect_identical(body$options$workflow, 'ms-ready')
    }
    if (name == 'chemi_resolver_orderBySimilarity') {
      expect_identical(body$main$sid, 'REF')
    }
    if (name == 'chemi_toxprints_calculate_bulk') expect_identical(body$options, structure(list(), names = character()))
  }
  legacy <- readRDS(test_path('fixtures/native-resolved-chemical-contracts.rds'))$legacy
  for (status in c(404L, 500L, 401L)) {
    saveRDS(status, file.path(directory, 'status.rds'))
    for (name in names(cases)) {
      value <- tryCatch(do.call(get(name, asNamespace('ComptoxR')), cases[[name]]), error = identity)
      if (status == 401L) {
        expect_s3_class(value, 'specmill_call_error')
      } else {
        expect_s3_class(value, paste0('httr2_http_', status))
        expect_identical(httr2::resp_status(value$resp), status)
        expect_identical(httr2::resp_body_string(value$resp), '{"error":"received sentinel"}')
        if (name %in% names(legacy)) {
          old <- eval(legacy[[name]][[3L]], asNamespace('ComptoxR'))
          original <- tryCatch(do.call(old, cases[[name]]), error = identity)
          expect_s3_class(original, paste0('httr2_http_', status))
        }
      }
    }
  }
})
