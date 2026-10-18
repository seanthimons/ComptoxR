# Derive only independently verified production reads from the preserved OAS3 source.
source <- 'dev/specmill-rebuild/sources/amos-staging-2026-10-18.json'
expected <- '627d6cb4ec4aab1448163b578a6b857476c817a93404369cddfe87a4dd54c401'
stopifnot(identical(digest::digest(file = source, algo = 'sha256'), expected))
schema <- jsonlite::read_json(source)
stopifnot(identical(schema$openapi, '3.0.3'))
routes <- paste0('/api/amos/', c('retrieve_fact_sheets/', 'retrieve_product_declarations/',
  'retrieve_safety_data_sheets/', 'substances_for_ids/', 'search_for_document_ids/{record_type}'))
paths <- lapply(schema$paths[routes], function(path) list(post = path$post))
stopifnot(all(vapply(paths, function(path) is.list(path$post), logical(1))))
refs <- function(value) {
  if (!is.list(value)) return(character())
  unique(c(value[['$ref']], unlist(lapply(value, refs), use.names = FALSE)))
}
# References remain local; copy the transitive component closure without rewriting it.
components <- list()
pending <- refs(paths); visited <- character()
while (length(pending)) {
  ref <- pending[[1L]]; pending <- pending[-1L]
  if (ref %in% visited) next
  stopifnot(startsWith(ref, '#/components/'))
  parts <- strsplit(sub('^#/', '', ref), '/', fixed = TRUE)[[1L]]
  stopifnot(length(parts) == 3L)
  value <- schema$components[[parts[[2L]]]][[parts[[3L]]]]
  stopifnot(!is.null(value))
  components[[parts[[2L]]]][parts[[3L]]] <- list(value)
  visited <- c(visited, ref); pending <- unique(c(pending, refs(value)))
}
bundle <- list(openapi = schema$openapi, info = schema$info,
  servers = list(list(url = 'https://hcd.rtpnc.epa.gov')), paths = paths)
if (length(components)) bundle$components <- components
output <- 'schema/chemi-amos-reviewed-reads.json'
jsonlite::write_json(bundle, output, pretty = TRUE, auto_unbox = TRUE, null = 'null')
record <- list(source_url = 'https://cim.sciencedataexperts.com/api/amos/swagger.json',
  retrieved_utc = format(file.info(source)$mtime, tz = 'UTC', usetz = TRUE),
  source_file = source, source_sha256 = expected, output = output,
  output_sha256 = digest::digest(file = output, algo = 'sha256'),
  canonical = 'schema/chemi-amos-prod.json',
  canonical_sha256 = digest::digest(file = 'schema/chemi-amos-prod.json', algo = 'sha256'),
  derivation = list(operations = paste('POST', routes),
    copied = 'openapi/info, selected POST objects, transitive local components',
    changed = 'servers replaced by explicit production origin; unselected paths/components omitted',
    operation_objects_unchanged = all(vapply(routes, function(route)
      identical(bundle$paths[[route]]$post, schema$paths[[route]]$post), logical(1)))),
  diff = list(removed_top_level_fields = setdiff(names(schema), names(bundle)),
    removed_paths = setdiff(names(schema$paths), routes),
    removed_selected_path_fields = lapply(schema$paths[routes], function(path) setdiff(names(path), 'post')),
    removed_component_keys = setdiff(unlist(lapply(names(schema$components), function(kind)
      paste(kind, names(schema$components[[kind]]), sep = '/')), use.names = FALSE),
      sub('^#/components/', '', visited)),
    servers_from = schema$servers, servers_to = bundle$servers),
  production_evidence = c('dev/specmill-rebuild/amos-positive-native-live-review.rds',
    'dev/specmill-rebuild/amos-document-search-live-review.rds'),
  issue = 'https://github.com/seanthimons/specmill/issues/27#issuecomment-6252444438')
stopifnot(record$derivation$operation_objects_unchanged)
jsonlite::write_json(record, 'dev/specmill-rebuild/amos-reviewed-source.json',
  pretty = TRUE, auto_unbox = TRUE)
cat(output, record$output_sha256, '\n')
