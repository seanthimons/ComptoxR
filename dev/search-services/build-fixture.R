rows <- jsonlite::read_json('dev/search-services/cases.json')
cases <- list()
for (row in rows) {
  schema <- jsonlite::read_json(row$schema)
  method <- tolower(sub(' .*', '', row$key))
  path <- sub('^[^ ]+ ', '', row$key)
  operation <- schema$paths[[path]][[method]]
  stopifnot(identical(row$operation, operation))
  args <- query <- list()
  for (p in operation$parameters) {
    value <- switch(p$name, id = 123L, format = 'MOL', smiles = 'localhost sentinel',
      query = 'localhost query', width = 96L, height = 64L, stop(p$name))
    args[[p$name]] <- query[[p$name]] <- value
  }
  media <- field <- NULL
  if (!is.null(operation$requestBody)) {
    media <- names(operation$requestBody$content)[[1L]]
    if (media == 'multipart/form-data') {
      field <- 'files[]'
      args$body <- stats::setNames(list(list(as.raw(c(65, 0, 255, 10, 34, 66)), as.raw(c(66, 0, 128)))), field)
    } else {
      # Transport sentinels are confined to localhost, never chemical calculation evidence.
      args$body <- if (grepl('/services/', path)) list(format = 'JSON', showImages = FALSE) else
        if (grepl('search-result-as-sdf$', path)) list(inputType = 'SMILES', searchType = 'EXACT', query = 'localhost sentinel', limit = 1L) else
          list(format = 'MOL', ids = list(), query = 'localhost sentinel')
    }
  }
  cases[[row$name]] <- list(method = toupper(method), path = path, args = args, query = query,
    body_media = media, upload_field = field, source = row$schema,
    source_sha256 = digest::digest(file = row$schema, algo = 'sha256'))
}
stopifnot(length(cases) == 11L)
saveRDS(cases, 'tests/testthat/fixtures/native-search-services.rds')
