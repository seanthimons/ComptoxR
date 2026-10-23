# Replay the pinned-renderer incompatibility probes for the retained #337 transformation wave.
# Run from the package root; writes only ignored probe configs and wave evidence.
source('dev/install_specmill.R')
verify_specmill()
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
w <- jsonlite::read_json('dev/specmill-rebuild/wave-resolver-transformations.json')
probe <- list()
for (file in c(
  'apis/chemi-resolver-prod-rebuild.yml',
  'apis/chemi-amos-prod-full.yml',
  'apis/chemi-safety-prod-rebuild.yml'
)) {
  s <- yaml::read_yaml(file)
  for (key in names(s$operations)) {
    op <- s$operations[[key]]
    name <- op$name
    if (!name %in% names(w$policies)) {
      next
    }
    op$implementation <- 'generated'
    s$documentation <- FALSE
    s$schemas$files <- as.list(s$schemas$files)
    s$operations <- setNames(list(op), key)
    s$selection$include <- list(key)
    if (name == 'chemi_resolver_getsimilaritymap') {
      s$hooks <- list(
        chemi_resolver_getsimilaritymap = list(
          pre_request = list('resolve_query_to_chemical_records', 'flatten_similarity_map_chemicals'),
          post_response = list('format_similarity_map_result')
        )
      )
      s$prepare <- 'preserve_choice_defaults'
    }
    d <- 'dev/specmill-pilot/artifacts/transformations-probe'
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    yaml::write_yaml(s, file.path(d, 'service.yml'))
    yaml::write_yaml(
      list(config_version = 1L, package = 'ComptoxR', services = list(file.path(d, 'service.yml'))),
      file.path(d, 'project.yml')
    )
    project <- specmill::load_project('.', config = file.path(d, 'project.yml'), callbacks = callbacks)
    native <- specmill::read_operations(s$schemas$files[[1]], policy = project$services[[1]]$policy)
    stopifnot(length(native$diagnostics) == 0, length(native$operations) == 1)
    mapped <- specmill:::configure_operation(native$operations[[1]], project$services[[1]])
    mapped$operation <- callbacks$preserve_choice_defaults(mapped$operation)
    code <- specmill::render_operation(mapped$operation, mapped$spec)
    e <- new.env(parent = baseenv())
    eval(parse(text = code), e)
    if (name == 'chemi_resolver_getsimilaritymap') {
      e$run_hook <- function(fn, stage, data) {
        original <- names(readRDS('tests/testthat/fixtures/specmill-rebuild-contracts.rds')[[name]]$calls[[1]]$arguments[[3]]$params)
        stopifnot(!identical(names(data$params), original))
        probe[[name]] <<- list(
          generated_pre_params = as.list(names(data$params)),
          original_pre_params = as.list(original),
          compatible = identical(names(data$params), original)
        )
        list(skip_request = TRUE, result = NULL)
      }
      do.call(e[[name]], list(query = 'one'))
    } else {
      contract <- readRDS('tests/testthat/fixtures/specmill-rebuild-contracts.rds')[[name]]
      assign(op$helper, function(...) contract$calls[[1]]$response, e)
      value <- do.call(e[[name]], contract$inputs)
      probe[[name]] <- list(
        generated_class = as.list(class(value)),
        original_class = as.list(class(contract$result)),
        generated_fields = as.list(names(value)),
        original_fields = as.list(names(contract$result)),
        compatible = identical(value, contract$result)
      )
      stopifnot(!probe[[name]]$compatible)
    }
  }
}
w$compatibility_probe <- probe
jsonlite::write_json(w, 'dev/specmill-rebuild/wave-resolver-transformations.json', pretty = TRUE, auto_unbox = TRUE)
