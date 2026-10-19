# Official50 native cached facades versus frozen originals, with independent caches and real HTTP.
test_that('PubChem native facades preserve actual requests, caches and Fault warnings', {
  skip_if_not_installed('httpuv')
  skip_if_not_installed('callr')
  frozen <- readRDS(test_path('fixtures/pubchem-retained-originals.rds'))
  directory <- tempfile('pubchem-http-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  saveRDS(
    list(status = 200L, mode = 'success'),
    file.path(directory, 'control.rds')
  )
  server <- callr::r_bg(
    function(directory) {
      port <- httpuv::randomPort()
      calls <- list()
      httpuv::startServer(
        '127.0.0.1',
        port,
        list(call = function(request) {
          body <- rawToChar(request$rook.input$read())
          path <- request$PATH_INFO
          calls[[length(calls) + 1L]] <<- list(
            method = request$REQUEST_METHOD,
            path = path,
            url = paste0('http://', request$HTTP_HOST, path),
            body = body,
            media = request$CONTENT_TYPE,
            agent = request$HTTP_USER_AGENT,
            has_auth = !is.null(request$HTTP_AUTHORIZATION),
            has_key = !is.null(request$HTTP_X_API_KEY) ||
              !is.null(request$HTTP_API_KEY),
            has_cookie = !is.null(request$HTTP_COOKIE)
          )
          saveRDS(calls, file.path(directory, 'calls.rds'))
          control <- readRDS(file.path(directory, 'control.rds'))
          value <- if (control$mode == 'invalid') {
            '{'
          } else if (control$mode == 'missing') {
            '{}'
          } else if (control$mode == 'fault') {
            '{"Fault":{"Code":"PUGREST.NotFound","Message":"sentinel"}}'
          } else if (grepl('/cids/JSON$', path)) {
            '{"IdentifierList":{"CID":[2244,6623]}}'
          } else {
            cid <- if (request$REQUEST_METHOD == 'POST') {
              utils::URLdecode(sub('^cid=', '', body))
            } else {
              sub('^.*/compound/cid/([^/]+)/.*$', '\\1', path)
            }
            ids <- as.integer(strsplit(cid, ',', fixed = TRUE)[[1L]])
            if (grepl('/synonyms/JSON$', path)) {
              jsonlite::toJSON(
                list(
                  InformationList = list(
                    Information = lapply(ids, function(id) {
                      list(CID = id, Synonym = c('aspirin', 'ASA'))
                    })
                  )
                ),
                auto_unbox = TRUE
              )
            } else {
              jsonlite::toJSON(
                list(
                  PropertyTable = list(
                    Properties = lapply(ids, function(id) {
                      list(CID = id, XLogP = 1.2)
                    })
                  )
                ),
                auto_unbox = TRUE
              )
            }
          }
          list(
            status = control$status,
            headers = list(`Content-Type` = 'application/json'),
            body = value
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
  expect_true(
    file.exists(file.path(directory, 'ready.rds')),
    info = server$read_error()
  )
  withr::local_options(list(
    ComptoxR.pubchem_burl = paste0(
      'http://127.0.0.1:',
      readRDS(file.path(directory, 'ready.rds'))
    ),
    ComptoxR.run_verbose = FALSE
  ))
  calls <- function() {
    if (file.exists(file.path(directory, 'calls.rds'))) {
      readRDS(file.path(directory, 'calls.rds'))
    } else {
      list()
    }
  }
  control <- function(mode = 'success', status = 200L) {
    saveRDS(
      list(mode = mode, status = status),
      file.path(directory, 'control.rds')
    )
  }
  make_client <- function(old) {
    env <- new.env(parent = asNamespace('ComptoxR'))
    env$.ComptoxREnv <- new.env(parent = emptyenv())
    for (name in names(frozen$functions)) {
      assign(
        name,
        if (old) {
          eval(frozen$functions[[name]], env)
        } else if (is.function(get(name, asNamespace('ComptoxR')))) {
          fn <- get(name, asNamespace('ComptoxR'))
          environment(fn) <- env
          fn
        } else {
          get(name, asNamespace('ComptoxR'))
        },
        env
      )
    }
    if (!old) {
      ns <- asNamespace('ComptoxR')
      names <- ls(ns, all.names = TRUE)
      for (name in names[startsWith(names, '.ct_pc_')]) {
        assign(name, get(name, ns), env)
      }
    }
    env
  }
  clients <- lapply(c(TRUE, FALSE), make_client)
  results <- lapply(clients, function(client) {
    all_start <- length(calls())
    start <- length(calls())
    search <- client$pubchem_search('aspirin')
    expect_identical(search$cid, c(2244L, 6623L))
    expect_identical(client$pubchem_search('aspirin'), search)
    expect_length(calls(), start + 1L)
    withr::with_options(list(ComptoxR.pubchem_burl = ''), {
      expect_identical(client$pubchem_search('aspirin'), search)
    })
    client$pubchem_search('C/C=C\\C#N', type = 'smiles', cache = FALSE)
    expect_identical(tail(calls(), 1L)[[1L]]$method, 'POST')
    expect_identical(tail(calls(), 1L)[[1L]]$body, 'smiles=C%2FC%3DC%5CC%23N')
    expect_identical(
      tail(calls(), 1L)[[1L]]$media,
      'application/x-www-form-urlencoded'
    )
    client$pubchem_search('a/b +#', type = 'name', cache = FALSE)
    expect_identical(tail(calls(), 1L)[[1L]]$method, 'GET')
    for (case in list(
      list(type = 'inchi', query = 'InChI=1S/CH4/h1H4'),
      list(type = 'inchikey', query = 'VNWKTOKETHGBQD-UHFFFAOYSA-N'),
      list(type = 'formula', query = 'CH4')
    )) {
      client$pubchem_search(case$query, type = case$type, cache = FALSE)
      wire <- tail(calls(), 1L)[[1L]]
      expect_identical(wire$method, if (case$type == 'inchi') 'POST' else 'GET')
      expect_identical(
        wire$path,
        if (case$type == 'inchi') {
          '/compound/inchi/cids/JSON'
        } else {
          paste0('/compound/', case$type, '/', case$query, '/cids/JSON')
        }
      )
      if (case$type == 'inchi') {
        expect_identical(wire$body, 'inchi=InChI%3D1S%2FCH4%2Fh1H4')
      }
    }
    properties <- client$pubchem_properties(1L, properties = 'XLogP')
    mixed <- client$pubchem_properties(c(2L, 1L), properties = 'XLogP')
    expect_identical(mixed$CID, c(1L, 2L))
    expect_identical(
      tail(calls(), 1L)[[1L]]$path,
      '/compound/cid/2/property/XLogP/JSON'
    )
    start <- length(calls())
    expect_identical(
      client$pubchem_properties(c(2L, 1L, 2L), properties = 'XLogP')$CID,
      c(2L, 1L, 2L)
    )
    expect_length(calls(), start)
    batch <- client$pubchem_properties(
      1:150,
      properties = 'XLogP',
      cache = FALSE
    )
    expect_identical(batch$CID, 1:150)
    expect_length(calls(), start + 2L)
    expect_true(all(vapply(
      tail(calls(), 2L),
      function(x) x$method == 'POST',
      logical(1)
    )))
    raw <- client$pubchem_synonyms(1L, tidy = FALSE)
    mixed_raw <- client$pubchem_synonyms(c(2L, 1L), tidy = FALSE)
    expect_identical(vapply(mixed_raw, `[[`, integer(1), 'CID'), c(1L, 2L))
    expect_identical(
      tail(calls(), 1L)[[1L]]$path,
      '/compound/cid/2/synonyms/JSON'
    )
    start <- length(calls())
    tidy <- client$pubchem_synonyms(c(2L, 1L))
    expect_identical(tidy$cid, c(2L, 2L, 1L, 1L))
    expect_length(calls(), start)
    expect_error(
      client$pubchem_properties(
        stop('cid forced'),
        '../invalid',
        cache = stop('cache forced')
      ),
      'Invalid PubChem property'
    )
    expect_error(
      client$pubchem_search('', cache = stop('cache forced')),
      'single non-empty'
    )
    expect_error(
      client$pubchem_synonyms(
        NA_integer_,
        tidy = stop('tidy forced'),
        cache = stop('cache forced')
      ),
      'at least one valid integer'
    )
    # Property-set keys, duplicate inputs and the final one-item POST chunk.
    property_set <- client$pubchem_properties(
      251L,
      properties = c('XLogP', 'MolecularWeight')
    )
    expect_identical(
      tail(calls(), 1L)[[1L]]$path,
      '/compound/cid/251/property/MolecularWeight,XLogP/JSON'
    )
    start <- length(calls())
    expect_identical(
      client$pubchem_properties(
        251L,
        properties = c('MolecularWeight', 'XLogP')
      ),
      property_set
    )
    expect_length(calls(), start)
    many <- client$pubchem_properties(
      300:500,
      properties = 'XLogP',
      cache = FALSE
    )
    expect_identical(many$CID, 300:500)
    expect_length(calls(), start + 3L)
    expect_true(all(vapply(
      tail(calls(), 3L),
      function(x) x$method == 'POST',
      logical(1)
    )))
    expect_identical(tail(calls(), 1L)[[1L]]$body, 'cid=500')
    duplicate <- client$pubchem_properties(c(600L, 600L), properties = 'XLogP')
    expect_identical(duplicate$CID, c(600L, 600L))
    start <- length(calls())
    many_synonyms <- client$pubchem_synonyms(
      701:901,
      tidy = FALSE,
      cache = FALSE
    )
    expect_identical(
      vapply(many_synonyms, `[[`, integer(1), 'CID'),
      stats::setNames(701:901, names(many_synonyms))
    )
    expect_length(calls(), start + 3L)
    expect_true(all(vapply(
      tail(calls(), 3L),
      function(x) x$method == 'POST' && x$path == '/compound/cid/synonyms/JSON',
      logical(1)
    )))
    expect_identical(tail(calls(), 1L)[[1L]]$body, 'cid=901')
    expect_error(
      client$pubchem_synonyms(700L, tidy = stop('late tidy')),
      'late tidy'
    )
    expect_true(exists(
      '700',
      envir = client$.ComptoxREnv$pubchem_syns_cache,
      inherits = FALSE
    ))
    start <- length(calls())
    expect_identical(
      client$pubchem_synonyms(700L, tidy = FALSE)[[1L]]$CID,
      700L
    )
    expect_length(calls(), start)
    control('fault', 404L)
    missing_warnings <- character()
    empty <- withCallingHandlers(
      client$pubchem_search('missing'),
      warning = function(w) {
        missing_warnings <<- c(missing_warnings, conditionMessage(w))
        invokeRestart('muffleWarning')
      }
    )
    expect_length(missing_warnings, 2L)
    expect_match(missing_warnings[[1L]], 'PUGREST.NotFound')
    expect_match(missing_warnings[[2L]], 'No PubChem CIDs found')
    # The first warning is the HTTP Fault; both are compared below without alteration.
    start <- length(calls())
    expect_silent(expect_identical(client$pubchem_search('missing'), empty))
    expect_length(calls(), start)
    # An empty property table must not invent cache entries.
    failed_property <- withCallingHandlers(
      client$pubchem_properties(990L, properties = 'XLogP'),
      warning = function(w) invokeRestart('muffleWarning')
    )
    expect_identical(failed_property, tibble::tibble())
    expect_false(exists(
      '990|XLogP',
      envir = client$.ComptoxREnv$pubchem_props_cache,
      inherits = FALSE
    ))
    conditions <- list()
    for (case in list(
      list('fault', 200L),
      list('invalid', 200L),
      list('missing', 200L)
    )) {
      control(case[[1L]], case[[2L]])
      warnings <- list()
      value <- withCallingHandlers(
        client$pubchem_synonyms(999L, tidy = FALSE, cache = FALSE),
        warning = function(w) {
          warnings[[length(warnings) + 1L]] <<- list(
            class = class(w),
            message = conditionMessage(w)
          )
          invokeRestart('muffleWarning')
        }
      )
      expect_identical(value, list())
      expect_length(warnings, 1L)
      conditions[[length(conditions) + 1L]] <- list(
        value = value,
        warnings = warnings
      )
    }
    observed <- calls()[seq.int(all_start + 1L, length(calls()))]
    expect_false(any(vapply(
      observed,
      function(w) w$has_auth || w$has_key || w$has_cookie,
      logical(1)
    )))
    expected_agent <- paste0(
      'ComptoxR/',
      as.character(utils::packageVersion('ComptoxR')),
      ' (https://github.com/seanthimons/ComptoxR)'
    )
    expect_true(all(vapply(
      observed,
      function(w) identical(w$agent, expected_agent),
      logical(1)
    )))
    control()
    list(
      search = search,
      properties = properties,
      mixed = mixed,
      batch = batch,
      raw = raw,
      mixed_raw = mixed_raw,
      tidy = tidy,
      conditions = conditions,
      many = many,
      many_synonyms = many_synonyms,
      property_set = property_set,
      duplicate = duplicate
    )
  })
  expect_identical(results[[1L]], results[[2L]])
  control('fault', 401L)
  expect_error(
    clients[[2L]]$pubchem_synonyms(999L, tidy = FALSE, cache = FALSE),
    class = 'specmill_call_error'
  )
  expect_error(
    clients[[2L]]$pubchem_synonyms(c(999L, 1000L), tidy = FALSE, cache = FALSE),
    class = 'specmill_call_error'
  )
  control()
  native <- clients[[2L]]
  # Runtime overrides use the real shared httr2 pool, without timing assertions.
  withr::with_options(list(comptoxr_native.dry_run = TRUE), {
    requests <- list(
      native$pubchem_search('policy', cache = FALSE),
      native$pubchem_properties(800L, properties = 'XLogP', cache = FALSE),
      native$pubchem_synonyms(800L, cache = FALSE)
    )
    original <- httr2::req_throttle(
      httr2::request(getOption('ComptoxR.pubchem_burl')),
      capacity = 4,
      fill_time_s = 1
    )
    for (req in requests) {
      expect_identical(
        req$policies$throttle_realm,
        original$policies$throttle_realm
      )
      expect_equal(req$policies$retry_max_tries, 4)
    }
  })
  realm <- 'comptoxr-pubchem-native-private'
  withr::with_options(
    list(
      comptoxr_native.request = list(
        max_retries = 0L,
        throttle = list(capacity = 100L, fill_time_s = 1e9, realm = realm)
      )
    ),
    {
      native$pubchem_search('pool', cache = FALSE)
      native$pubchem_properties(
        c(810L, 811L),
        properties = 'XLogP',
        cache = FALSE
      )
      native$pubchem_synonyms(810L, tidy = FALSE)
      pool <- httr2::throttle_status()
      expect_equal(pool$tokens[pool$realm == realm], 97, tolerance = .01)
      start <- length(calls())
      native$pubchem_synonyms(810L, tidy = FALSE)
      expect_length(calls(), start)
      pool <- httr2::throttle_status()
      expect_equal(pool$tokens[pool$realm == realm], 97, tolerance = .01)
    }
  )
  start <- length(calls())
  withr::with_options(list(comptoxr_native.request = list(timeout = -1)), {
    expect_error(
      native$pubchem_search('bad control', cache = FALSE),
      class = 'specmill_call_error'
    )
    expect_identical(native$pubchem_search('aspirin'), results[[2L]]$search)
  })
  expect_length(calls(), start)
  # Cold requests must preserve complete configured base URL prefixes.
  prefix_cases <- list(
    list(name = 'pubchem_search', args = list(query = 'prefix-cold', cache = FALSE), method = 'GET', path = '/compound/name/prefix-cold/cids/JSON'),
    list(name = 'pubchem_search', args = list(query = 'C=C', type = 'smiles', cache = FALSE), method = 'POST', path = '/compound/smiles/cids/JSON'),
    list(name = 'pubchem_properties', args = list(cid = 9101L, properties = 'XLogP', cache = FALSE), method = 'GET', path = '/compound/cid/9101/property/XLogP/JSON'),
    list(name = 'pubchem_properties', args = list(cid = c(9101L, 9102L), properties = 'XLogP', cache = FALSE), method = 'POST', path = '/compound/cid/property/XLogP/JSON'),
    list(name = 'pubchem_synonyms', args = list(cid = 9101L, tidy = FALSE, cache = FALSE), method = 'GET', path = '/compound/cid/9101/synonyms/JSON'),
    list(name = 'pubchem_synonyms', args = list(cid = c(9101L, 9102L), tidy = FALSE, cache = FALSE), method = 'POST', path = '/compound/cid/synonyms/JSON')
  )
  origin <- paste0('http://127.0.0.1:', readRDS(file.path(directory, 'ready.rds')))
  control()
  for (prefix in c('/rest/pug', '/custom/pug-v2')) {
    withr::with_options(list(ComptoxR.pubchem_burl = paste0(origin, prefix)), {
      for (case in prefix_cases) {
        route_calls <- lapply(clients, function(client) {
          start <- length(calls())
          do.call(client[[case$name]], case$args)
          expect_length(calls(), start + 1L)
          tail(calls(), 1L)[[1L]]
        })
        expect_identical(route_calls[[2L]], route_calls[[1L]])
        expect_identical(route_calls[[2L]]$method, case$method)
        expect_identical(route_calls[[2L]]$url, paste0(origin, prefix, case$path))
      }
    })
  }
  start <- length(calls())
  withr::with_envvar(c(pubchem_burl = ''), {
    withr::with_options(list(ComptoxR.pubchem_burl = NULL, comptoxr_native.dry_run = TRUE), {
      for (case in prefix_cases) {
        request <- do.call(native[[case$name]], case$args)
        if (!inherits(request, 'httr2_request')) {
          expect_length(request, 1L)
          request <- request[[1L]]
        }
        expect_s3_class(request, 'httr2_request')
        expect_identical(httr2::req_get_url(request), paste0('https://pubchem.ncbi.nlm.nih.gov/rest/pug', case$path))
      }
    })
  })
  expect_length(calls(), start)
  server$kill()
  for (args in list(
    list(name = 'pubchem_search', args = list(query = 'closed', cache = FALSE)),
    list(
      name = 'pubchem_properties',
      args = list(cid = 9991L, properties = 'XLogP', cache = FALSE)
    ),
    list(
      name = 'pubchem_synonyms',
      args = list(cid = 9991L, tidy = FALSE, cache = FALSE)
    )
  )) {
    errors <- lapply(clients, function(client) {
      tryCatch(do.call(client[[args$name]], args$args), error = identity)
    })
    expect_s3_class(errors[[1L]], 'httr2_failure')
    expect_identical(class(errors[[2L]]), class(errors[[1L]]))
    expect_identical(class(errors[[2L]]$parent), class(errors[[1L]]$parent))
  }
  errors <- lapply(clients, function(client) {
    tryCatch(
      client$pubchem_properties(
        c(9991L, 9992L),
        properties = 'XLogP',
        cache = FALSE
      ),
      error = identity
    )
  })
  expect_s3_class(errors[[1L]], 'purrr_error_indexed')
  expect_s3_class(errors[[2L]], 'purrr_error_indexed')
  expect_identical(class(errors[[2L]]$parent), class(errors[[1L]]$parent))
  for (name in c('pubchem_properties', 'pubchem_search', 'pubchem_synonyms')) {
    expect_identical(
      formals(get(name, clients[[1L]])),
      formals(get(name, clients[[2L]]))
    )
  }
  evidence <- Sys.getenv('PUBCHEM_NATIVE_EVIDENCE', '')
  if (nzchar(evidence)) {
    saveRDS(list(calls = calls(), comparisons = results), evidence, version = 3)
  }
})
