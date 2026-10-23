loadNamespace('specmill',lib.loc='/home/sxthi/.cache/comptoxr-specmill-finish/release51-verification/library')
duplicate_response_overrides_acceptance <- function() {
  root <- path.expand('~/.cache/comptoxr-specmill-finish/release51-verification/portability/original')
  dir.create(root)
  # Preserve isolated repro artifacts.
  fixture <- system.file('catalogue', package = 'specmill', mustWork = TRUE)
  stopifnot(all(file.copy(
    list.files(fixture, full.names = TRUE),
    root,
    recursive = TRUE
  )))
  document <- function(media, parameter = 'id') {
    list(
      openapi = '3.0.3',
      info = list(title = 'Render', version = '1'),
      servers = list(list(url = 'https://render.invalid')),
      paths = list(
        '/render' = list(
          get = list(
            operationId = 'render',
            parameters = list(list(
              name = parameter,
              `in` = 'query',
              schema = list(type = 'string')
            )),
            responses = list(
              '200' = list(
                description = 'OK',
                content = stats::setNames(
                  list(
                    if (media == '*/*') {
                      list(schema = list(type = 'string'))
                    } else {
                      list(schema = list(type = 'string', format = 'binary'))
                    }
                  ),
                  media
                )
              )
            )
          )
        )
      )
    )
  }
  write_schema <- function(media, file, parameter = 'id') {
    jsonlite::write_json(
      document(media, parameter),
      file.path(root, file),
      auto_unbox = TRUE
    )
  }
  dir.create(file.path(root, 'schema/nested'), recursive = TRUE)
  write_schema('image/png', 'schema/nested/alerts.json')
  write_schema('*/*', 'schema/nested/safety.json')
  files <- file.path(root, c('schema/nested/safety.json', 'schema/nested/alerts.json'))
  policy <- list(service = 'render', include = 'GET /render')
  fails <- function(expr, text) {
    error <- tryCatch(force(expr), error = identity)
    stopifnot(
      inherits(error, 'error'),
      grepl(text, conditionMessage(error), fixed = TRUE)
    )
  }
  fails(
    specmill::read_operations(files, policy),
    'Conflicting duplicate operation'
  )
  reviewed <- list(
    source = 'alerts.json',
    reason = 'Reviewed binary response declaration for the same request'
  )
  policy$duplicate_response_overrides <- list('GET /render' = reviewed)
  parsed <- specmill::read_operations(files, policy)
  selected <- parsed$operations[[1L]]
  stopifnot(
    length(parsed$operations) == 1L,
    selected$content_type == 'image/png',
    selected$response_schema_type == 'binary',
    basename(selected$source) == 'alerts.json',
    length(selected$response_sources$sources) == 2L,
    all(vapply(
      parsed$inventory,
      function(x) identical(x$response_sources, selected$response_sources),
      logical(1)
    ))
  )
  reverse <- specmill::read_operations(rev(files), policy)
  stopifnot(identical(reverse$operations[[1L]]$response, selected$response))
  policy$duplicate_response_overrides[['GET /render']]$source <- 'missing.json'
  fails(specmill::read_operations(files, policy), 'one loaded duplicate')
  policy$duplicate_response_overrides[['GET /render']] <- reviewed
  fails(
    specmill::read_operations(files[1L], policy),
    'requires a loaded duplicate'
  )
  policy$duplicate_response_overrides[['GET /render']]$reason <- ''
  fails(specmill::read_operations(files, policy), 'duplicate_response.reason')
  policy$duplicate_response_overrides[['GET /render']] <- reviewed
  write_schema('*/*', 'schema/nested/safety.json', 'other')
  fails(
    specmill::read_operations(files, policy),
    'Conflicting duplicate operation'
  )
  write_schema('*/*', 'schema/nested/safety.json')
  writeLines(
    'api_request <- function(method, path, ...) list(method = method, path = path)',
    file.path(root, 'R/request.R')
  )
  writeLines(
    c('config_version: 1', 'services: [service.yml]'),
    file.path(root, 'specmill.yml')
  )
  writeLines(
    c(
      'id: render',
      'schemas: {files: [schema/nested/safety.json, schema/nested/alerts.json]}',
      'helper: api_request',
      'selection: {include: [GET /render]}',
      'operations:',
      '  GET /render:',
      '    duplicate_response:',
      '      source: alerts.json',
      '      reason: Reviewed binary response declaration for the same request'
    ),
    file.path(root, 'service.yml')
  )
  specmill::generate_client(
    validation = TRUE,
    root,
    config = 'specmill.yml',
    mode = 'apply'
  )
  manifest <- jsonlite::read_json(file.path(root, '.specmill/manifest.json'))
  proof <- manifest$files[['R/render.R']]$response_sources[[
    'render GET /render'
  ]]
  stopifnot(
    identical(proof$selected, 'schema/nested/alerts.json'),
    setequal(vapply(proof$sources, `[[`, '', 'source'), c('schema/nested/safety.json', 'schema/nested/alerts.json')),
    length(proof$sources) == 2L,
    identical(proof$reason, reviewed$reason)
  )
  specmill::generate_client(
    validation = TRUE,
    root,
    config = 'specmill.yml',
    mode = 'check'
  )
  moved <- path.expand('~/.cache/comptoxr-specmill-finish/release51-verification/portability/relocated')
  dir.create(moved)
  stopifnot(all(file.copy(list.files(root, all.files = TRUE, no.. = TRUE, full.names = TRUE), moved, recursive = TRUE)))
  relocated <- specmill::generate_client(validation = TRUE, moved, config = 'specmill.yml', mode = 'check')
  saveRDS(relocated, file.path(dirname(root), 'relocated-check.rds'))
  before_manifest <- jsonlite::read_json(file.path(moved, '.specmill/manifest.json'))
  relocated_apply <- specmill::generate_client(validation = TRUE, moved, config = 'specmill.yml', mode = 'apply')
  after_manifest <- jsonlite::read_json(file.path(moved, '.specmill/manifest.json'))
  changes <- Filter(function(file) file$action != 'unchanged', relocated$files)
  jsonlite::write_json(list(before_root = root, after_root = moved, actions = changes, before = before_manifest$files[['R/render.R']]$response_sources, after = after_manifest$files[['R/render.R']]$response_sources, manifest_equal = identical(before_manifest, after_manifest)), file.path(dirname(root), 'results.json'), pretty = TRUE, auto_unbox = TRUE)
  stopifnot(!length(relocated$diagnostics), !length(relocated$mapping_diagnostics), !length(relocated$drift), !length(relocated$retained_diagnostics), !length(changes), identical(before_manifest, after_manifest), identical(readBin(file.path(root,'.specmill/manifest.json'),'raw',n=1e7),readBin(file.path(moved,'.specmill/manifest.json'),'raw',n=1e7)))
  saveRDS(list(relocated_check=relocated,relocated_apply=relocated_apply),file.path(dirname(root),'generation.rds'))
  jsonlite::write_json(list(version=as.character(utils::packageVersion('specmill')),validation_TRUE=TRUE,selected=proof$selected,sources=vapply(proof$sources,`[[`,'','source'),copied_checkout_fresh=TRUE,all_files_unchanged=TRUE,manifest_raw_bytes_unchanged=TRUE),file.path(dirname(root),'proof.json'),auto_unbox=TRUE,pretty=TRUE)
  print(changes)
  cat('RELOCATION_MANIFEST_EQUAL:', identical(before_manifest, after_manifest), '\n')
  cat(
    'Duplicate responses: explicit reviewed source, both source contracts/provenance, stable selection, request conflicts, missing source and validated freshness passed.\n'
  )
}
if (sys.nframe() == 0L) {
  duplicate_response_overrides_acceptance()
}
