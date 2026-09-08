verify_local_runtime <- function(client) {
  stopifnot(!'wrapmaint' %in% loadedNamespaces(), !'ComptoxR' %in% loadedNamespaces())
  local <- if (is.environment(client)) client else new.env(parent = baseenv())
  if (!is.environment(client)) {
    sys.source(client, envir = local)
  }
  calls <- list()
  mock <- function(req) {
    calls[[length(calls) + 1L]] <<- req
    httr2::response(200, headers = list('content-type' = 'application/json'), body = charToRaw('{"ok":true}'))
  }
  httr2::with_mocked_responses(mock, {
    stopifnot(httr2::resp_status(local$get_item('a/b', language = 'en us')) == 200L)
    stopifnot(httr2::resp_status(local$create_item(list(title = 'Example'))) == 200L)
    stopifnot(httr2::resp_status(local$refresh()) == 200L)
  })
  stopifnot(
    identical(calls[[1]]$method, 'GET'),
    identical(calls[[1]]$url, 'https://local.invalid/api/items/a%2Fb?language=en%20us'),
    identical(calls[[2]]$method, 'POST'),
    identical(calls[[2]]$url, 'https://local.invalid/api/items'),
    identical(calls[[2]]$body$data, list(title = 'Example')),
    identical(calls[[3]]$method, 'POST'),
    identical(calls[[3]]$url, 'https://local.invalid/api/refresh')
  )
  failed <- try(httr2::with_mocked_responses(function(req) httr2::response(404), local$refresh()), silent = TRUE)
  stopifnot(inherits(failed, 'try-error'), !'wrapmaint' %in% loadedNamespaces(), !'ComptoxR' %in% loadedNamespaces())
  cat(
    'Fresh runtime: 3 mocked HTTP requests, encoded path/query, JSON body, propagated HTTP error; no toolkit or ComptoxR loaded.\n'
  )
}

verify_local_client <- function(root = '.') {
  root <- normalizePath(root, winslash = '/', mustWork = TRUE)
  context <- new.env(parent = globalenv())
  sys.source(file.path(root, 'dev/generate_local_client.R'), envir = context)
  input <- tempfile('local-input-')
  dir.create(input)
  fixture <- system.file('catalogue/schema.json', package = 'wrapmaint', mustWork = TRUE)
  file.copy(fixture, file.path(input, 'catalogue.json'))
  output <- tempfile('local-output-')
  generate <- function(target, schema = 'catalogue.json') {
    context$generate_local_client(root, input, schema, target, 'https://local.invalid/api', 'localcataloguegenerated')
  }
  protected <- file.path(root, 'local-client-must-not-exist')
  stopifnot(inherits(try(generate(protected), silent = TRUE), 'try-error'), !file.exists(protected))
  checkout <- tempfile('other-checkout-')
  dir.create(checkout)
  writeLines('Package: ComptoxR', file.path(checkout, 'DESCRIPTION'))
  stopifnot(inherits(try(generate(file.path(checkout, 'client')), silent = TRUE), 'try-error'))
  first <- generate(output)
  stopifnot(length(first$operations) == 4L, length(first$diagnostics) == 0L)
  hash_output <- function(path) {
    unname(tools::md5sum(list.files(path, full.names = TRUE, recursive = TRUE, all.files = TRUE)))
  }
  hashes <- hash_output(output)
  stopifnot(
    inherits(try(generate(output), silent = TRUE), 'try-error'),
    identical(hashes, hash_output(output))
  )
  second <- tempfile('local-second-')
  generate(second)
  stopifnot(identical(hashes, hash_output(second)))
  document <- jsonlite::read_json(file.path(input, 'catalogue.json'))
  document$paths[['/unsupported']] <- list(
    get = list(
      operationId = 'unsupported_header',
      parameters = list(list(name = 'X-Mode', 'in' = 'header', schema = list(type = 'string')))
    )
  )
  jsonlite::write_json(document, file.path(input, 'unsupported.json'), auto_unbox = TRUE)
  diagnostic <- generate(tempfile('local-unsupported-'), 'unsupported.json')
  stopifnot(length(diagnostic$operations) == 4L, length(diagnostic$diagnostics) == 1L)
  runner <- file.path(root, 'dev/migration-evidence/verify-local-client.R')
  status <- system2(
    file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'Rscript.exe' else 'Rscript'),
    c('--vanilla', shQuote(runner), '--runtime', shQuote(file.path(output, 'client.R')))
  )
  stopifnot(status == 0L)
  verify_local_install(output, runner)
  cat(
    'Local generation: public-root rejection, existing-output preservation, deterministic output and unsupported-operation report passed.\n'
  )
}

verify_frozen_alerts_runtime <- function(client) {
  stopifnot(!'wrapmaint' %in% loadedNamespaces(), !'ComptoxR' %in% loadedNamespaces())
  local <- if (is.environment(client)) client else new.env(parent = baseenv())
  if (!is.environment(client)) {
    sys.source(client, envir = local)
  }
  mock <- function(req) {
    stopifnot(identical(req$method, 'GET'), identical(req$url, 'https://local.invalid/api/alerts/groups/a%2Fb'))
    httr2::response(200, headers = list('content-type' = 'application/json'), body = charToRaw('{"id":"a/b"}'))
  }
  response <- httr2::with_mocked_responses(mock, local$groupGet('a/b'))
  stopifnot(
    identical(httr2::resp_body_json(response)$id, 'a/b'),
    !'wrapmaint' %in% loadedNamespaces(),
    !'ComptoxR' %in% loadedNamespaces()
  )
  cat('Frozen alerts client: mocked GET, encoded path and JSON response passed without toolkit or ComptoxR.\n')
}

verify_local_install <- function(package_root, runner, library_dir = tempfile('local-library-')) {
  dir.create(library_dir, recursive = TRUE, showWarnings = FALSE)
  dependencies <- unique(c(
    c('httr2', 'jsonlite'),
    unlist(tools::package_dependencies(
      c('httr2', 'jsonlite'),
      db = installed.packages(),
      which = c('Depends', 'Imports', 'LinkingTo'),
      recursive = TRUE
    ))
  ))
  for (package in setdiff(dependencies, 'R')) {
    path <- find.package(package)
    if (!startsWith(normalizePath(path, winslash = '/'), normalizePath(.Library, winslash = '/'))) {
      stopifnot(file.copy(path, library_dir, recursive = TRUE))
    }
  }
  status <- system2(
    file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'R.exe' else 'R'),
    c('CMD', 'INSTALL', paste0('--library=', shQuote(library_dir)), shQuote(package_root))
  )
  stopifnot(status == 0L)
  package <- read.dcf(file.path(package_root, 'DESCRIPTION'))[1, 'Package']
  status <- system2(
    file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'Rscript.exe' else 'Rscript'),
    c('--vanilla', shQuote(runner), '--installed', shQuote(library_dir), shQuote(package))
  )
  stopifnot(status == 0L)
  cat('Installed local package checked in isolated library:', library_dir, '\n')
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) && args[[1]] == '--runtime') {
    verify_local_runtime(args[[2]])
  } else if (length(args) && args[[1]] == '--alerts') {
    verify_frozen_alerts_runtime(args[[2]])
  } else if (length(args) && args[[1]] == '--install-alerts') {
    verify_local_install(args[[2]], normalizePath('dev/migration-evidence/verify-local-client.R'), args[[3]])
  } else if (length(args) && args[[1]] == '--installed') {
    .libPaths(c(args[[2]], .Library))
    stopifnot(!requireNamespace('wrapmaint', quietly = TRUE), !requireNamespace('ComptoxR', quietly = TRUE))
    local <- asNamespace(args[[3]])
    if (args[[3]] == 'localcataloguegenerated') verify_local_runtime(local) else verify_frozen_alerts_runtime(local)
  } else {
    verify_local_client()
  }
}
