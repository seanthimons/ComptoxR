reviewed_get_body_acceptance <- function() {
  workspace <- tempfile('reviewed-get-body-')
  dir.create(workspace)
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)
  port_file <- file.path(workspace, 'port')
  server <- callr::r_bg(
    function(port_file) {
      port <- httpuv::randomPort()
      count <- 0L
      server <- httpuv::startServer(
        '127.0.0.1',
        port,
        list(call = function(req) {
          count <<- count + 1L
          body <- rawToChar(req$rook.input$read())
          list(
            status = if (nzchar(body)) 200L else 400L,
            headers = list('Content-Type' = 'application/json'),
            body = jsonlite::toJSON(
              list(
                method = req$REQUEST_METHOD,
                body = body,
                type = req$CONTENT_TYPE,
                count = count
              ),
              auto_unbox = TRUE
            )
          )
        })
      )
      on.exit(server$stop(), add = TRUE)
      writeLines(as.character(port), port_file)
      repeat {
        httpuv::service(100)
      }
    },
    list(port_file),
    supervise = TRUE
  )
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(port_file)) {
      break
    }
    if (!server$is_alive()) {
      server$get_result()
    }
    Sys.sleep(0.05)
  }
  stopifnot(file.exists(port_file))
  schema <- file.path(workspace, 'schema.json')
  operation <- list(
    operationId = 'download',
    requestBody = list(
      required = TRUE,
      content = list(
        'application/json' = list(
          schema = list(type = 'object', additionalProperties = TRUE)
        )
      )
    ),
    responses = list(
      '200' = list(
        description = 'OK',
        content = list(
          'application/json' = list(schema = list(type = 'object'))
        )
      )
    )
  )
  document <- list(
    openapi = '3.1.0',
    info = list(title = 'Reviewed GET body', version = '1'),
    paths = list('/download' = list(get = operation, post = operation))
  )
  document$paths[['/download']]$post$operationId <- 'submit'
  jsonlite::write_json(document, schema, auto_unbox = TRUE)
  before <- tools::md5sum(schema)
  root <- file.path(workspace, 'client')
  specmill::initialize_client(
    root,
    schema,
    package = 'getbodyclient',
    title = 'Reviewed GET body',
    author = list(
      given = 'Test',
      family = 'Maintainer',
      email = 'test@example.org'
    ),
    license = 'MIT + file LICENSE',
    base_url = paste0('http://127.0.0.1:', readLines(port_file))
  )
  correction <- list(
    preserve = TRUE,
    reason = 'Captured deployed read requires JSON.'
  )
  path <- file.path(root, 'apis/default.yml')
  service <- yaml::read_yaml(path, handlers = list(seq = identity))
  service$operations[['GET /download']] <- list(
    body_media = 'application/json'
  )
  yaml::write_yaml(service, path)
  plan <- specmill::generate_client(
    root,
    config = 'specmill.yml',
    mode = 'apply',
    validation = TRUE
  )
  stopifnot(
    !length(plan$diagnostics),
    !length(plan$mapping_diagnostics),
    identical(before, tools::md5sum(schema))
  )
  get <- Filter(function(op) op$method == 'GET', plan$operations)[[1L]]
  stopifnot(
    identical(get$body$type, 'object'), isTRUE(get$body_required)
  )
  runtime <- new.env(parent = baseenv())
  for (file in list.files(file.path(root, 'R'), full.names = TRUE)) {
    sys.source(file, runtime)
  }
  empty <- runtime$download(setNames(list(), character()))
  stopifnot(
    empty$method == 'GET',
    empty$body == '{}',
    empty$type == 'application/json',
    empty$count == 1L
  )
  fields <- list(ids = list('one', 'two'), filter = list(active = TRUE))
  result <- runtime$download(fields)
  stopifnot(identical(
    jsonlite::fromJSON(result$body, simplifyVector = FALSE),
    fields
  ))
  error <- tryCatch(runtime$download('invalid'), error = identity)
  stopifnot(
    inherits(error, 'error'),
    runtime$download(setNames(list(), character()))$count == 3L
  )
  stopifnot(runtime$submit(fields)$method == 'POST')
  specmill::generate_client(
    root,
    config = 'specmill.yml',
    mode = 'check',
    validation = TRUE
  )
  cat(
    'Existing released OAS3.1 reviewed source GET body: schema-validated JSON, empty object, arbitrary fields, native method, sibling, provenance and freshness passed.\n'
  )
}
if (sys.nframe() == 0L) {
  reviewed_get_body_acceptance()
}
