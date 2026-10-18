# Run from the package root. Generates only held candidate files, never package wrappers.
source('dev/install_specmill.R')
do.call(verify_specmill, getOption('chet.candidate.toolkit', list()))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill-rebuild/chet-search-candidate/callbacks.R', callbacks)
work <- tempfile('chet-generation-'); dir.create(work)
file.copy('R', work, recursive = TRUE)
file.copy(c('DESCRIPTION', 'NAMESPACE'), work)
dir.create(file.path(work, 'schema'))
file.copy('schema/chemi-chet-prod.json', file.path(work, 'schema'))
directory <- 'dev/specmill-rebuild/chet-search-candidate'
dir.create(file.path(work, directory), recursive = TRUE)
file.copy(file.path(directory, c('service.yml', 'specmill.yml')), file.path(work, directory))
mapping_file <- getOption('chet.candidate.mapping', 'service.yml')
file.copy(file.path(directory, mapping_file), file.path(work, directory, 'service.yml'), overwrite = TRUE)
mapping <- yaml::read_yaml(file.path(directory, mapping_file))
outputs <- vapply(mapping$operations, `[[`, '', 'file')
unlink(file.path(work, outputs))
args <- list(root = work, config = 'dev/specmill-rebuild/chet-search-candidate/specmill.yml',
  callbacks = callbacks, artifacts = 'wrappers', mode = 'plan')
plan <- do.call(specmill::generate_client, args)
print(plan)
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$drift))
args$mode <- 'apply'
do.call(specmill::generate_client, args)

files <- file.path(work, outputs)
stopifnot(length(files) == 2L, all(file.copy(files, directory, overwrite = TRUE)))
unlink(work, recursive = TRUE)
