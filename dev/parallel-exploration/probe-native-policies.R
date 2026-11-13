# Rscript dev/parallel-exploration/probe-native-policies.R
# Test existing Specmill settings without changing production configuration or helpers.
probe_native_policies <- function() {
  source("dev/install_specmill.R", local = TRUE)
  verify_specmill()
  pkgload::load_all(quiet = TRUE)
  root <- tempfile("native-policy-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  paths <- system2("git", "ls-files", stdout = TRUE)
  paths <- paths[grepl("^(R/|schema/|inst/|tests/testthat/fixtures/|[.]specmill/|DESCRIPTION$|NAMESPACE$|air.toml$)", paths)]
  for (path in paths) {
    dir.create(dirname(file.path(root, path)), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(path, file.path(root, path)))
  }
  config <- yaml::read_yaml("specmill.yml", handlers = list(seq = function(x) x))
  config$documentation <- FALSE
  config$callback_files <- NULL
  config$services <- list("apis/ctx_chemical.yml")
  yaml::write_yaml(config, file.path(root, "specmill.yml"))
  service <- yaml::read_yaml("apis/ctx_chemical.yml", handlers = list(seq = function(x) x))
  key <- "POST /chemical/detail/search/by-dtxsid/"
  original <- service$groups$ctx_chemical
  service$groups <- list()
  variants <- list()
  for (policy in c("legacy", "metadata", "defaults")) {
    for (concurrency in c(1L, 2L)) {
      name <- paste0("probe_", policy, "_", concurrency)
      group <- original
      group$hook_config <- group$contracts_file <- NULL
      group$selection <- list(include = list(key))
      group$names <- stats::setNames(list(name), key)
      settings <- original$operations[[key]]
      settings$batch$concurrency <- concurrency
      if (policy != "legacy") settings$batch$metadata <- TRUE
      if (policy == "defaults") settings$batch$warning <- NULL
      settings$request_controls <- list(max_retries = 0L,
        throttle = list(capacity = 2L, fill_time_s = 1))
      group$operations <- stats::setNames(list(settings), key)
      service$groups[[name]] <- group
      variants[[name]] <- list(policy = policy, concurrency = concurrency)
    }
  }
  dir.create(file.path(root, "apis"))
  yaml::write_yaml(service, file.path(root, "apis/ctx_chemical.yml"), precision = 17)
  callbacks <- new.env(parent = baseenv())
  for (file in yaml::read_yaml("specmill.yml")$callback_files) sys.source(file, callbacks)
  plan <- specmill::generate_client(root, config = "specmill.yml", callbacks = callbacks,
    mode = "apply", artifacts = "wrappers", validation = TRUE)
  stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics), !length(plan$drift))
  runtime <- list2env(as.list(asNamespace("ComptoxR"), all.names = TRUE),
    parent = asNamespace("ComptoxR"))
  for (name in names(variants)) sys.source(file.path(root, "R", paste0(name, ".R")), runtime)
  withr::local_envvar(c(batch_limit = "1", ctx_api_key = "mock-policy-key"))
  withr::local_options(list(comptoxr_native.ct_request.batching = list(), comptoxr_native.request = list()))
  scenario <- "transport"
  index <- 0L
  next_response <- function(req) {
    stopifnot(req$method == "POST")
    index <<- index + 1L
    if (index == 2L && scenario == "transport") return(simpleError("simulated transport timeout"))
    status <- if (index == 2L && scenario == "http") 503L else 200L
    label <- c("first", "middle", "last")[[index]]
    httr2::response(status_code = status, headers = list(`content-type` = "application/json"),
      body = charToRaw(sprintf('[{"dtxsid":"%s"}]', label)))
  }
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      response <- next_response(req)
      if (inherits(response, "error")) stop(response)
      response
    },
    req_perform_parallel = function(reqs, ...) lapply(reqs, next_response),
    .package = "httr2")
  results <- list()
  for (scenario in c("success", "transport", "http")) {
    for (name in names(variants)) {
      index <- 0L
      warnings <- character()
      result <- withCallingHandlers(get(name, runtime)(
        query = c("first", "middle", "last"), projection = "chemicalidentifier"), warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        })
      variant <- variants[[name]]
      failed <- attr(result, "failed")
      failure <- scenario != "success"
      expected_warning <- failure && (scenario == "http" || variant$policy == "defaults")
      stopifnot(index == 3L, inherits(result, "tbl_df"),
        identical(result$dtxsid, if (failure) c("first", "last") else c("first", "middle", "last")),
        length(warnings) == as.integer(expected_warning),
        length(failed) == as.integer(failure && variant$policy != "legacy"))
      results[[paste(name, scenario, sep = "/")]] <- c(variant, list(scenario = scenario,
        rows = nrow(result), warnings = warnings, failed = failed, assertions_passed = TRUE))
    }
  }
  summary <- list(checked_at = format(Sys.time(), tz = "UTC"),
    toolkit = jsonlite::read_json("dev/specmill-lock.json"),
    operation = key, config = "apis/ctx_chemical.yml", schema = "schema/ctx_chemical_prod.json",
    transport = "mocked, no network", results = results)
  jsonlite::write_json(summary, "dev/parallel-exploration/native-policy-probes.json",
    pretty = TRUE, auto_unbox = TRUE, null = "null")
  cat("Passed 18 generated-wrapper policy cases; return types preserved.\n")
  invisible(summary)
}

if (sys.nframe() == 0L) probe_native_policies()
