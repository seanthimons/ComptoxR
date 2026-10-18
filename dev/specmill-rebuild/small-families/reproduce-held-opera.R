# The held wrapper is official output, executed only against a real localhost server.
pkgload::load_all(quiet = TRUE)
env <- new.env(parent = asNamespace('ComptoxR'))
sys.source('dev/specmill-rebuild/small-families/held-opera.R.txt', env)
directory <- tempfile('opera-boolean-')
dir.create(directory)
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
            body = request$rook.input$read(),
            content_type = request$CONTENT_TYPE
          ),
          file.path(directory, 'request.rds')
        )
        list(status = 200L, headers = list(`Content-Type` = 'application/json'), body = '{}')
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
tryCatch(
  {
    for (i in seq_len(100L)) {
      if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) {
        break
      }
      Sys.sleep(0.05)
    }
    stopifnot(file.exists(file.path(directory, 'ready.rds')))
    options(
      ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
      comptoxr_native.request = list(max_retries = 0L, timeout = 5)
    )
    evidence <- lapply(c(FALSE, TRUE), function(standardize) {
      env$chemi_opera_file(standardize = standardize, body = list(file = charToRaw('CCO ethanol\n')))
      sent <- readRDS(file.path(directory, 'request.rds'))
      stopifnot(
        identical(sent$method, 'POST'),
        identical(sent$path, '/api/opera/file'),
        identical(sub('^\\?', '', sent$query), paste0('format=json&standardize=', standardize)),
        grepl('^multipart/form-data; boundary=', sent$content_type),
        grepl('CCO ethanol\n', rawToChar(sent$body), fixed = TRUE)
      )
      sent
    })
    saveRDS(evidence, 'dev/specmill-rebuild/small-families/held-opera-wire.rds', version = 2)
    cat('Confirmed real multipart POST uses standardize=FALSE and standardize=TRUE. No external HTTP.\n')
  },
  finally = {
    server$kill()
    unlink(directory, recursive = TRUE)
  }
)
