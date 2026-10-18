source('dev/specmill-rebuild/released-facades-v42/setup.R')
path <- file.path(folder, 'held-config.yml')
result <- tryCatch(specmill::generate_client('.', config = path, callbacks = callbacks,
  mode = 'plan', artifacts = 'wrappers', validation = TRUE), error = identity)
print(result)
stopifnot(inherits(result, 'error'), startsWith(conditionMessage(result),
  'batch.split requires batch.max_items on a top-level array request body'))
saveRDS(result, file.path(folder, 'held-bulk-rejection.rds'))
cat(conditionMessage(result), '\n')
