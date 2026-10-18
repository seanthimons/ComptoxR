# Run from the package root. Generates only held candidate files, never package wrappers.
directory <- 'dev/specmill-rebuild/rootheldrelease'
source('dev/install_specmill.R')
verify_specmill(lib = file.path(directory, '.toolkit-library'), lock = file.path(directory, 'toolkit-lock.json'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill-rebuild/rootheldrelease/callbacks.R', callbacks)
work <- tempfile('chet-generation-'); dir.create(work)
file.copy('R', work, recursive = TRUE)
file.copy(file.path(directory, 'input-policy.R'), file.path(work, 'R'))
file.copy(c('DESCRIPTION', 'NAMESPACE'), work)
dir.create(file.path(work, 'schema'))
file.copy('schema/chemi-chet-prod.json', file.path(work, 'schema'))
dir.create(file.path(work, directory), recursive = TRUE)
file.copy(file.path(directory, c('service.yml', 'specmill.yml')), file.path(work, directory))
mapping <- yaml::read_yaml(file.path(directory, 'service.yml'))
outputs <- vapply(mapping$operations, `[[`, '', 'file')
unlink(file.path(work, outputs))
args <- list(root = work, config = 'dev/specmill-rebuild/rootheldrelease/specmill.yml',
  callbacks = callbacks, artifacts = 'wrappers', mode = 'plan')
plan <- do.call(specmill::generate_client, args)
print(plan)
stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$drift))
args$mode <- 'apply'
do.call(specmill::generate_client, args)

files <- file.path(work, outputs)
stopifnot(length(files) == 2L)
if (isTRUE(getOption('chet.candidate.check'))) {
  stopifnot(all(vapply(files, function(file) identical(readBin(file, 'raw', file.info(file)$size),
    readBin(file.path(directory, basename(file)), 'raw', file.info(file)$size)), FALSE)))
  cat('PASS: official generated wrappers reproduce byte for byte.\n')
} else {
  stopifnot(all(file.copy(files, directory, overwrite = TRUE)))
}
unlink(work, recursive = TRUE)
