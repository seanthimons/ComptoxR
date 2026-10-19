out <- 'dev/specmill-rebuild/released-facades-v47'
source('dev/install_specmill.R'); verify_specmill()
source('dev/specmill-342/emit.R'); emit_issue342(mode = 'check')
previous <- system2('git', c('show', '354401ce:.specmill/manifest.json'), stdout = TRUE)
before <- jsonlite::fromJSON(paste(previous, collapse = '\n'), simplifyVector = FALSE)$files
before[['tests/testthat/test-contract-chemi_search.R']] <- NULL
after <- jsonlite::read_json('.specmill/manifest.json')$files
changed <- names(before)[!vapply(names(before), function(path) identical(before[[path]], after[[path]]), FALSE)]
added <- setdiff(names(after), names(before))
stopifnot(length(before) == 707L, length(after) == 711L, identical(changed, 'R/api_validation.R'),
  setequal(added, c('R/chemi_search.R', paste0('R/chemi_chet_auth_', c('login', 'register', 'report'), '_post.R'))))
source('dev/generate_specmill.R')
fresh <- generate_specmill('check')
saveRDS(fresh, file.path(out, 'fresh.rds'))
stopifnot(all(vapply(names(after), function(path) identical(specmill:::output_hash(path), after[[path]]$hash), FALSE)))
jsonlite::write_json(list(pin = jsonlite::read_json('dev/specmill-lock.json'),
  preceding_owners_after_test_retirement = length(before), owners = length(after),
  changed_preceding_records = changed, new_owners = added,
  sources = length(fresh$validation), freshness = TRUE,
  helper_sha256 = digest::digest(file = 'R/z_specmill_request.R', algo = 'sha256')),
  file.path(out, 'generation.json'), auto_unbox = TRUE, pretty = TRUE)
cat('PASS: official47 helper/validator,33 sources,711 owner hashes and public freshness.\n')
