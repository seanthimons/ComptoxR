chet_extra_wrappers <- c(
  'chemi_chet_chemicals_chemdelete',
  'chemi_chet_chemicals_chemical_dl_post',
  'chemi_chet_chemicals_newchemfile',
  'chemi_chet_chemicals_newchemical',
  'chemi_chet_chemicals_template_dl',
  'chemi_chet_curators_change_password',
  'chemi_chet_curators_detail_sets',
  'chemi_chet_curators_details',
  'chemi_chet_curators_libraries',
  'chemi_chet_curators_libraries_detail_options',
  'chemi_chet_curators_libraries_by_lib_id',
  'chemi_chet_curators_login',
  'chemi_chet_curators_logout',
  'chemi_chet_curators_units',
  'chemi_chet_curators_units_create',
  'chemi_chet_reaction_download_db_backup',
  'chemi_chet_reaction_editor_check_existing',
  'chemi_chet_reaction_editor_check_existing_map',
  'chemi_chet_reaction_editor_library_details',
  'chemi_chet_reaction_editor_load_map',
  'chemi_chet_reaction_editor_load_reactions',
  'chemi_chet_reaction_editor_save_scheme',
  'chemi_chet_reaction_editor_by_reaction_id',
  'chemi_chet_reaction_editor_by_reaction_id_create',
  'chemi_chet_reaction_map_dl',
  'chemi_chet_reaction_mapfix_by_map_id',
  'chemi_chet_reaction_newlibrary',
  'chemi_chet_reaction_newreactfile',
  'chemi_chet_reaction_newreaction',
  'chemi_chet_reaction_reaction_dl',
  'chemi_chet_reaction_reactiondelete',
  'chemi_chet_reaction_template_dl',
  'chemi_chet_reaction_visibility')

test_that('chet_extra bindings validate inputs and preserve actual localhost wire contracts', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  cases <- readRDS(test_path('fixtures/native-chet-extra.rds'))
  expect_setequal(names(cases), chet_extra_wrappers)
  directory <- tempfile('chet_extra-http-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  response <- list(status = 200L, media = 'application/json', body = charToRaw('{"ok":true,"items":[1,2]}'))
  saveRDS(response, file.path(directory, 'response.rds'))
  server <- callr::r_bg(function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer('127.0.0.1', port, list(call = function(req) {
      count <<- count + 1L
      body <- req$rook.input$read()
      saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO,
        query = req$QUERY_STRING, content_type = req$CONTENT_TYPE,
        accept = req$HTTP_ACCEPT, body = body), file.path(directory, paste0(count, '.rds')))
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
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds'))),
    comptoxr_native.request = list(max_retries = 0L, timeout = 5)))
  count <- 0L
  invoke <- function(fn, args) {
    count <<- count + 1L
    value <- do.call(fn, args)
    list(value = value, wire = readRDS(file.path(directory, paste0(count, '.rds'))))
  }
  # Split bytes rather than text, since uploaded files can contain NULs.
  multipart <- function(wire) {
    boundary <- sub('.*boundary=', '', wire$content_type)
    marker <- charToRaw(paste0('--', boundary))
    starts <- grepRaw(marker, wire$body, fixed = TRUE, all = TRUE)
    parts <- list()
    for (i in seq_len(length(starts) - 1L)) {
      bytes <- wire$body[seq.int(starts[[i]] + length(marker) + 2L, starts[[i + 1L]] - 3L)]
      split <- grepRaw(charToRaw('\r\n\r\n'), bytes, fixed = TRUE)[[1L]]
      header <- rawToChar(bytes[seq_len(split - 1L)])
      name <- regmatches(header, regexec('; name="([^"]+)"', header))[[1L]][[2L]]
      parts[[name]] <- list(header = header, body = bytes[seq.int(split + 4L, length(bytes))])
    }
    parts
  }
  for (name in names(cases)) {
    case <- cases[[name]]
    fn <- get(name, asNamespace('ComptoxR'))
    if (file.exists(test_path('..', '..', 'specmill.yml'))) {
      expect_identical(digest::digest(file = test_path('../..', case$source), algo = 'sha256'), case$source_sha256)
    }
    result <- invoke(fn, case$args)
    expect_identical(result$value, list(ok = TRUE, items = list(1L, 2L)), info = name)
    expect_identical(result$wire$method, case$method, info = name)
    expect_identical(result$wire$path, case$path, info = name)
    expect_identical(result$wire$accept, '*/*', info = name)
    query <- httr2::url_parse(paste0('http://localhost/?', sub('^\\?', '', result$wire$query)))$query
    expected <- lapply(case$query, function(x) if (is.logical(x)) tolower(as.character(x)) else as.character(x))
    expect_equal(query, if (length(expected)) expected else NULL, info = name)
    if (is.null(case$body_media)) {
      expect_length(result$wire$body, 0L)
    } else if (case$body_media == 'application/json') {
      expect_match(result$wire$content_type, '^application/json', info = name)
      expect_identical(jsonlite::fromJSON(rawToChar(result$wire$body), simplifyVector = FALSE), case$args$body, info = name)
    } else {
      expect_match(result$wire$content_type, '^multipart/form-data; boundary=', info = name)
      parts <- multipart(result$wire)
      expect_setequal(names(parts), case$upload_field)
      upload <- parts[[case$upload_field]]
      expect_match(upload$header, 'Content-Type: application/octet-stream', ignore.case = TRUE)
      expect_identical(upload$body, case$args$body[[case$upload_field]])
      file <- file.path(directory, 'upload.bin')
      writeBin(case$args$body[[case$upload_field]], file)
      args <- case$args
      args$body[[case$upload_field]] <- curl::form_file(file)
      uploaded <- multipart(invoke(fn, args)$wire)
      expect_identical(uploaded[[case$upload_field]]$body, case$args$body[[case$upload_field]])
    }
    # A malformed declared input must fail before the localhost server sees it.
    if (length(case$args)) {
      invalid <- case$args
      field <- if ('body' %in% names(invalid)) 'body' else names(invalid)[[1L]]
      invalid[[field]] <- if (field == 'body') 'invalid object' else list('invalid scalar')
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    if ('body' %in% names(case$args)) {
      invalid <- case$args
      invalid$body <- NULL
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
      if (case$body_media == 'multipart/form-data') {
        invalid <- case$args
        invalid$body[[case$upload_field]] <- '/a/plain/path/is/not/a/binary/upload'
        expect_error(do.call(fn, invalid), info = name)
        expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
      }
    }
    if (name == 'chemi_chet_reaction_visibility') for (bad in list(
      list(reaction_id = '7', internal_only = FALSE),
      list(reaction_id = 7L, internal_only = 'false'), list(reaction_id = 7L))) {
      invalid <- case$args
      invalid$body <- bad
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    if (grepl('curators_(login|change_password)$', name)) {
      invalid <- case$args
      invalid$body[[names(invalid$body)[[1L]]]] <- NULL
      expect_error(do.call(fn, invalid), info = name)
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    for (bad in list(list(timeout = -1), list(max_retries = 0.5), list(preserve_errors = 'yes'))) {
      withr::with_options(list(comptoxr_native.request = bad), {
        expect_error(do.call(fn, case$args), class = 'specmill_call_error', info = name)
      })
      expect_false(file.exists(file.path(directory, paste0(count + 1L, '.rds'))), info = name)
    }
    for (status in c(400L, 401L, 404L, 500L)) {
      response$status <- status
      response$body <- charToRaw('{"error":"chet_extra sentinel"}')
      saveRDS(response, file.path(directory, 'response.rds'))
      count <- count + 1L
      error <- tryCatch(do.call(fn, case$args), error = identity)
      expect_s3_class(error, if (status == 401L) 'specmill_call_error' else paste0('httr2_http_', status))
      if (status == 401L) {
        expect_match(conditionMessage(error), 'HTTP 401 application/json', info = name)
      } else {
        expect_identical(httr2::resp_status(error$resp), status)
        expect_identical(httr2::resp_body_json(error$resp), list(error = 'chet_extra sentinel'))
      }
      expect_true(file.exists(file.path(directory, paste0(count, '.rds'))), info = name)
    }
    response$status <- 200L
    for (sample in list(
      list(media = 'image/svg+xml', body = charToRaw('<svg>sentinel</svg>'), value = '<svg>sentinel</svg>'),
      list(media = 'image/png', body = as.raw(c(137, 80, 78, 71, 0, 255)), value = as.raw(c(137, 80, 78, 71, 0, 255))),
      list(media = 'text/plain', body = charToRaw('report sentinel'), value = 'report sentinel'),
      list(media = 'application/json', body = charToRaw('{}'), value = stats::setNames(list(), character()))
    )) {
      response$media <- sample$media
      response$body <- sample$body
      saveRDS(response, file.path(directory, 'response.rds'))
      expect_identical(invoke(fn, case$args)$value, sample$value, info = name)
    }
    response$media <- 'application/json'
    response$body <- charToRaw('{"ok":true,"items":[1,2]}')
    saveRDS(response, file.path(directory, 'response.rds'))
  }
})
