endpoint_keys <- c('ctx_burl', 'chemi_burl', 'epi_burl', 'eco_burl', 'toxval_burl', 'np_burl', 'pubchem_burl')

test_that('all services use option, environment, then approved defaults', {
  withr::local_envvar(setNames(rep(NA_character_, length(endpoint_keys)), endpoint_keys))
  withr::local_options(setNames(rep(list(NULL), length(endpoint_keys)), paste0('ComptoxR.', endpoint_keys)))
  for (key in endpoint_keys) {
    expect_identical(.endpoint_target(key), .endpoint_default(key))
    do.call(Sys.setenv, setNames(list('https://environment.example/api'), key))
    expect_identical(.endpoint_target(key), 'https://environment.example/api')
    options(setNames(list('https://option.example/api'), paste0('ComptoxR.', key)))
    expect_identical(.endpoint_target(key), 'https://option.example/api')
    expect_identical(.endpoint_url('https://literal.example/api'), 'https://literal.example/api')
    for (invalid in list('', NA_character_, character(), c('one', 'two'), FALSE)) {
      options(setNames(list(invalid), paste0('ComptoxR.', key)))
      expect_error(.endpoint_target(key), 'Configure')
    }
    options(setNames(list(NULL), paste0('ComptoxR.', key)))
    do.call(Sys.setenv, setNames(list(''), key))
    expect_identical(.endpoint_target(key), .endpoint_default(key))
  }
  withr::local_envvar(custom_service = 'https://custom.example/api')
  expect_identical(.endpoint_url('custom_service'), 'https://custom.example/api')
  for (bad in c('https://', 'https://bad host/api', 'ftp://example.com')) {
    expect_error(.endpoint_url(bad), 'HTTP|Configure')
  }
  expect_identical(.endpoint_default('epi_burl'), 'https://episuite.dev/api')
})

test_that('selectors preserve explicit settings and reject removed numeric modes', {
  withr::local_envvar(ctx_burl = 'https://environment.example/api', chemi_burl = NA_character_)
  withr::local_options(ComptoxR.ctx_burl = 'https://option.example/api')
  expect_identical(ctx_server(1, url_only = TRUE), .endpoint_default('ctx_burl'))
  expect_identical(Sys.getenv('ctx_burl'), 'https://environment.example/api')
  expect_identical(ctx_server('https://explicit.example/api'), 'https://option.example/api')
  expect_identical(Sys.getenv('ctx_burl'), 'https://explicit.example/api')
  expect_identical(ctx_server(), 'https://option.example/api')
  expect_identical(Sys.getenv('ctx_burl'), '')
  expect_error(ctx_server(2), 'not supported')
  expect_error(ctx_server(3), 'not supported')
  expect_error(chemi_server(2), 'not supported')
  expect_error(chemi_server(3), 'not supported')
  expect_error(eco_server(4), 'not supported')
  expect_error(toxval_server(4), 'not supported')
  expect_error(epi_server(1, url_only = NA), 'TRUE or FALSE')
})

test_that('source and dated package startup do not change endpoint settings', {
  local_mocked_bindings(globalVariables = function(...) NULL, .package = 'utils')
  withr::local_envvar(setNames(rep(NA_character_, length(endpoint_keys)), endpoint_keys))
  withr::local_options(setNames(rep(list(NULL), length(endpoint_keys)), paste0('ComptoxR.', endpoint_keys)))
  expected <- vapply(endpoint_keys, .endpoint_default, character(1))
  for (date in c(NA_character_, '2026-09-07')) {
    local_mocked_bindings(packageDate = function(...) date, .package = 'utils')
    .onLoad(NULL, 'ComptoxR')
    expect_identical(
      Sys.getenv(endpoint_keys, unset = NA_character_),
      setNames(rep(NA_character_, length(endpoint_keys)), endpoint_keys)
    )
    expect_identical(vapply(endpoint_keys, .endpoint_target, character(1)), expected)
  }
  expect_identical(
    .diagnostic_endpoint('https://user:secret@example.com/api?token=secret'),
    'https://<redacted>@example.com/api'
  )
  expect_identical(
    .diagnostic_endpoint('HTTPS://user:secret@example.com/api?token=secret'),
    'HTTPS://<redacted>@example.com/api'
  )
})

test_that('database configuration changes close stale connections but lookups do not', {
  withr::local_envvar(eco_burl = NA_character_, toxval_burl = NA_character_)
  withr::local_options(ComptoxR.eco_burl = NULL, ComptoxR.toxval_burl = NULL)
  paths <- c(tempfile(fileext = '.duckdb'), tempfile(fileext = '.duckdb'))
  withr::defer(unlink(paths))
  for (path in paths) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
    DBI::dbWriteTable(con, 'marker', data.frame(value = path))
    DBI::dbDisconnect(con, shutdown = TRUE)
  }
  for (key in c('eco_burl', 'toxval_burl')) {
    selector <- if (key == 'eco_burl') eco_server else toxval_server
    get_con <- if (key == 'eco_burl') .eco_get_con else .tox_get_con
    close_con <- if (key == 'eco_burl') .eco_close_con else .tox_close_con
    close_con()
    selector(paths[1])
    first <- get_con()
    expect_true(DBI::dbIsValid(first))
    expect_identical(selector(paths[2], url_only = TRUE), normalizePath(paths[2]))
    expect_true(DBI::dbIsValid(first))
    options(setNames(list(paths[2]), paste0('ComptoxR.', key)))
    second <- get_con()
    expect_false(DBI::dbIsValid(first))
    expect_identical(DBI::dbReadTable(second, 'marker')$value, paths[2])
    options(setNames(list(NULL), paste0('ComptoxR.', key)))
    do.call(Sys.setenv, setNames(list(paths[1]), key))
    third <- get_con()
    expect_false(DBI::dbIsValid(second))
    expect_identical(DBI::dbReadTable(third, 'marker')$value, paths[1])
    selector('https://local-api.example/api')
    expect_false(DBI::dbIsValid(third))
    route <- if (key == 'eco_burl') .eco_route else .tox_route
    expect_identical(route(), 'plumber')
    selector(3)
    expect_error(route(), 'not a REST API')
    expect_identical(selector(), .endpoint_default(key))
    close_con()
  }
})
