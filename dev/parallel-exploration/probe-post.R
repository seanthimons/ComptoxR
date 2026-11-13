# Called by dev/explore_parallel.R --post or --extended after disposable generation.
probe_parallel_post <- function(root, live = FALSE, extended = FALSE) {
  pkgload::load_all(quiet = TRUE)
  withr::local_envvar(c(batch_limit = "1"))
  withr::local_options(list(comptoxr_native.ct_request.batching = list(),
    comptoxr_native.request = list(timeout = 15, max_retries = 0,
      throttle = list(capacity = 2, fill_time_s = 1))))
  # Generated callbacks can resolve private helpers with inherits = FALSE.
  runtime <- list2env(as.list(asNamespace("ComptoxR"), all.names = TRUE),
    parent = asNamespace("ComptoxR"))
  ids <- c("DTXSID7020182", "DTXSID9020112", "DTXSID2021315", "DTXSID7020182")
  calls <- list(
    ct_chemical_detail_search_by_dtxsid_bulk = list(query = ids, projection = "chemicalidentifier"),
    ct_bioactivity_data_aed_search_by_dtxsid_bulk = list(dtxsid = ids),
    ct_exposure_seem_general_search_by_dtxsid_bulk = list(dtxsid = ids),
    ct_hazard_genetox_summary_search_by_dtxsid_bulk = list(dtxsid = ids))
  for (name in names(calls)) sys.source(file.path(root, "R", paste0(name, ".R")), runtime)
  state <- get(".ComptoxREnv", asNamespace("ComptoxR"))
  old_observer <- state$probe_observer
  on.exit(state$probe_observer <- old_observer, add = TRUE)
  run <- function(fn, args) {
    warnings <- character()
    statuses <- integer()
    bodies <- list()
    state$probe_observer <- function(response) {
      statuses <<- c(statuses, httr2::resp_status(response))
      if (extended) bodies[[length(bodies) + 1L]] <<- httr2::resp_body_string(response)
    }
    result <- tryCatch(withCallingHandlers(do.call(fn, args), warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }), error = identity)
    list(result = result, warnings = warnings, statuses = statuses, bodies = bodies)
  }
  compare <- function(a, b) {
    tables <- is.data.frame(a$result) && is.data.frame(b$result)
    same_columns <- tables && setequal(names(a$result), names(b$result))
    aligned <- if (same_columns) all.equal(a$result[sort(names(a$result))], b$result[sort(names(b$result))]) else NULL
    list(
    sequential_statuses = a$statuses, parallel_statuses = b$statuses,
    sequential_error = if (inherits(a$result, "error")) conditionMessage(a$result) else NULL,
    parallel_error = if (inherits(b$result, "error")) conditionMessage(b$result) else NULL,
    identical_result = identical(a$result, b$result),
    sequential_columns = if (tables) names(a$result) else NULL,
    parallel_columns = if (tables) names(b$result) else NULL,
    comparison_after_column_order = aligned,
    comparison = if (!inherits(a$result, "error") && !inherits(b$result, "error")) all.equal(a$result, b$result) else NULL,
    sequential_warnings = a$warnings, parallel_warnings = b$warnings,
    parallel_rows = if (is.data.frame(b$result)) nrow(b$result) else NULL,
    input_groups = if (is.data.frame(b$result) && "dtxsid" %in% names(b$result)) unname(rle(b$result$dtxsid)$values) else NULL)
  }
  safe_capture <- function(x) {
    # HTTP error conditions can retain requests, including auth headers.
    if (inherits(x$result, "error")) x$result <- list(error = conditionMessage(x$result), classes = class(x$result))
    x
  }

  # Delayed HTTP responses prove real overlap and deliberately finish out of order.
  directory <- tempfile("post-server-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  server <- callr::r_bg(function(directory) {
    active <- peak <- 0L
    requests <- completed <- list()
    json <- function(body, status = 200L) list(status = status,
      headers = list("Content-Type" = "application/json"),
      body = as.character(jsonlite::toJSON(body, auto_unbox = TRUE)))
    port <- httpuv::randomPort()
    handle <- httpuv::startServer("127.0.0.1", port, list(call = function(req) {
      if (req$PATH_INFO == "/reset") {
        stopifnot(active == 0L)
        peak <<- 0L
        requests <<- completed <<- list()
        return(json(list()))
      }
      if (req$PATH_INFO == "/state") return(json(list(active = active, peak = peak, requests = requests, completed = completed)))
      text <- rawToChar(req$rook.input$read())
      stopifnot(req$REQUEST_METHOD == "POST", startsWith(req$CONTENT_TYPE, "application/json"), startsWith(text, "["))
      items <- unname(unlist(jsonlite::fromJSON(text)))
      requests[[length(requests) + 1L]] <<- items
      active <<- active + 1L
      peak <<- max(peak, active)
      promises::promise(function(resolve, reject) later::later(function() {
        active <<- active - 1L
        completed[[length(completed) + 1L]] <<- items
        failures <- c(DTXSID0000000 = 404L, DTXSID0000001 = 429L,
          DTXSID0000002 = 503L, DTXSID0000004 = 401L)
        failure <- intersect(items, names(failures))
        status <- if (length(failure)) unname(failures[[failure[[1L]]]]) else 200L
        resolve(json(lapply(items, function(id) list(dtxsid = id)), status))
      }, if ("DTXSID0000003" %in% items) 1.2 else if ("DTXSID7020182" %in% items) 0.2 else 0.03))
    }))
    on.exit(httpuv::stopServer(handle))
    saveRDS(port, file.path(directory, "ready.rds"))
    repeat { httpuv::service(10); later::run_now(0) }
  }, list(directory), supervise = TRUE)
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(200L)) {
    if (file.exists(file.path(directory, "ready.rds"))) break
    if (!server$is_alive()) server$get_result()
    Sys.sleep(0.025)
  }
  stopifnot(file.exists(file.path(directory, "ready.rds")))
  origin <- paste0("http://127.0.0.1:", readRDS(file.path(directory, "ready.rds")))
  control <- function(path) httr2::resp_body_json(httr2::req_perform(httr2::request(paste0(origin, path))))
  settled <- function() {
    for (i in seq_len(100L)) {
      value <- control("/state")
      if (value$active == 0L) return(value)
      Sys.sleep(0.025)
    }
    stop("Local server did not settle")
  }
  local_results <- list()
  local_captures <- list()
  local_checks <- function() {
    withr::local_envvar(c(ctx_api_key = "local-fixture"))
    withr::local_options(list(ComptoxR.ctx_burl = origin,
      comptoxr_native.request = list(timeout = 10, max_retries = 0,
        throttle = list(capacity = 100, fill_time_s = 1))))
    # The fixture speaks HTTP/1.1; avoid curl waiting for HTTP/2 negotiation.
    perform_parallel <- httr2::req_perform_parallel
    testthat::local_mocked_bindings(req_perform_parallel = function(reqs, ...) {
      perform_parallel(lapply(reqs, httr2::req_options, http_version = 1L), ...)
    }, .package = "httr2")
    for (name in names(calls)[c(1L, 4L)]) {
      scenarios <- c("success", "drop", "stop", if (extended) c("rate", "server", "timeout", "auth", "all_failed"))
      for (scenario in scenarios) {
        withr::with_options(list(comptoxr_native.ct_request.batching =
          if (scenario == "stop") list(on_error = "stop") else list(),
          comptoxr_native.request = list(timeout = if (scenario == "timeout") 0.5 else 10,
            max_retries = 0, throttle = list(capacity = 100, fill_time_s = 1))), {
          args <- calls[[name]]
          failed_id <- switch(scenario, rate = "DTXSID0000001", server = "DTXSID0000002",
            timeout = "DTXSID0000003", auth = "DTXSID0000004", "DTXSID0000000")
          input <- if (scenario == "success") ids else if (scenario == "all_failed") {
            c("DTXSID0000000", "DTXSID0000001", "DTXSID0000002")
          } else c(ids[[1L]], failed_id, ids[[2L]])
          args[[1L]] <- input
          control("/reset")
          a <- run(get(name, asNamespace("ComptoxR")), args)
          serial_state <- settled()
          control("/reset")
          b <- run(get(name, runtime), args)
          parallel_state <- settled()
          if (extended) {
            local_captures[[paste(name, scenario, sep = "/")]] <<- list(
              sequential = safe_capture(a), parallel = safe_capture(b),
              serial_state = serial_state, parallel_state = parallel_state)
            saveRDS(local_captures, "dev/parallel-exploration/extended-local-captures.rds")
          }
          message("Local POST ", name, " / ", scenario, ": peaks ",
            serial_state$peak, "/", parallel_state$peak)
          if (inherits(b$result, "error") && !scenario %in% c("stop", "auth")) stop(b$result)
          # A client timeout does not cancel work already running on the server.
          stopifnot(serial_state$peak == if (scenario == "timeout") 2L else 1L, parallel_state$peak == 2L,
            length(serial_state$requests) == if (scenario %in% c("stop", "auth")) 2L else 3L,
            length(parallel_state$requests) == 3L,
            all(lengths(parallel_state$requests) == 1L),
            identical(unname(unlist(parallel_state$requests)), unique(input)))
          if (scenario %in% c("stop", "auth")) {
            stopifnot(inherits(a$result, "error"), inherits(b$result, "error"),
              identical(class(a$result), class(b$result)), identical(conditionMessage(a$result), conditionMessage(b$result)))
          } else {
            expected <- unique(input[!startsWith(input, "DTXSID000000")])
            stopifnot(identical(a$result, b$result), identical(a$warnings, b$warnings),
              if (scenario == "all_failed") nrow(b$result) == 0L else identical(b$result$dtxsid, expected))
            if (scenario == "success") stopifnot(identical(parallel_state$completed[[1L]], ids[[2L]]))
            if (scenario != "success") stopifnot(
              if (name == "ct_hazard_genetox_summary_search_by_dtxsid_bulk") {
                identical(names(attr(b$result, "failed")), input[startsWith(input, "DTXSID000000")])
              } else is.null(attr(b$result, "failed")))
            if (scenario == "timeout" && name == "ct_chemical_detail_search_by_dtxsid_bulk") {
              stopifnot(nrow(b$result) == 2L, length(b$warnings) == 0L, is.null(attr(b$result, "failed")))
            }
          }
          local_results[[paste(name, scenario, sep = "/")]] <<- c(compare(a, b),
            list(assertions_passed = TRUE, sequential_peak = serial_state$peak,
              parallel_peak = parallel_state$peak, post_requests = length(parallel_state$requests),
              completion_order = unname(unlist(parallel_state$completed))))
        })
      }
    }
  }
  local_checks()
  live_results <- list()
  live_captures <- list()
  if (live && nzchar(Sys.getenv("ctx_api_key"))) {
    test_ids <- if (extended) head(unique(ComptoxR::testing_chemicals$dtxsid), 27L) else ids
    for (size in if (extended) c(10L, 25L) else 1L) {
      withr::with_envvar(c(batch_limit = as.character(size)), {
        for (name in names(calls)) {
          message("POST probe: ", name, " / chunk size ", size)
          args <- calls[[name]]
          args[[1L]] <- test_ids
          a <- run(get(name, asNamespace("ComptoxR")), args)
          b <- run(get(name, runtime), args)
          key <- if (extended) paste(name, size, sep = "/") else name
          live_results[[key]] <- c(compare(a, b), list(chunk_size = size,
            expected_chunks = ceiling(length(unique(test_ids)) / size)))
          if (extended) {
            live_captures[[key]] <- list(args = args, sequential = safe_capture(a), parallel = safe_capture(b))
            saveRDS(live_captures, "dev/parallel-exploration/extended-post-captures.rds")
          }
        }
      })
    }
  }
  list(checked_at = format(Sys.time(), tz = "UTC"),
    toolkit = jsonlite::read_json("dev/specmill-lock.json"), chunk_sizes = if (extended) c(10L, 25L) else 1L,
    concurrency = 2L, inputs = if (extended && length(live_results)) test_ids else ids,
    normalized_inputs = unique(if (extended && length(live_results)) test_ids else ids), local = local_results, live = live_results,
    live_skipped = if (!live) "not requested" else if (!nzchar(Sys.getenv("ctx_api_key"))) "ctx_api_key unavailable" else NULL)
}
