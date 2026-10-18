service_info_wrappers <- c(
  "chemi_alerts_metadata",
  "chemi_alerts_version",
  "chemi_amnb_nate_metadata",
  "chemi_amnb_nate_version",
  "chemi_arn_cats_metadata",
  "chemi_arn_cats_version",
  "chemi_descriptors_metadata",
  "chemi_descriptors_version",
  "chemi_hazard_metadata",
  "chemi_hazard_version",
  "chemi_mordred_version",
  "chemi_mordred_metadata",
  "chemi_ncc_cats_metadata",
  "chemi_ncc_cats_version",
  "chemi_opera_metadata",
  "chemi_opera_version",
  "chemi_padel_metadata",
  "chemi_padel_version",
  "chemi_pfas_atlas_metadata",
  "chemi_pfas_atlas_version",
  "chemi_pfas_cats_metadata",
  "chemi_pfas_cats_version",
  "chemi_predictor_models_metadata",
  "chemi_predictor_models_version",
  "chemi_rdkit_version",
  "chemi_rdkit_metadata",
  "chemi_resolver_metadata",
  "chemi_resolver_version",
  "chemi_safety_metadata",
  "chemi_safety_version",
  "chemi_search_metadata",
  "chemi_search_version",
  "chemi_services_metadata",
  "chemi_services_version",
  "chemi_stdizer_metadata",
  "chemi_stdizer_version",
  "chemi_toxprints_metadata",
  "chemi_toxprints_version",
  "chemi_webtest_metadata",
  "chemi_webtest_version"
)

test_that('service information endpoints preserve exact routes and declared response decoding', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  contracts <- readRDS(test_path('fixtures/native-service-info.rds'))
  expect_setequal(names(contracts), service_info_wrappers)
  directory <- tempfile('service-info-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(
    list(status = 200L, body = '{"name":"service","nested":{"ready":true},"missing":null}'),
    file.path(directory, 'response.rds')
  )
  server <- callr::r_bg(
    function(directory) {
      port <- httpuv::randomPort()
      httpuv::startServer(
        '127.0.0.1',
        port,
        list(call = function(request) {
          saveRDS(
            list(
              method = request$REQUEST_METHOD,
              path = request$PATH_INFO,
              query = request$QUERY_STRING,
              body = request$rook.input$read()
            ),
            file.path(directory, 'request.rds')
          )
          response <- readRDS(file.path(directory, 'response.rds'))
          list(status = response$status, headers = list(`Content-Type` = 'application/json'), body = response$body)
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
  for (i in seq_len(400L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) {
      break
    }
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')), '/api'),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5),
    comptoxr_native.response_policy = NULL
  ))
  ns <- asNamespace('ComptoxR')
  for (name in names(contracts)) {
    fn <- get(name, ns)
    expect_length(formals(fn), 0L)
    saveRDS(
      list(status = 200L, body = '{"name":"service","nested":{"ready":true},"missing":null}'),
      file.path(directory, 'response.rds')
    )
    expect_identical(fn(), list(name = 'service', nested = list(ready = TRUE), missing = NULL))
    expect_identical(
      readRDS(file.path(directory, 'request.rds')),
      list(method = 'GET', path = contracts[[name]]$path, query = '', body = raw())
    )
    for (body in c('[]', 'null', '"version 1"')) {
      saveRDS(list(status = 200L, body = body), file.path(directory, 'response.rds'))
      expect_identical(fn(), jsonlite::fromJSON(body, simplifyVector = FALSE))
    }
    saveRDS(list(status = 200L, body = '{'), file.path(directory, 'response.rds'))
    expect_error(fn(), 'Cannot decode HTTP 200 application/json response as JSON', fixed = TRUE)
    for (status in c(404L, 500L, 401L)) {
      saveRDS(list(status = status, body = '{}'), file.path(directory, 'response.rds'))
      error <- tryCatch(fn(), error = identity)
      expect_s3_class(error, if (status == 401L) 'specmill_call_error' else 'error')
      expect_match(conditionMessage(error), paste('HTTP', status), fixed = TRUE)
    }
  }
})
