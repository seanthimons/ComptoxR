# Reproduce the upstream parallel/custom-request limitation without editing the package.
# Run from the package root: Rscript dev/parallel-exploration/reproduce-mapped-batch.R
source("dev/install_specmill.R")
verify_specmill()
root <- tempfile("mapped-parallel-")
dir.create(root)
paths <- system2("git", "ls-files", stdout = TRUE)
paths <- paths[grepl("^(R/|apis/|schema/|inst/|tests/testthat/fixtures/|[.]specmill/|DESCRIPTION$|NAMESPACE$|air.toml$)", paths)]
for (path in paths) {
  dir.create(dirname(file.path(root, path)), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(path, file.path(root, path)))
}
config <- yaml::read_yaml("specmill.yml", handlers = list(seq = function(x) x))
config$services <- list("apis/ctx_chemical.yml")
config$callback_files <- NULL
yaml::write_yaml(config, file.path(root, "specmill.yml"))
service <- yaml::read_yaml("apis/ctx_chemical.yml", handlers = list(seq = function(x) x))
key <- "POST /chemical/search/equal/"
group <- service$groups$ctx_chemical
group$operations <- group$operations[key]
group$names <- group$names[key]
group$selection <- list(include = list(key))
group$operations[[key]]$batch$concurrency <- 2L
group$operations[[key]]$request_controls <- list(max_retries = 0L,
  throttle = list(capacity = 2L, fill_time_s = 1))
service$groups$ctx_chemical <- group
yaml::write_yaml(service, file.path(root, "apis/ctx_chemical.yml"))
callbacks <- new.env(parent = baseenv())
for (file in yaml::read_yaml("specmill.yml")$callback_files) sys.source(file, callbacks)
error <- tryCatch({
  specmill::generate_client(root, config = "specmill.yml", callbacks = callbacks,
    mode = "plan", artifacts = "wrappers", validation = FALSE)
  NULL
}, error = identity)
unlink(root, recursive = TRUE)
stopifnot(inherits(error, "error"), grepl("batch.concurrency requires native unpaged requests", conditionMessage(error), fixed = TRUE))
cat(conditionMessage(error), "\n")
