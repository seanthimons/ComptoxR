cases <- jsonlite::read_json('dev/specmill-rebuild/stdizer-unbound/cases.json')
for (name in names(cases)) cases[[name]]$source_sha256 <- digest::digest(file = cases[[name]]$source, algo = 'sha256')
saveRDS(cases, 'tests/testthat/fixtures/native-stdizer-unbound.rds', version = 3)
