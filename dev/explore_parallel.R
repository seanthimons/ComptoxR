# Run from the package root: Rscript dev/explore_parallel.R [--live] [--post|--extended]
# Generates experimental wrappers in a disposable directory. Never adopts them.
explore_parallel <- function(live = FALSE, baseline = NULL, post = FALSE, extended = FALSE) {
  source("dev/generate_specmill.R", local = TRUE)
  source("dev/install_specmill.R", local = TRUE)
  verify_specmill()
  if (is.null(baseline)) baseline <- generate_specmill("plan")
  candidates <- Filter(function(op) !is.null(op$iterate), baseline$operations)
  root <- tempfile("comptoxr-parallel-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  paths <- system2("git", c("ls-files"), stdout = TRUE)
  paths <- paths[grepl("^(R/|man/|apis/|schema/|inst/|tests/testthat/fixtures/|[.]specmill/|dev/specmill.*[.]R$|DESCRIPTION$|NAMESPACE$|specmill.yml$|air.toml$)", paths)]
  for (path in paths) {
    dir.create(dirname(file.path(root, path)), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(path, file.path(root, path)))
  }
  # Reconcile baseline-identical output hashes only in the disposable copy.
  manifest_path <- file.path(root, ".specmill/manifest.json")
  manifest <- jsonlite::read_json(manifest_path)
  for (entry in baseline$files) {
    if (entry$action == "unchanged" && !is.null(manifest$files[[entry$file]])) {
      text <- paste(readLines(entry$path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
      manifest$files[[entry$file]]$hash <- digest::digest(enc2utf8(text), algo = "sha256", serialize = FALSE)
    }
  }
  jsonlite::write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE)
  config <- yaml::read_yaml("specmill.yml")
  # This experiment checks emitted code; package documentation is unchanged.
  config$documentation <- FALSE
  yaml::write_yaml(config, file.path(root, "specmill.yml"))
  rows <- list()
  for (file in config$services) {
    service <- yaml::read_yaml(file, handlers = list(seq = function(x) x))
    for (group in names(service$groups)) {
      for (op in Filter(function(op) identical(op$service, group), candidates)) {
        settings <- service$groups[[group]]$operations[[op$key]]
        blocked <- intersect(names(settings), c("request", "cache", "pagination", "route_guard", "preserve_visibility"))
        reason <- if (length(blocked)) paste(blocked, collapse = ", ") else ""
        rows[[op$name]] <- data.frame(service = group, wrapper = op$name,
          operation = op$key, schema = paste(service$schemas$files, collapse = ";"),
          batching = if (isTRUE(op$iterate$split)) "split" else "fan_out",
          eligible = !nzchar(reason), blocker = reason)
        if (nzchar(reason)) next
        settings$batch$concurrency <- 2L
        settings$request_controls$max_retries <- 0L
        # Exploratory limit only, not an assertion about the provider's quota.
        settings$request_controls$throttle <- list(capacity = 2L, fill_time_s = 1)
        service$groups[[group]]$operations[[op$key]] <- settings
      }
    }
    yaml::write_yaml(service, file.path(root, file), precision = 17)
  }
  inventory <- do.call(rbind, unname(rows))
  stopifnot(nrow(inventory) == length(candidates), !anyDuplicated(inventory$wrapper))
  callbacks <- new.env(parent = baseenv())
  for (file in config$callback_files) sys.source(file, callbacks)
  plan <- specmill::generate_client(root, config = "specmill.yml", callbacks = callbacks,
    mode = "apply", artifacts = c("wrappers", "tests"), validation = TRUE)
  stopifnot(!length(plan$diagnostics), !length(plan$mapping_diagnostics),
    !length(plan$retained_diagnostics), !length(plan$drift))
  for (name in inventory$wrapper[inventory$eligible]) {
    code <- readLines(file.path(root, "R", paste0(name, ".R")))
    if (!any(grepl("concurrency = 2", code, fixed = TRUE))) {
      stop("Concurrency missing from ", name, ": ", paste(tail(code, 15), collapse = "\n"))
    }
    emitted <- eval(parse(text = code)[[1L]][[3L]], baseenv())
    current <- eval(parse(file = file.path("R", paste0(name, ".R")))[[1L]][[3L]], baseenv())
    stopifnot(identical(formals(emitted), formals(current)))
  }
  output <- "dev/parallel-exploration"
  dir.create(output, showWarnings = FALSE)
  jsonlite::write_json(list(checked_at = format(Sys.time(), tz = "UTC"),
    toolkit = jsonlite::read_json("dev/specmill-lock.json"),
    httr2 = as.character(utils::packageVersion("httr2")), live = live),
    file.path(output, "metadata.json"), pretty = TRUE, auto_unbox = TRUE)
  jsonlite::write_json(inventory, file.path(output, "inventory.json"), pretty = TRUE, auto_unbox = TRUE)
  probes <- list()
  if (live && !post && !extended) {
    stopifnot(utils::packageVersion("httr2") >= "1.3.0")
    pkgload::load_all(quiet = TRUE)
    runtime <- new.env(parent = asNamespace("ComptoxR"))
    calls <- list(
      ct_chemical_detail_search_by_dtxsid = list(dtxsid = c("DTXSID7020182", "DTXSID9020112"), projection = "chemicalidentifier"),
      ct_bioactivity_analyticalqc_search_by_dtxsid = list(dtxsid = c("DTXSID7020182", "DTXSID9020112")),
      ct_exposure_ccd_production_volume_search_by_dtxsid = list(dtxsid = c("DTXSID7020182", "DTXSID9020112")),
      ct_hazard_genetox_summary_search_by_dtxsid = list(dtxsid = c("DTXSID7020182", "DTXSID9020112")),
      chemi_amos_find_dtxsids = list(internal_id = c("1", "2")),
      chemi_chet_reaction_mappositions = list(map_id = c("1", "2")),
      chemi_toxprints_assays_by_name = list(name = c("AMES", "AMES"))
    )
    old <- options(comptoxr_native.request = list(timeout = 15, max_retries = 0,
      throttle = list(capacity = 2, fill_time_s = 1)))
    on.exit(options(old), add = TRUE)
    for (name in names(calls)) {
      if (!name %in% inventory$wrapper[inventory$eligible]) next
      if (startsWith(name, "ct_") && !nzchar(Sys.getenv("ctx_api_key"))) next
      sys.source(file.path(root, "R", paste0(name, ".R")), runtime)
      sequential <- get(name, asNamespace("ComptoxR"))
      parallel <- get(name, runtime)
      run <- function(fn) {
        warnings <- character()
        result <- tryCatch(withCallingHandlers(do.call(fn, calls[[name]]),
          warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }), error = identity)
        list(result = result, warnings = warnings)
      }
      message("Probing ", name)
      serial <- run(sequential)
      concurrent <- run(parallel)
      failed <- function(x) inherits(x$result, "error") || length(attr(x$result, "failed")) > 0L || length(x$warnings) > 0L
      # Keep only diagnostics; response bodies and credentials are not recorded.
      probes[[name]] <- list(wrapper = name,
        sequential_ok = !failed(serial), parallel_ok = !failed(concurrent),
        identical_result = identical(serial$result, concurrent$result),
        comparison = if (!failed(serial) && !failed(concurrent)) all.equal(serial$result, concurrent$result) else NULL,
        comparison_after_column_order = if (is.data.frame(serial$result) && is.data.frame(concurrent$result) &&
          setequal(names(serial$result), names(concurrent$result))) {
          all.equal(serial$result[sort(names(serial$result))], concurrent$result[sort(names(concurrent$result))])
        } else NULL,
        result_rows = if (is.data.frame(concurrent$result)) nrow(concurrent$result) else NULL,
        result_length = if (is.list(concurrent$result) && !is.data.frame(concurrent$result)) length(concurrent$result) else NULL,
        sequential_warnings = serial$warnings, parallel_warnings = concurrent$warnings,
        sequential_error = if (inherits(serial$result, "error")) conditionMessage(serial$result) else NULL,
        parallel_error = if (inherits(concurrent$result, "error")) conditionMessage(concurrent$result) else NULL)
    }
    jsonlite::write_json(probes, file.path(output, "live-probes.json"), pretty = TRUE, auto_unbox = TRUE)
  }
  if (post || extended) {
    source("dev/parallel-exploration/probe-post.R", local = TRUE)
    probes <- probe_parallel_post(root, live, extended)
    jsonlite::write_json(probes, file.path(output, if (extended) "extended-post-probes.json" else "post-probes.json"),
      pretty = TRUE, auto_unbox = TRUE, null = "null")
  }
  invisible(list(inventory = inventory, probes = probes))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(TRUE)
  stopifnot(all(args %in% c("--live", "--post", "--extended")))
  explore_parallel(live = "--live" %in% args, post = "--post" %in% args, extended = "--extended" %in% args)
}
