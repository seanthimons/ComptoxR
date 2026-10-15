test_that('download persistence repairs only empty Swagger 2.0 basePath in JSON and YAML', {
  root <- withr::local_tempdir()
  for (format in c('json', 'yaml')) {
    schema <- list(
      swagger = '2.0',
      basePath = '',
      paths = list('/api/mordred' = list()),
      definitions = list(empty = setNames(list(), character()))
    )
    encode <- function(x) {
      charToRaw(
        if (format == 'json') {
          as.character(jsonlite::toJSON(x, auto_unbox = TRUE))
        } else {
          yaml::as.yaml(x)
        }
      )
    }
    bytes <- encode(schema)
    original <- bytes
    path <- file.path(root, paste0('schema.', format))
    suppressMessages(expect_true(.write_downloaded_schema(bytes, path)))
    result <- if (format == 'json') jsonlite::read_json(path) else yaml::read_yaml(path)
    schema$basePath <- '/'
    expect_identical(result, schema)
    expect_identical(bytes, original)
    for (base_path in list(NULL, '/', '/api', 'relative')) {
      schema$basePath <- base_path
      bytes <- encode(schema)
      expect_false(.write_downloaded_schema(bytes, path))
      expect_identical(readBin(path, 'raw', n = file.info(path)$size), bytes)
    }
    schema$swagger <- NULL
    schema$openapi <- '3.1.0'
    schema$basePath <- ''
    bytes <- encode(schema)
    expect_false(.write_downloaded_schema(bytes, path))
    expect_identical(readBin(path, 'raw', n = file.info(path)$size), bytes)
    bytes <- charToRaw('not a schema')
    expect_false(.write_downloaded_schema(bytes, path))
    expect_identical(readBin(path, 'raw', n = file.info(path)$size), bytes)
  }
})

test_that('chemi_schema normalizes freshly downloaded JSON and YAML', {
  root <- withr::local_tempdir()
  testthat::local_mocked_bindings(here = function(...) file.path(root, ...), .package = 'here')
  schema <- list(swagger = '2.0', basePath = '', paths = list('/api/mordred' = list()))
  perform <- function(req, ...) {
    if (grepl('/services/cim_component_info$', req$url)) {
      body <- jsonlite::toJSON(list(list(name = 'mordred'), list(name = 'rdkit')), auto_unbox = TRUE)
      type <- 'application/json'
    } else if (grepl('/mordred/api-docs$', req$url)) {
      body <- jsonlite::toJSON(schema, auto_unbox = TRUE)
      type <- 'application/json'
    } else if (grepl('/rdkit/api-docs$', req$url)) {
      body <- yaml::as.yaml(schema)
      type <- 'application/yaml'
    } else {
      stop('Unexpected schema request: ', req$url)
    }
    httr2::response(status_code = 200, headers = list('Content-Type' = type), body = charToRaw(body))
  }
  testthat::local_mocked_bindings(req_perform = perform, .package = 'httr2')
  testthat::local_mocked_bindings(req_perform = perform, .package = 'ComptoxR')
  suppressMessages(log <- chemi_schema(record = TRUE))
  expect_true(all(log$success))
  json <- jsonlite::read_json(file.path(root, 'schema/chemi-mordred-prod.json'))
  yaml <- yaml::read_yaml(file.path(root, 'schema/chemi-rdkit-prod.yaml'))
  schema$basePath <- '/'
  expect_identical(json, schema)
  expect_identical(yaml, schema)
})
