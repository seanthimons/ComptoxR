# Samples use the canonical schema, never generated formals or request code.
rows <- jsonlite::read_json('dev/chet-extra/cases.json')
canonical <- jsonlite::read_json('schema/chemi-chet-prod.json')
cases <- list()
for (row in rows) {
  method <- tolower(sub(' .*', '', row$key))
  route <- sub('^[^ ]+ ', '', row$key)
  operation <- canonical$paths[[route]][[method]]
  stopifnot(identical(row$parameters, as.list(c(canonical$paths[[route]]$parameters, operation$parameters))),
    identical(row$requestBody, operation$requestBody))
  args <- query <- list()
  path <- sub('^[^ ]+ ', '', row$key)
  for (p in row$parameters) {
    value <- switch(p$name, lib_id = 'library space', reaction_id = 'reaction space',
      map_id = 'map space', stop(p$name))
    args[[p$name]] <- value
    if (p[['in']] == 'query') query[[p$name]] <- value else {
      path <- gsub(paste0('{', p$name, '}'), utils::URLencode(value, reserved = TRUE), path, fixed = TRUE)
    }
  }
  media <- field <- NULL
  if (!is.null(row$requestBody)) {
    media <- names(row$requestBody$content)[[1L]]
    schema <- row$requestBody$content[[media]]$schema
    if (media == 'multipart/form-data') {
      field <- names(schema$properties)[[1L]]
      args$body <- stats::setNames(list(as.raw(c(65, 0, 255, 10, 34, 66))), field)
    } else if (grepl('change-password$', path)) {
      args$body <- list(current_password = 'localhost-old', new_password = 'localhost-new')
    } else if (grepl('/login$', path)) {
      args$body <- list(username = 'localhost-user', password = 'localhost-password')
    } else if (grepl('/visibility$', path)) {
      args$body <- list(reaction_id = 7L, internal_only = FALSE)
    } else {
      stopifnot(isTRUE(schema$additionalProperties))
      args$body <- list(name = 'localhost sample', nested = list(values = list(1L, TRUE, 'quote " and newline\n')))
    }
  }
  cases[[row$name]] <- list(method = sub(' .*', '', row$key),
    path = paste0(canonical$servers[[1L]]$url, path),
    args = args, query = query, body_media = media, upload_field = field,
    source = row$schema, source_sha256 = digest::digest(file = row$schema, algo = 'sha256'))
}
stopifnot(length(cases) == 35L)
saveRDS(cases, 'tests/testthat/fixtures/native-chet-extra.rds')
