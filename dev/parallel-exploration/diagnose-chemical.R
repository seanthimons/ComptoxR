# Run from the package root. Captures only public chemical responses, never requests.
# Rscript dev/parallel-exploration/diagnose-chemical.R [--replay]
diagnose_chemical <- function(replay = FALSE) {
  pkgload::load_all(quiet = TRUE)
  withr::local_envvar(c(batch_limit = "1"))
  withr::local_options(list(comptoxr_native.ct_request.batching = list(),
    comptoxr_native.request = list(timeout = 15, max_retries = 0,
      throttle = list(capacity = 2, fill_time_s = 1))))
  output <- "dev/parallel-exploration/chemical-diagnosis"
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  ids <- c("DTXSID7020182", "DTXSID9020112", "DTXSID2021315")
  compare <- function(a, b) list(
    exact = identical(a, b),
    same_columns = setequal(names(a), names(b)),
    columns_a = names(a), columns_b = names(b),
    equal_by_column = if (setequal(names(a), names(b))) identical(a[sort(names(a))], b[sort(names(b))]) else FALSE,
    difference = all.equal(a, b))
  fetch <- function(query = ids) ComptoxR::ct_chemical_detail_search_by_dtxsid_bulk(
    query = query, projection = "chemicalidentifier")
  if (replay) {
    saved <- readRDS(file.path(output, "mismatch.rds"))
    withr::local_envvar(c(ctx_api_key = "local-replay"))
    replay_one <- function(capture, query = ids) {
      index <- 0L
      testthat::local_mocked_bindings(req_perform = function(req, ...) {
        index <<- index + 1L
        item <- capture$responses[[index]]
        httr2::response(status_code = item$status,
          headers = list(`content-type` = "application/json"), body = charToRaw(item$body))
      }, .package = "httr2")
      result <- fetch(query)
      stopifnot(index == length(capture$responses), identical(result, capture$result))
      result
    }
    a <- replay_one(saved$a)
    b <- replay_one(saved$b)
    verdict <- compare(a, b)
    stopifnot(!verdict$exact, verdict$equal_by_column, identical(verdict, saved$comparison))
    # One identifier and one response per call suffice to reproduce the symptom.
    first <- function(capture) list(result = capture$result[1L, , drop = FALSE],
      responses = capture$responses[1L])
    single_a <- replay_one(first(saved$a), ids[[1L]])
    single_b <- replay_one(first(saved$b), ids[[1L]])
    single_verdict <- compare(single_a, single_b)
    stopifnot(!single_verdict$exact, single_verdict$equal_by_column)
    # Fixed bodies decode deterministically; the field order changes on the wire.
    stopifnot(identical(single_a, replay_one(first(saved$a), ids[[1L]])))
    fields <- function(capture) names(jsonlite::fromJSON(capture$responses[[1L]]$body,
      simplifyVector = FALSE)[[1L]])
    stopifnot(identical(fields(saved$a), names(single_a)),
      identical(fields(saved$b), names(single_b)))
    # Comparing by name must still detect changed values and reordered rows.
    changed <- single_b
    changed$dtxsid[[1L]] <- "changed"
    stopifnot(!compare(single_a, changed)$equal_by_column,
      !compare(a, b[rev(seq_len(nrow(b))), , drop = FALSE])$equal_by_column)
    evidence <- list(reproduced_without_network = TRUE, original_wrapper_only = TRUE,
      single_identifier_sufficient = TRUE, decoder_deterministic = TRUE,
      detects_value_changes = TRUE, detects_row_reordering = TRUE,
      response_fields_a = fields(saved$a), response_fields_b = fields(saved$b),
      comparison = verdict, single_response_comparison = single_verdict)
    jsonlite::write_json(evidence, file.path(output, "replay.json"), pretty = TRUE, auto_unbox = TRUE)
    cat("Captured mismatch reproduced through the original sequential POST wrapper, without network.\n")
    print(verdict)
    return(invisible(verdict))
  }
  stopifnot(nzchar(Sys.getenv("ctx_api_key")))
  state <- get(".ComptoxREnv", asNamespace("ComptoxR"))
  old <- state$probe_observer
  on.exit(state$probe_observer <- old, add = TRUE)
  captures <- list()
  comparisons <- list()
  for (i in seq_len(8L)) {
    responses <- list()
    state$probe_observer <- function(response) {
      responses[[length(responses) + 1L]] <<- list(status = httr2::resp_status(response),
        body = httr2::resp_body_string(response))
    }
    result <- fetch()
    stopifnot(length(responses) == length(ids), all(vapply(responses, function(x) x$status == 200L, FALSE)))
    captures[[i]] <- list(result = result, responses = responses)
    saveRDS(captures, file.path(output, "sequential-captures.rds"))
    if (i > 1L) {
      comparison <- compare(captures[[1L]]$result, result)
      comparisons[[length(comparisons) + 1L]] <- comparison
      message("Sequential POST repeat ", i, ": exact=", comparison$exact,
        ", equal by column=", comparison$equal_by_column)
      if (!comparison$exact) {
        saveRDS(list(a = captures[[1L]], b = captures[[i]], comparison = comparison),
          file.path(output, "mismatch.rds"))
        break
      }
    }
  }
  summary <- list(checked_at = format(Sys.time(), tz = "UTC"),
    wrapper = "ct_chemical_detail_search_by_dtxsid_bulk",
    operation = "POST /chemical/detail/search/by-dtxsid/", projection = "chemicalidentifier",
    inputs = ids, chunk_size = 1L, execution = "original sequential wrapper only",
    calls = length(captures), comparisons = comparisons,
    mismatch_captured = any(!vapply(comparisons, function(x) x$exact, FALSE)))
  jsonlite::write_json(summary, file.path(output, "summary.json"), pretty = TRUE, auto_unbox = TRUE)
  invisible(summary)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(TRUE)
  stopifnot(all(args %in% "--replay"))
  diagnose_chemical(replay = "--replay" %in% args)
}
