test_that('EPI specification and distribution preserve declared JSON and binary responses', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  directory <- tempfile('epi-distribution-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  binary <- as.raw(c(80, 75, 3, 4, 0, 255, 10, 13))
  saveRDS(list(status = 200L, binary = binary), file.path(directory, 'response.rds'))
  server <- callr::r_bg(
    function(directory) {
      port <- httpuv::randomPort()
      httpuv::startServer(
        '127.0.0.1',
        port,
        list(call = function(request) {
          saveRDS(
            list(method = request$REQUEST_METHOD, path = request$PATH_INFO, query = request$QUERY_STRING),
            file.path(directory, 'request.rds')
          )
          response <- readRDS(file.path(directory, 'response.rds'))
          download <- identical(request$PATH_INFO, '/api/download')
          list(
            status = response$status,
            headers = list(
              `Content-Type` = if (download) 'application/java-archive' else 'application/json',
              `Content-Disposition` = if (download) 'attachment; filename="epi.jar"' else 'inline'
            ),
            body = if (download) response$binary else '{"openapi":"3.0.3","x-epi-health":{"ready":true}}'
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
  for (i in seq_len(400L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) {
      break
    }
    Sys.sleep(0.05)
  }
  expect_true(file.exists(file.path(directory, 'ready.rds')), info = server$read_error())
  withr::local_options(list(
    ComptoxR.epi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')), '/api'),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)
  ))
  ns <- asNamespace('ComptoxR')
  for (name in c('epi', 'epi_download')) {
    fn <- get(name, ns)
    expected_path <- if (name == 'epi') '/api' else '/api/download'
    value <- fn()
    if (name == 'epi') {
      expect_identical(value, list(openapi = '3.0.3', `x-epi-health` = list(ready = TRUE)))
    } else {
      expect_identical(value, binary)
    }
    expect_identical(
      readRDS(file.path(directory, 'request.rds')),
      list(method = 'GET', path = expected_path, query = '')
    )
    expect_length(formals(fn), 0L)
    for (status in c(404L, 500L, 503L, 401L)) {
      saveRDS(list(status = status, binary = binary), file.path(directory, 'response.rds'))
      error <- tryCatch(fn(), error = identity)
      expect_s3_class(error, if (status == 401L) 'specmill_call_error' else 'error')
      expect_match(conditionMessage(error), paste('HTTP', status), fixed = TRUE)
    }
    saveRDS(list(status = 200L, binary = binary), file.path(directory, 'response.rds'))
  }
})
