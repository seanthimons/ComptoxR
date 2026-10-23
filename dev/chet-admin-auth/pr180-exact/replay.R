# Run from the ComptoxR root after installing the exact archive in the private library.
replay_pr180 <- function() {
  sha <- 'd9c6f9600f075e941999fc4fafffd4ede3d90b73'
  cache <- Sys.getenv('PR180_CACHE', path.expand('~/.cache/comptoxr-pr180-exact-test'))
  out <- 'dev/chet-admin-auth/pr180-exact'
  lib <- file.path(cache, 'library')
  loadNamespace('specmill', lib.loc = lib)
  stopifnot(startsWith(getNamespaceInfo('specmill', 'path'), lib))
  work <- tempfile('project-', tmpdir = cache)
  dir.create(file.path(work, 'R'), recursive = TRUE)
  dir.create(file.path(work, 'schema'))
  dir.create(file.path(work, 'apis'))
  count <- 0L
  checks <- list()
  check <- function(ok, label) {
    count <<- count + 1L
    checks[[count]] <<- list(label = label, passed = isTRUE(ok))
    if (!isTRUE(ok)) stop(label)
    invisible(TRUE)
  }
  hash <- function(file) digest::digest(file = file, algo = 'sha256')
  normalized_hash <- function(file) digest::digest(paste(readLines(file, warn = FALSE), collapse = '\n'),
    algo = 'sha256', serialize = FALSE)
  canonical_hash <- hash('schema/chemi-chet-prod.json')
  canonical <- jsonlite::read_json('schema/chemi-chet-prod.json')
  rows <- Filter(function(x) identical(x$upstream, 'https://github.com/seanthimons/specmill/issues/178'),
    jsonlite::read_json('dev/chet-admin-auth/held.json'))
  check(length(rows) == 3L, 'Three actual held operations')
  config <- yaml::read_yaml('apis/chemi-chet-admin-auth.yml')
  config$schemas$files <- as.list(config$schemas$files)
  template <- config$operations[['POST /admin/login']]
  config$selection$include <- vapply(rows, `[[`, '', 'key')
  config$operations <- setNames(lapply(rows, function(row) {
    path <- sub('^POST ', '', row$key)
    check(identical(row$requestBody, canonical$paths[[path]]$post$requestBody), paste(row$key, 'canonical body'))
    check(isTRUE(row$requestBody$content[['application/x-www-form-urlencoded']]$schema$additionalProperties),
      paste(row$key, 'explicit additionalProperties'))
    op <- template
    op$name <- row$name
    op$file <- paste0('R/', row$name, '.R')
    op$docs$title <- sub("^#' ", '', readLines(file.path('dev/chet-admin-auth/held-generated',
      paste0(row$name, '.R')), n = 1L))
    op
  }), config$selection$include)
  yaml::write_yaml(config, file.path(work, 'apis/held.yml'))
  file.copy('schema/chemi-chet-prod.json', file.path(work, 'schema'))
  file.copy('R/service_endpoints.R', file.path(work, 'R'))
  check(identical(hash(file.path(work, 'schema/chemi-chet-prod.json')), canonical_hash), 'Private canonical schema unchanged')
  scaffold <- specmill:::request_helper_scaffold('.ct_request', 'https://example.invalid', NULL,
    'COMPTOXR_NATIVE_DRY_RUN', companions = c('batching', 'pagination'))
  writeLines(scaffold$code, file.path(work, 'R/z_specmill_request.R'))
  dir.create(file.path(work, '.specmill/helpers'), recursive = TRUE)
  writeLines(scaffold$provenance, file.path(work, '.specmill/helpers/.ct_request.json'))
  writeLines(c('Package: ComptoxR', 'Title: Isolated held forms proof', 'Version: 3.0.0',
    'Authors@R: person("Test", "Maintainer", email="test@example.org", role=c("aut", "cre"))',
    'Description: Private exact candidate form contract proof.', 'License: MIT', 'Encoding: UTF-8',
    'Roxygen: list(markdown = TRUE)', 'Imports: httr2, jsonlite, curl, lifecycle'), file.path(work, 'DESCRIPTION'))
  yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR', formatter = list(name = 'air', version = '0.11.0'),
    services = list('apis/held.yml')),
    file.path(work, 'specmill.yml'))
  generate <- function(mode) specmill::generate_client(root = work, config = 'specmill.yml', mode = mode,
    validation = TRUE, artifacts = c('wrappers', 'documentation'))
  plan <- generate('plan')
  check(length(plan$operations) == 3L, 'Validated plan has exactly three operations')
  applied <- generate('apply')
  fresh <- generate('check')
  for (field in c('diagnostics', 'mapping_diagnostics', 'drift', 'retained_diagnostics')) {
    check(!length(fresh[[field]]), paste('Fresh generation', field))
  }
  check(all(vapply(fresh$files, function(x) x$action %in% c('unchanged', 'retained'), TRUE)), 'All generated files fresh')
  check(length(fresh$validation) > 0L, 'Full validation report present')
  check(all(vapply(fresh$validation, function(x) identical(x$status, 'passed'), TRUE)), 'Full canonical validation passed')
  check(identical(normalized_hash(file.path(work, 'R/z_specmill_request.R')),
    digest::digest(scaffold$code, algo = 'sha256', serialize = FALSE)), 'Helper is exact official scaffold')
  manifest <- jsonlite::read_json(file.path(work, '.specmill/manifest.json'))
  for (file in names(manifest$files)) {
    check(identical(normalized_hash(file.path(work, file)), manifest$files[[file]]$hash), paste('Owner hash', file))
  }
  env <- new.env(parent = baseenv())
  for (file in list.files(file.path(work, 'R'), full.names = TRUE)) sys.source(file, env)
  for (row in rows) {
    old <- new.env(parent = baseenv())
    sys.source(file.path('dev/chet-admin-auth/held-generated', paste0(row$name, '.R')), old)
    check(identical(formals(env[[row$name]]), formals(old[[row$name]])), paste(row$name, 'unchanged public formals'))
    check(identical(names(formals(env[[row$name]])), 'body'), paste(row$name, 'required body only, no defaults'))
    check(identical(readLines(file.path(work, 'R', paste0(row$name, '.R'))),
      readLines(file.path('dev/chet-admin-auth/held-generated', paste0(row$name, '.R')))),
      paste(row$name, 'entire generated wrapper matches held wrapper'))
  }
  directory <- tempfile('http-', tmpdir = cache)
  dir.create(directory)
  response <- list(status = 200L, media = 'application/json', body = '{"ok":true}')
  saveRDS(response, file.path(directory, 'response.rds'))
  server <- callr::r_bg(function(directory) {
    n <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      n <<- n + 1L
      saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, query = req$QUERY_STRING,
        content_type = req$CONTENT_TYPE, cookie = req$HTTP_COOKIE, authorization = req$HTTP_AUTHORIZATION,
        body = req$rook.input$read()), file.path(directory, paste0(n, '.rds')))
      response <- readRDS(file.path(directory, 'response.rds'))
      list(status = response$status, headers = list(`Content-Type` = response$media), body = response$body)
    }))
    saveRDS(port, file.path(directory, 'ready.rds'))
    repeat httpuv::service(50)
  }, args = list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, 'ready.rds')) || !server$is_alive()) break
    Sys.sleep(0.05)
  }
  check(file.exists(file.path(directory, 'ready.rds')), 'Real localhost listener ready')
  origin <- paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')))
  withr::local_options(list(ComptoxR.chemi_burl = origin, comptoxr_native.request = list(timeout = 3, max_retries = 0L),
    comptoxr_native.dry_run = FALSE, comptoxr_native.run_verbose = FALSE, comptoxr_native.response_policy = NULL))
  requests <- 0L
  rejected <- 0L
  wires <- list()
  transport <- list()
  wire_check <- function(row, expected) {
    requests <<- requests + 1L
    wire <- readRDS(file.path(directory, paste0(requests, '.rds')))
    check(identical(wire$method, 'POST'), paste(row$name, 'exact POST'))
    check(identical(wire$path, paste0('/api/chet', sub('^POST ', '', row$key))), paste(row$name, 'exact path'))
    check(wire$query %in% c('', '?'), paste(row$name, 'absent query'))
    check(identical(wire$content_type, 'application/x-www-form-urlencoded'), paste(row$name, 'exact media'))
    check(identical(wire$body, charToRaw(expected)), paste(row$name, 'exact raw form bytes'))
    check(is.null(wire$cookie) && is.null(wire$authorization), paste(row$name, 'no invented session or credentials'))
    wires[[requests]] <<- list(method = wire$method, path = wire$path, content_type = wire$content_type,
      body = rawToChar(wire$body))
  }
  reject <- function(fn, args, label, class = 'error') {
    error <- tryCatch(do.call(fn, args), error = identity)
    check(inherits(error, class), paste(label, 'error class', class))
    Sys.sleep(0.02)
    check(!file.exists(file.path(directory, paste0(requests + 1L, '.rds'))), paste(label, 'zero HTTP'))
    rejected <<- rejected + 1L
    invisible(error)
  }
  body <- list(username = 'invented localhost user', password = 'fixture only', count = 2L,
    fraction = 1.5, yes = TRUE, no = FALSE, blank = '', punctuation = 'a&b=+/?', `field &` = 'caf\u00e9')
  expected <- paste0('username=invented%20localhost%20user&password=fixture%20only&count=2&fraction=1.5',
    '&yes=true&no=false&blank=&punctuation=a%26b%3D%2B%2F%3F&field%20%26=caf%C3%A9')
  invalid <- list(null = NULL, na_string = NA_character_, na_number = NA_real_, na_bool = NA,
    inf = Inf, negative_inf = -Inf, nan = NaN, empty = character(), vector = c('a', 'b'),
    numeric_vector = c(1, 2), list = list('a'), nested = list(nested = 'a'), raw = as.raw(1), date = as.Date('2026-01-01'))
  for (row in rows) {
    fn <- env[[row$name]]
    check(identical(fn(body), list(ok = TRUE)), paste(row$name, 'decoded JSON'))
    wire_check(row, expected)
    fn(list())
    wire_check(row, '')
    fn(list(note = 'only this field'))
    wire_check(row, 'note=only%20this%20field')
    reject(fn, list(), paste(row$name, 'omitted body'))
    for (name in names(invalid)) reject(fn, list(body = setNames(list(invalid[[name]]), 'field')),
      paste(row$name, 'invalid field', name))
    for (bad in list(NULL, NA, 'scalar', c('a', 'b'), list('unnamed'))) {
      reject(fn, list(body = bad), paste(row$name, 'invalid body', deparse(bad)[[1L]]))
    }
    for (bad in list(list(timeout = -1), list(max_retries = 0.5), list(preserve_errors = 'yes'),
      list(base_url = 'file:///tmp/held'), list(unknown = TRUE), list(throttle = list(capacity = 0, fill_time_s = 1)))) {
      withr::with_options(list(comptoxr_native.request = bad),
        reject(fn, list(body = body), paste(row$name, 'invalid request controls', paste(names(bad), collapse = ',')), 'specmill_call_error'))
    }
    withr::with_options(list(comptoxr_native.dry_run = NA),
      reject(fn, list(body = body), paste(row$name, 'invalid dry_run'), 'specmill_call_error'))
    withr::with_options(list(ComptoxR.chemi_burl = 'file:///tmp/held'),
      reject(fn, list(body = body), paste(row$name, 'invalid client endpoint')))
    for (status in c(400L, 404L, 500L, 401L)) {
      response$status <- status
      response$body <- '{"error":"localhost sentinel"}'
      saveRDS(response, file.path(directory, 'response.rds'))
      error <- tryCatch(fn(body), error = identity)
      check(inherits(error, if (status == 401L) 'specmill_call_error' else paste0('httr2_http_', status)),
        paste(row$name, 'HTTP error', status))
      if (status == 401L) {
        check(grepl('HTTP 401 application/json', conditionMessage(error), fixed = TRUE), paste(row$name, 'hard401 diagnostic'))
      } else {
        check(identical(httr2::resp_status(error$resp), status), paste(row$name, 'typed HTTP status'))
        check(identical(httr2::resp_body_json(error$resp), list(error = 'localhost sentinel')), paste(row$name, 'HTTP body retained'))
      }
      wire_check(row, expected)
      withr::with_options(list(comptoxr_native.request = list(timeout = 3, max_retries = 0L, preserve_errors = FALSE)), {
        error <- tryCatch(fn(body), error = identity)
        check(inherits(error, if (status == 401L) 'specmill_call_error' else 'simpleError'),
          paste(row$name, 'native preserve_errors FALSE', status))
        check(!inherits(error, 'httr2_http'), paste(row$name, 'runtime override suppresses typed HTTP', status))
        wire_check(row, expected)
      })
    }
    response$status <- 200L
    response$body <- '{"ok":true}'
    saveRDS(response, file.path(directory, 'response.rds'))
    withr::with_options(list(ComptoxR.chemi_burl = 'file:///invalid',
      comptoxr_native.request = list(base_url = paste0(origin, '/api/chet'), timeout = 3, max_retries = 0L)), {
      check(identical(fn(body), list(ok = TRUE)), paste(row$name, 'explicit base_url overrides resolver'))
      wire_check(row, expected)
    })
  }
  # Stop our own listener: transport failures use its now-closed localhost port.
  server$kill()
  for (row in rows) {
    error <- tryCatch(env[[row$name]](body), error = identity)
    check(inherits(error, 'httr2_failure'), paste(row$name, 'typed actual transport error'))
    check(inherits(error$parent, 'curl_error'), paste(row$name, 'original curl parent'))
    transport[[row$name]] <- list(class = class(error), parent_class = class(error$parent))
  }
  check(identical(hash('schema/chemi-chet-prod.json'), canonical_hash), 'Root canonical schema unchanged after replay')
  validation <- fresh$validation
  names(validation) <- sub(paste0(work, '/'), '', names(validation), fixed = TRUE)
  for (name in names(validation)) validation[[name]]$source <- name
  proof <- list(source_commit = sha, archive_sha256 = hash(file.path(cache, 'source.tar.gz')),
    source_archive = paste0('https://api.github.com/repos/seanthimons/specmill/tarball/', sha),
    candidate_version = as.character(utils::packageVersion('specmill', lib.loc = lib)),
    validation_enabled = TRUE, validation = validation, fresh = TRUE, owners = manifest$files,
    canonical_sha256 = canonical_hash, scaffold_sha256 = hash(file.path(work, 'R/z_specmill_request.R')),
    assertions = count, failures = 0L, errors = 0L, warnings = 0L, skips = 0L,
    http_requests = requests, zero_http_rejections = rejected, transport_failures = length(rows),
    localhost_only = TRUE, configs_directory_present = dir.exists('dev/chet-admin-auth/held-generated/configs'),
    configs_reconstructed_from_held_records = TRUE, wires = wires, transport = transport, checks = checks)
  jsonlite::write_json(proof, file.path(out, 'results.json'), auto_unbox = TRUE, pretty = TRUE, null = 'null')
  dir.create(file.path(out, 'generated'), showWarnings = FALSE)
  for (row in rows) file.copy(file.path(work, 'R', paste0(row$name, '.R')), file.path(out, 'generated'), overwrite = TRUE)
  file.copy(file.path(work, 'apis/held.yml'), file.path(out, 'held.yml'), overwrite = TRUE)
  file.copy(file.path(work, '.specmill/manifest.json'), file.path(out, 'private-manifest.json'), overwrite = TRUE)
  cat(count, 'assertions passed;', requests, 'localhost HTTP requests;', rejected, 'zero-HTTP rejections; 3 transport failures.\n')
}
withCallingHandlers(replay_pr180(), warning = function(w) stop(w))
