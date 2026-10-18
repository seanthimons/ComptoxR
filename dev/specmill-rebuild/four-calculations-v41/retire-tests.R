# Retire only fixed helper contracts replaced by the registered native suite.
.libPaths(c('/tmp/chet-specmill41-library', .libPaths()))
names4 <- c('chemi_mordred','chemi_mordred_bulk','chemi_webtest_predict','chemi_webtest_predict_bulk')
config <- yaml::read_yaml('inst/hook_config.yml')
stopifnot(all(vapply(config[names4], function(x) identical(x$bespoke_test,
  'tests/testthat/test-native_four_calculations.R'), FALSE)))
path <- 'tests/testthat/fixtures/specmill-rebuild-contracts.rds'
fixtures <- readRDS(path)
if (all(names4 %in% names(fixtures))) {
  saveRDS(fixtures[names4], 'dev/specmill-rebuild/four-calculations-v41/retired-fixed-contracts.rds', version=2)
} else stopifnot(!any(names4 %in% names(fixtures)))
remaining <- fixtures[setdiff(names(fixtures),names4)]
stopifnot(identical(remaining,fixtures[!names(fixtures) %in% names4]))
saveRDS(remaining,path,version=2)
remove <- paste0('tests/testthat/test-contract-',names4,'.R')
owned <- jsonlite::read_json('.specmill/manifest.json')$files
stopifnot(all(vapply(remove, function(p) identical(digest::digest(paste(readLines(p,warn=FALSE),collapse='\n'),algo='sha256',serialize=FALSE),owned[[p]]$hash), FALSE)))
result <- specmill::apply_files('.',list(),remove=remove,mode='apply')
saveRDS(result,'dev/specmill-rebuild/four-calculations-v41/test-retirement.rds',version=2)
