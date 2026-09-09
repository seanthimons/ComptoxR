#!/usr/bin/env Rscript
# Sourceable command. Generated output needs httr2, but no development toolkit.
generate_local_client <- function(repository_root, input_root, schema, output_root, base_url, package_name, metadata) {
  if (
    length(package_name) != 1L ||
      !grepl('^[A-Za-z][A-Za-z0-9.]*[A-Za-z0-9]$', package_name) ||
      tolower(package_name) %in% c('comptoxr', 'apipak', 'wrapmaint', 'httr2')
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
  apipak::initialize_client(
    output_root,
    schema_path,
    package = package_name,
    title = metadata$title,
    author = metadata$author,
    license = metadata$license,
    base_url = base_url
  )
  apipak::generate_client(output_root, config = 'apipak.yml', mode = 'apply')
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 7L) {
    stop(
      'Usage: Rscript dev/generate_local_client.R <repository_root> <input_root> <schema_file> <output_root> <base_url> <package_name> <metadata.json>'
    )
  }
  do.call(generate_local_client, c(as.list(args[1:6]), list(metadata = jsonlite::read_json(args[[7L]]))))
}
