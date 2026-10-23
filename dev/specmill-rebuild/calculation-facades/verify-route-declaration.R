# Reproduce the remaining #61 / ComptoxR#341 blocker without HTTP or client edits.
source('dev/install_specmill.R')
verify_specmill()
root <- tempfile('calculation-routes-')
dir.create(root); dir.create(file.path(root, 'schema'))
files <- paste0('schema/chemi-', c('descriptors', 'rdkit'), '-prod.json')
stopifnot(all(file.copy(files, file.path(root, files))))
reports <- lapply(files, specmill::validate_schema)
stopifnot(all(vapply(reports, function(x) identical(x$status, 'passed'), FALSE)))
results <- list()
for (method in c('GET', 'POST')) {
  key <- paste(method, '/api/descriptors')
  route <- paste('chemi-rdkit-prod.json', method, '/api/rdkit')
  service <- list(id = 'calculation-route-repro', schemas = list(files = as.list(files)),
    selection = list(include = list(key)), helper = '.ct_request',
    defaults = list(server = list(resolver = '.ct_server_url', key = 'chemi_burl')),
    operations = setNames(list(list(name = if (method == 'GET') 'chemi_descriptors' else 'chemi_descriptors_bulk',
      routes = list(route))), key))
  yaml::write_yaml(service, file.path(root, 'service.yml'))
  yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR', services = list('service.yml')),
    file.path(root, 'specmill.yml'))
  error <- tryCatch(specmill::generate_client(root, config = 'specmill.yml', mode = 'plan', artifacts = 'wrappers'), error = identity)
  expected <- paste0('calculation-route-repro: route ', route, ' disagrees with ', key, ' server')
  stopifnot(inherits(error, 'error'), identical(conditionMessage(error), expected))
  results[[method]] <- list(message = conditionMessage(error), service = service)
}
saveRDS(list(pin = jsonlite::read_json('dev/specmill-lock.json'),
  schemas = lapply(reports, function(x) x[c('source_sha256', 'status', 'reason')]),
  results = results, upstream = 'https://github.com/seanthimons/specmill/issues/61#issuecomment-6252954521'),
  'dev/specmill-rebuild/calculation-facades/route-declaration.rds', version = 2)
unlink(root, recursive = TRUE)
cat('Confirmed GET and POST declared-route server blockers; both sources validate.\n')
