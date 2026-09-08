#!/usr/bin/env Rscript
# Sourceable command. Generated output needs httr2, but no development toolkit.
generate_local_client <- function(repository_root, input_root, schema, output_root, base_url, package_name) {
  if (
    length(package_name) != 1L ||
      !grepl('^[A-Za-z][A-Za-z0-9.]*[A-Za-z0-9]$', package_name) ||
      tolower(package_name) %in% c('comptoxr', 'wrapmaint', 'httr2')
  ) {
    stop('Supply a distinct valid local package name')
  }
  repository_root <- fs::path_real(repository_root)
  input_root <- fs::path_real(input_root)
  if (read.dcf(file.path(repository_root, 'DESCRIPTION'))[1, 'Package'] != 'ComptoxR') {
    stop('repository_root must identify the ComptoxR checkout')
  }
  resolve_target <- function(path) {
    path <- fs::path_norm(fs::path_abs(path))
    ancestor <- path
    while (!dir.exists(ancestor)) {
      ancestor <- dirname(ancestor)
    }
    fs::path_norm(file.path(fs::path_real(ancestor), fs::path_rel(path, ancestor)))
  }
  within <- function(path, root) {
    path <- tolower(as.character(path))
    root <- tolower(as.character(root))
    identical(path, root) || startsWith(path, paste0(root, '/'))
  }
  output_root <- resolve_target(output_root)
  common <- system2('git', c('-C', shQuote(repository_root), 'rev-parse', '--git-common-dir'), stdout = TRUE)
  if (length(common) != 1L || !is.null(attr(common, 'status'))) {
    stop('Cannot identify the public repository')
  }
  public_root <- dirname(fs::path_real(fs::path_abs(common, start = repository_root)))
  ancestor <- output_root
  repeat {
    description <- file.path(ancestor, 'DESCRIPTION')
    if (file.exists(description) && read.dcf(description)[1, 'Package'] == 'ComptoxR') {
      stop('Local clients must be outside every ComptoxR checkout')
    }
    parent <- dirname(ancestor)
    if (identical(parent, ancestor)) {
      break
    }
    ancestor <- parent
  }
  if (within(output_root, repository_root) || within(output_root, public_root)) {
    stop('Local clients must be outside the public ComptoxR repository')
  }
  if (within(input_root, repository_root) || within(input_root, public_root)) {
    stop('Local schema inputs must be outside the public ComptoxR repository')
  }
  schema_path <- fs::path_real(file.path(input_root, schema))
  if (!within(schema_path, input_root)) {
    stop('Schema escapes input_root')
  }
  url <- httr2::url_parse(base_url)
  if (
    !url$scheme %in% c('http', 'https') ||
      is.null(url$hostname) ||
      !nzchar(url$hostname) ||
      !is.null(url$username) ||
      !is.null(url$password) ||
      length(url$query) ||
      !is.null(url$fragment)
  ) {
    stop('Supply an explicit HTTP(S) base URL without credentials, query or fragment')
  }
  if (
    file.exists(output_root) &&
      (!dir.exists(output_root) || length(list.files(output_root, all.files = TRUE, no.. = TRUE)))
  ) {
    stop('Use a new or empty local output directory')
  }
  stage <- tempfile('local-client-')
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  result <- wrapmaint::generate_client(
    stage,
    list(files = schema_path, helper = 'local_request', policy_version = 'local-explicit-url-1'),
    'apply'
  )
  if (any(names(result$operations) %in% c('local_request', 'local_base_url'))) {
    stop('Operation name conflicts with the local transport helper')
  }
  local_request <- function(method, path, path_params, query, body) {
    for (name in names(path_params)) {
      path <- gsub(
        paste0('{', name, '}'),
        utils::URLencode(as.character(path_params[[name]]), reserved = TRUE),
        path,
        fixed = TRUE
      )
    }
    request <- httr2::req_method(httr2::request(local_base_url), method)
    request <- do.call(httr2::req_url_query, c(list(request), query))
    suffix <- if (grepl('?', request$url, fixed = TRUE)) sub('^[^?]*', '', request$url) else ''
    request <- httr2::req_url(request, paste0(sub('/+$', '', local_base_url), '/', sub('^/+', '', path), suffix))
    if (!is.null(body)) {
      request <- httr2::req_body_json(request, body)
    }
    httr2::req_perform(request)
  }
  code <- c(
    '# Local client. Keep outside the public ComptoxR package.',
    paste0('local_base_url <- ', deparse(base_url)),
    paste0('local_request <- ', paste(deparse(local_request), collapse = '\n')),
    unlist(lapply(list.files(file.path(stage, 'R'), full.names = TRUE), readLines), use.names = FALSE)
  )
  parse(text = code)
  writeLines(code, file.path(stage, 'client.R'))
  writeLines(code[1:3], file.path(stage, 'R/local_request.R'))
  writeLines(
    c(
      paste0('Package: ', package_name),
      'Version: 0.0.0.9000',
      'Title: Explicitly Configured Local API Client',
      'Description: Local-only generated operations from a frozen schema snapshot.',
      'Authors@R: person("Sean", "Thimons", role = c("aut", "cre"), email = "sxthi@outlook.com")',
      'License: MIT + file LICENSE',
      'Encoding: UTF-8',
      'Imports: httr2, jsonlite'
    ),
    file.path(stage, 'DESCRIPTION')
  )
  writeLines(c('YEAR: 2026', 'COPYRIGHT HOLDER: Sean Thimons'), file.path(stage, 'LICENSE'))
  writeLines(paste0('export(', names(result$operations), ')'), file.path(stage, 'NAMESPACE'))
  writeLines('^(client[.]R|manifest[.]json)$', file.path(stage, '.Rbuildignore'))
  result$manifest$base_url <- base_url
  result$manifest$package <- package_name
  result$manifest$inputs <- as.list(result$manifest$inputs)
  result$manifest$supported <- names(result$operations)
  result$manifest$diagnostics <- result$diagnostics
  jsonlite::write_json(
    result$manifest,
    file.path(stage, 'manifest.json'),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = 'null'
  )
  dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
  stopifnot(all(file.copy(
    list.files(stage, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    output_root,
    recursive = TRUE
  )))
  cat(sprintf(
    'Generated %d operation(s); %d unsupported operation(s). See manifest.json.\n',
    length(result$operations),
    length(result$diagnostics)
  ))
  invisible(result)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 6L) {
    stop(
      'Usage: Rscript dev/generate_local_client.R <repository_root> <input_root> <schema_file> <output_root> <base_url> <package_name>'
    )
  }
  do.call(generate_local_client, as.list(args))
}
