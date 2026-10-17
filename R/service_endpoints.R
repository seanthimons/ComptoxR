# Effective service settings are resolved when used, without changing the session.
.endpoint_default <- function(key) {
  switch(
    key,
    ctx_burl = 'https://comptox.epa.gov/ctx-api/',
    chemi_burl = 'https://hcd.rtpnc.epa.gov/api',
    epi_burl = 'https://episuite.dev/api',
    eco_burl = eco_path(),
    toxval_burl = toxval_path(),
    np_burl = 'https://api.naturalproducts.net/latest/',
    pubchem_burl = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug/',
    NULL
  )
}

.endpoint_string <- function(value, key) {
  if (!is.character(value) || length(value) != 1L || is.na(value) || !nzchar(trimws(value))) {
    cli::cli_abort('Configure {.code ComptoxR.{key}} or {.code {key}} with one non-empty string.')
  }
  value
}

.endpoint_url <- function(server) {
  server <- .endpoint_string(server, 'server')
  value <- if (grepl('^https?://', server, ignore.case = TRUE)) server else .endpoint_target(server)
  parsed <- tryCatch(httr2::url_parse(value), error = function(e) NULL)
  if (
    is.null(parsed) ||
      !tolower(parsed$scheme) %in% c('http', 'https') ||
      is.null(parsed$hostname) ||
      !nzchar(parsed$hostname) ||
      grepl('[[:space:]]', value)
  ) {
    cli::cli_abort(
      'The configured endpoint must be one valid HTTP(S) URL. Use a ComptoxR service option or environment variable.'
    )
  }
  value
}

.endpoint_target <- function(key) {
  value <- getOption(paste0('ComptoxR.', key))
  if (is.null(value)) {
    value <- Sys.getenv(key, unset = '')
    if (!nzchar(value)) value <- .endpoint_default(key)
  }
  value <- .endpoint_string(value, key)
  if (!key %in% c('eco_burl', 'toxval_burl') || grepl('^[[:alpha:]][[:alnum:]+.-]*://', value)) {
    # Pass the literal value to avoid resolving the same key again.
    if (!grepl('^https?://', value, ignore.case = TRUE)) {
      cli::cli_abort('Configure {.code ComptoxR.{key}} or {.code {key}} with an HTTP(S) URL.')
    }
    .endpoint_url(value)
  }
  value
}

.set_endpoint <- function(key, server, url_only, choices) {
  if (!rlang::is_bool(url_only)) {
    cli::cli_abort('{.arg url_only} must be one TRUE or FALSE value.')
  }
  if (is.null(server)) {
    if (!url_only) {
      Sys.unsetenv(key)
    }
    value <- .endpoint_target(key)
  } else {
    if (length(server) != 1L || is.na(server)) {
      cli::cli_abort('{.arg server} must be one nonmissing value.')
    }
    choice <- as.character(server)
    value <- choices[[choice]]
    if (is.null(value)) {
      if (!is.character(server) || grepl('^[0-9]+$', server)) {
        cli::cli_abort(
          'This server mode is not supported. Use {.code ComptoxR.{key}}, {.code {key}}, or an explicit URL.'
        )
      }
      value <- .endpoint_string(server, key)
      if (key %in% c('eco_burl', 'toxval_burl') && !grepl('^https?://', value, ignore.case = TRUE)) {
        if (!file.exists(value)) {
          cli::cli_abort('Database file not found: {.path {value}}')
        }
        value <- normalizePath(value, mustWork = TRUE)
      } else {
        value <- .endpoint_url(value)
      }
    }
    if (!url_only) {
      do.call(Sys.setenv, stats::setNames(list(value), key))
      value <- .endpoint_target(key)
    }
  }
  if (!url_only && key %in% c('eco_burl', 'toxval_burl')) {
    .sync_database_target(key, value)
  }
  value
}

.sync_database_target <- function(key, target = .endpoint_target(key)) {
  field <- if (key == 'eco_burl') 'ecotox_db_path' else 'toxval_db_path'
  effective <- if (grepl('^https?://', target, ignore.case = TRUE)) {
    target
  } else {
    normalizePath(target, winslash = '/', mustWork = FALSE)
  }
  if (!identical(.ComptoxREnv[[field]], effective)) {
    if (key == 'eco_burl') {
      .eco_close_con()
    } else {
      .tox_close_con()
    }
    .ComptoxREnv[[field]] <- effective
  }
  invisible(effective)
}

.diagnostic_endpoint <- function(value) {
  value <- gsub('(https?://)[^/@[:space:]]+@', '\\1<redacted>@', value, ignore.case = TRUE)
  gsub('(https?://[^?#[:space:]]+)[?#][^[:space:]]*', '\\1', value, ignore.case = TRUE)
}

# Specmill server resolver for native wrappers: one ComptoxR service key per API.
# Relative schema servers carry the /api prefix in their paths, so they get the origin only.
.ct_server_url <- function(key, server) {
  url <- .endpoint_url(.endpoint_target(key))
  if (is.null(server$url)) sub('^(https?://[^/]+).*$', '\\1', url) else url
}

# Specmill response policy: the same tibble output as generic_request(tidy = TRUE).
.ct_tidy <- function(response, context, decode) {
  # probe_api_function() reads HTTP statuses through this observer.
  observe_api_responses(list(response))
  body <- unwrap_collection_envelope(decode())
  # The API doesn't echo the input on single-object responses; name it in a query column.
  single <- is.list(body) && !is.null(names(body))
  .ct_request_table(
    .ct_request_records(body, query = if (single && length(context$query) == 1L) context$query),
    build = safe_tidy_bind
  )
}

# Specmill response policy for file endpoints: text (mol) as a string, images as magick objects.
.ct_file <- function(response, context, decode) {
  observe_api_responses(list(response))
  value <- decode()
  if (!startsWith(context$media, 'image/') || context$media == 'image/svg+xml') return(value)
  tryCatch(magick::image_read(value), error = function(e) value)
}

# Specmill response policy for paged CTX endpoints: each page is an envelope around `data`.
.ct_paged <- function(response, context, decode) {
  observe_api_responses(list(response))
  body <- decode()
  table <- .ct_request_table(
    .ct_request_records(body, collection = 'data'),
    build = safe_tidy_bind
  )
  attr(table, 'paging') <- body[c('pageNumber', 'totalPages')]
  table
}

# Specmill pagination stop: the envelope names the last page.
.ct_last_page <- function(response, state) {
  paging <- attr(response, 'paging')
  isTRUE(paging$pageNumber >= paging$totalPages)
}
