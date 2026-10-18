# Run in a clean R process using the pinned toolkit library.
source('dev/install_specmill.R'); verify_specmill()
source('dev/check_hook_config.R')
root <- tempfile('hook-discovery-')
dir.create(file.path(root, 'R'), recursive = TRUE)
dir.create(file.path(root, 'inst'))
stopifnot(file.copy('R/hook_registry.R', file.path(root, 'R/hook_registry.R')))
writeLines(c("alpha <- function(query = NULL) run_hook('alpha', 'post_response', list(result = query))",
  'transform_alpha <- function(data) data'), file.path(root, 'R/policy.R'))
writeLines('[]', file.path(root, 'inst/hook_config_generated.yml'))
write_config <- function(wrapper = 'alpha', hook = 'transform_alpha') {
  yaml::write_yaml(stats::setNames(list(list(post_response = list(hook))), wrapper),
    file.path(root, 'inst/hook_config.yml'))
}
write_config()
stopifnot(isTRUE(check_hook_config(root)$valid))
write_config(hook = 'missing_transform')
error <- tryCatch(check_hook_config(root), error = identity)
stopifnot(inherits(error, 'error'), grepl('references missing hook: missing_transform', conditionMessage(error), fixed = TRUE))
write_config(wrapper = 'missing_wrapper')
error <- tryCatch(check_hook_config(root), error = identity)
stopifnot(inherits(error, 'error'), grepl('Missing selected wrapper: missing_wrapper', conditionMessage(error), fixed = TRUE))
unlink(root, recursive = TRUE)
cat('External hook file discovery and strict missing-hook/wrapper rejection PASS\n')
