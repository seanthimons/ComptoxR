# Expected requests derive only from canonical operation records.
rows <- jsonlite::read_json('dev/chet-admin-auth/cases.json')
canonical <- jsonlite::read_json('schema/chemi-chet-prod.json')
cases <- list()
for (row in rows) {
  method <- tolower(sub(' .*', '', row$key))
  path <- sub('^[^ ]+ ', '', row$key)
  operation <- canonical$paths[[path]][[method]]
  stopifnot(identical(row$parameters, as.list(c(canonical$paths[[path]]$parameters, operation$parameters))),
    identical(row$requestBody, operation$requestBody))
  args <- query <- list()
  for (p in row$parameters) {
    stopifnot(p[['in']] == 'path', p$schema$type == 'string', isTRUE(p$required))
    value <- 'localhost space & + ? # % slash/'
    args[[p$name]] <- value
    path <- gsub(paste0('{', p$name, '}'), utils::URLencode(value, reserved = TRUE), path, fixed = TRUE)
  }
  media <- NULL
  if (!is.null(row$requestBody)) {
    stopifnot(isTRUE(row$requestBody$required))
    media <- names(row$requestBody$content)[[1L]]
    schema <- row$requestBody$content[[media]]$schema
    stopifnot(schema$type == 'object', isTRUE(schema$additionalProperties), is.null(schema$required))
    args$body <- list(username = 'invented localhost & + user', password = 'invented localhost = ? password')
    if (media == 'application/json') args$body$nested <- list(values = list(1L, TRUE, 'quote " and newline\n'))
  }
  cases[[row$name]] <- list(method = toupper(method), path = paste0(canonical$servers[[1L]]$url, path),
    args = args, query = query, body_media = media, source = row$schema,
    source_sha256 = digest::digest(file = row$schema, algo = 'sha256'))
}
stopifnot(length(cases) == 14L)
saveRDS(cases, 'tests/testthat/fixtures/native-chet-admin-auth.rds')
