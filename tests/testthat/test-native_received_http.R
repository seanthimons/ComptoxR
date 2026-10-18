test_that('adopted static and AMOS wrappers preserve real received HTTP status conditions', {
  skip_if_not_installed('httpuv'); skip_if_not_installed('callr')
  directory <- tempfile('received-http-'); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(404L, file.path(directory, 'status.rds'))
  server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(request) {
      list(status = readRDS(file.path(directory, 'status.rds')),
        headers = list(`Content-Type` = 'application/json'), body = '{"error":"received sentinel"}')
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(100)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(100L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  # Avoid backoff delays while retaining real transport and httr2 status checks.
  local_mocked_bindings(is_transient_error = function(...) FALSE)
  cases <- list(
    chemi_resolver_safety_flags = list('one'),
    chemi_resolver_pubchem_section = list('one'),
    chemi_toxprints_calculate = list('C'),
    chemi_chet_chemicals_image = list(1),
    chemi_chet_reaction_batchsearch = list('one', 'chemical'),
    chemi_amos_substances_for_ids = list('FS-10313'),
    chemi_amos_retrieve_fact_sheets = list('FS-10313'),
    chemi_amos_retrieve_product_declarations = list('PD-104171'),
    chemi_amos_retrieve_safety_data_sheets = list('SDS-100074'),
    chemi_amos_for_document_ids = list('Fact Sheet',
      search_info = list(internal_id = list(value = 'FS-10313', exact = TRUE)),
      record_info_fields = 'internal_id'))
  legacy <- readRDS(test_path('fixtures/native-static-media-contracts.rds'))
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
