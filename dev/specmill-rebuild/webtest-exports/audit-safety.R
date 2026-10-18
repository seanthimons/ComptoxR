source('dev/install_specmill.R')
verify_specmill('/home/sxthi/Documents/Projects/ComptoxR/dev/specmill-pilot/artifacts/toolkit-library/0.1.42')
root <- path.expand('~/.cache/comptoxr-specmill-finish/proof')
service <- yaml::read_yaml('apis/chemi-management.yml')
service$schemas$files <- c(service$schemas$files, 'schema/chemi-safety-prod.json')
yaml::write_yaml(service, file.path(root, 'apis/safety-ownership-repro.yml'))
yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR',
  services = list('apis/safety-ownership-repro.yml')),
  file.path(root, 'safety-ownership-repro.yml'))
error <- tryCatch(specmill::generate_client(root = root,
  config = 'safety-ownership-repro.yml', mode = 'plan', artifacts = 'wrappers',
  validation = TRUE), error = conditionMessage)
stopifnot(is.character(error), grepl('Conflicting duplicate operation chemi-management GET /api/alerts/render', error, fixed = TRUE))
alerts <- jsonlite::read_json('schema/chemi-alerts-prod.json')
safety <- jsonlite::read_json('schema/chemi-safety-prod.json')
a <- alerts$paths[['/api/alerts/render']]$get
s <- safety$paths[['/api/alerts/render']]$get
stopifnot(identical(alerts$servers, safety$servers), identical(a$parameters, s$parameters))
jsonlite::write_json(list(
  error = error, same_server = TRUE, same_parameters = TRUE,
  alerts_media = names(a$responses[['200']]$content),
  safety_media = names(s$responses[['200']]$content),
  disposition = 'Retain existing chemi_alerts_render; safety source identity held on specmill#61',
  source_commit = 'b17a0856263e0179a164a9673399f221168cda6d'),
  'dev/specmill-rebuild/webtest-exports/safety-ownership.json', pretty = TRUE, auto_unbox = TRUE)
