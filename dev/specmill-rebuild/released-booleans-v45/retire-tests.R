source('dev/install_specmill.R')
verify_specmill()
names4 <- c('chemi_opera', 'chemi_resolver_lookup', 'chemi_toxprints', 'epi_ecosar_surfactant_nonionic')
config <- yaml::read_yaml('inst/hook_config.yml')
stopifnot(all(vapply(config[names4], function(x) identical(x$bespoke_test,
  'tests/testthat/test-native_released_booleans_v45.R'), FALSE)))
frozen <- setNames(lapply(names4, function(name) {
  code <- system2('git', c('show', paste0('HEAD:R/', name, '.R')), stdout = TRUE)
  definitions <- parse(text = code)
  assignment <- Filter(function(x) is.call(x) && identical(x[[1]], as.name('<-')) &&
    identical(x[[2]], as.name(name)), as.list(definitions))
  stopifnot(length(assignment) == 1L)
  formals(eval(assignment[[1]][[3]], baseenv()))
}), names4)
saveRDS(frozen, 'tests/testthat/fixtures/native-boolean-formals-v45.rds', version = 2)
# Remove obsolete generator inputs after archiving the exact fixed contracts.
retired <- list()
for (fixture in c('tests/testthat/fixtures/specmill-rebuild-contracts.rds',
                  'tests/testthat/fixtures/specmill-full-contracts.rds')) {
  contracts <- readRDS(fixture)
  selected <- intersect(names4, names(contracts))
  retired <- c(retired, contracts[selected])
  saveRDS(contracts[setdiff(names(contracts), names4)], fixture, version = 2)
}
stopifnot(setequal(names(retired), names4))
saveRDS(retired, 'dev/specmill-rebuild/released-booleans-v45/retired-fixed-contracts.rds', version = 2)
remove <- paste0('tests/testthat/test-contract-', names4, '.R')
owned <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(all(vapply(remove, function(path) identical(specmill:::output_hash(path), owned[[path]]$hash), FALSE)))
result <- specmill::apply_files('.', list(), remove = remove, mode = 'apply')
saveRDS(result, 'dev/specmill-rebuild/released-booleans-v45/test-retirement.rds')
stopifnot(all(!file.exists(remove)))
cat('Four obsolete helper-call snapshots retired through supported apply_files; frozen public formals retained.\n')
