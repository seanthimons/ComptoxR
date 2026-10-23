# Independent samples checked against the unchanged canonical declarations.
rows <- jsonlite::read_json('dev/resolver-extra/cases.json')
canonical <- jsonlite::read_json('schema/chemi-resolver-prod.json')
chemical <- list(sid = 'localhost-id', smiles = 'C', name = 'localhost sample')
chemical_list <- list(chemical)
cases <- list()
for (row in rows) {
  method <- tolower(sub(' .*', '', row$key))
  path <- sub('^[^ ]+ ', '', row$key)
  operation <- canonical$paths[[path]][[method]]
  stopifnot(identical(row$parameters, as.list(c(canonical$paths[[path]]$parameters, operation$parameters))),
    identical(row$requestBody, operation$requestBody))
  args <- query <- list()
  for (p in row$parameters) {
    value <- switch(p$name, query = 'localhost sample & quote "', idType = 'Name',
      outputFormat = 'JSON', sid = 'localhost-id', section = 'localhost section',
      search = 'localhost search', linkBy = 'localhost link', report = 'localhost report',
      smiles = 'C', smirks = '[C:1]>>[C:1]', format = 'SVG', width = 120L, height = 80L,
      stop(p$name))
    args[[p$name]] <- query[[p$name]] <- value
  }
  media <- field <- NULL
  if (!is.null(row$requestBody)) {
    media <- names(row$requestBody$content)[[1L]]
    schema <- row$requestBody$content[[media]]$schema
    if (media == 'multipart/form-data') {
      stopifnot(identical(names(schema$properties), c('chemicals', 'file')),
        identical(schema$properties$file$format, 'binary'),
        identical(schema$properties$chemicals$items[['$ref']], '#/components/schemas/Chemical'))
      field <- 'file'
      args$body <- list(chemicals = chemical_list, file = as.raw(c(65, 0, 255, 10, 34, 66)))
    } else {
      ref <- schema[['$ref']]
      args$body <- switch(sub('^#/components/schemas/', '', if (is.null(ref)) '' else ref),
        SafetyExportRequest = list(flags = list(list(chemical = chemical, exp = FALSE, sah = TRUE)),
          outputFormat = 'JSON', showImages = FALSE),
        ExportRequest = list(chemicals = chemical_list, format = 'JSON',
          records = list(list(chemical = chemical, query = 'localhost sample', result = 'FOUND')),
          selectedForSimilarity = chemical, showImages = FALSE),
        ExportSectionRequest = list(chemicals = chemical_list, outputFormat = 'JSON', sections = list('localhost section')),
        PubchemRequest = list(chemicals = chemical_list, section = 'localhost section'),
        UniversalHarvestRequest = list(chemicals = chemical_list,
          info = list(deepSearch = FALSE, keyChemIdType = 'Name', useResolver = TRUE)),
        {
          stopifnot(identical(path, '/api/resolver/ghs-list-count'),
            identical(schema$additionalProperties$items$items$type, 'string'))
          list(localhost = list(list('H000', 'localhost sample')))
        })
    }
  }
  cases[[row$name]] <- list(method = toupper(method), path = path, args = args,
    query = query, body_media = media, upload_field = field,
    body_required = isTRUE(row$requestBody$required),
    source = row$schema, source_sha256 = digest::digest(file = row$schema, algo = 'sha256'))
}
stopifnot(length(cases) == 12L)
saveRDS(cases, 'tests/testthat/fixtures/native-resolver-extra.rds')
