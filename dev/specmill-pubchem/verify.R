# Usage: Rscript dev/specmill-pubchem/verify.R /path/to/official-v41-library
args <- commandArgs(TRUE)
stopifnot(length(args) %in% 1:2)
source_only <- length(args) == 2L && identical(args[[2L]], '--source-only')
stopifnot(length(args) == 1L || source_only)
library(specmill, lib.loc = args[[1L]])
metadata <- utils::packageDescription('specmill')
stopifnot(metadata$Version == '0.1.41',
  metadata[['Config/specmill/source-commit']] == '05862bee1804806cea157ff1962300d741516301',
  metadata[['Config/specmill/source-archive-sha256']] == '70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc')
source_dir <- 'dev/specmill-pubchem'
ledger <- jsonlite::read_json(file.path(source_dir, 'source-ledger.json'))
stopifnot(identical(digest::digest(file = file.path(source_dir, 'pug-rest-original.md'), algo = 'sha256'), ledger$source_sha256),
  identical(digest::digest(file = file.path(source_dir, 'pubchem-reviewed.json'), algo = 'sha256'), ledger$output_sha256))
validation <- validate_schema(file.path(source_dir, 'pubchem-reviewed.json'))
stopifnot(validation$status == 'passed', length(validation$operations) == 6L)
cache_error <- tryCatch(specmill:::validate_settings(list(cache = list(enabled = 'cache')), 'PubChem'), error = conditionMessage)
stopifnot(identical(cache_error, 'PubChem: unknown field cache'))
# Public generator contract probe, isolated from production config and ownership.
stage <- tempfile('pubchem-source-probe-')
dir.create(stage)
file.copy('DESCRIPTION', stage)
dir.create(file.path(stage, 'R'))
scaffold <- specmill:::request_helper_scaffold('.ct_request', 'https://example.invalid', NULL,
  'COMPTOXR_NATIVE_DRY_RUN', companions = c('batching', 'pagination'))
writeLines(scaffold$code, file.path(stage, 'R/native.R'))
dir.create(file.path(stage, 'schema'))
file.copy(file.path(source_dir, 'pubchem-reviewed.json'), file.path(stage, 'schema/pubchem.json'))
operations <- lapply(validation$operations, function(op) list(name = sub('^pubchem_', 'probe_',
  jsonlite::read_json(file.path(source_dir, 'pubchem-reviewed.json'))$paths[[op$path]][[tolower(op$method)]]$operationId),
  helper = '.ct_request', implementation = 'generated'))
names(operations) <- vapply(validation$operations, `[[`, '', 'key')
yaml::write_yaml(list(id = 'pubchem-contract-probe', schemas = list(files = list('schema/pubchem.json')),
  helper = '.ct_request', documentation = FALSE, operations = operations), file.path(stage, 'pubchem.yml'))
yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR', services = list('pubchem.yml')),
  file.path(stage, 'specmill.yml'))
probe <- generate_client(root = stage, config = 'specmill.yml', mode = 'plan', artifacts = 'wrappers', validation = TRUE)
stopifnot(!length(probe$diagnostics), !length(probe$mapping_diagnostics), !length(probe$drift))
if (source_only) {
  applied <- generate_client(root = stage, config = 'specmill.yml', mode = 'apply',
    artifacts = 'wrappers', validation = TRUE)
  fresh <- generate_client(root = stage, config = 'specmill.yml', mode = 'check',
    artifacts = 'wrappers', validation = TRUE)
  stopifnot(!length(fresh$diagnostics), !length(fresh$mapping_diagnostics), !length(fresh$drift),
    all(vapply(fresh$files, function(file) file$action == 'unchanged', logical(1))))
  saveRDS(list(validation = validation, applied = applied, fresh = fresh),
    file.path(source_dir, 'source-freshness.rds'), version = 3)
  unlink(stage, recursive = TRUE)
  message('Six-route isolated public generation/apply/fresh check passed; no facade adoption.')
  quit(status = 0L)
}
# Original full root source/config, read-only: no pin, helper or ownership adoption.
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
full <- generate_client(root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'plan', artifacts = c('wrappers', 'tests'), validation = TRUE)
stopifnot(!length(full$diagnostics), !length(full$mapping_diagnostics), !length(full$drift),
  !length(full$retained_diagnostics))
changes <- Filter(function(file) file$action != 'unchanged', full$files)
result <- list(toolkit = list(version = metadata$Version,
  commit = metadata[['Config/specmill/source-commit']], archive_sha256 = metadata[['Config/specmill/source-archive-sha256']]),
  source_validation = validation, cache_error = cache_error,
  source_probe = list(diagnostics = probe$diagnostics, mapping_diagnostics = probe$mapping_diagnostics,
    drift = probe$drift, files = probe$files),
  full_generation = list(validation = full$validation, diagnostics = full$diagnostics,
    mapping_diagnostics = full$mapping_diagnostics, drift = full$drift,
    retained_diagnostics = full$retained_diagnostics, changes = changes),
  adopted_operations = 0L)
saveRDS(result, file.path(source_dir, 'verification.rds'), version = 3)
print(result[c('cache_error', 'adopted_operations')])
print(changes)
unlink(stage, recursive = TRUE)
