.libPaths(c(normalizePath('.migration-evidence/comptoxr-library', winslash = '/'), .libPaths()))
loadNamespace('ComptoxR')
source('dev/build_migration_database.R')
build_migration_database(system.file('ecotox', 'ecotox_build.R', package = 'ComptoxR'), 'source-only-installed')
