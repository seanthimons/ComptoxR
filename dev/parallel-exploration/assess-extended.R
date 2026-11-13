# Run after dev/explore_parallel.R --extended --live.
# Add --aed-control to capture repeated original sequential AED calls.
assess_extended <- function(control = FALSE) {
  pkgload::load_all(quiet = TRUE)
  folder <- "dev/parallel-exploration"
  captures <- readRDS(file.path(folder, "extended-post-captures.rds"))
  canonical <- function(x) dplyr::arrange(x[sort(names(x))], dplyr::across(dplyr::everything()))
  compare <- function(a, b) list(exact = identical(a, b),
    same_column_sets = setequal(names(a), names(b)),
    same_ordered_records = identical(a[sort(names(a))], b[sort(names(b))]),
    same_record_multiset = identical(canonical(a), canonical(b)),
    sequential_rows = nrow(a), parallel_rows = nrow(b))
  comparisons <- lapply(captures, function(x) compare(x$sequential$result, x$parallel$result))
  stopifnot(length(comparisons) == 8L,
    all(vapply(comparisons, function(x) x$same_record_multiset, FALSE)))
  # Chunk-size changes must preserve duplicate counts and the complete record set.
  across_sizes <- lapply(names(captures)[endsWith(names(captures), "/10")], function(name) {
    other <- sub("/10$", "/25", name)
    comparison <- compare(captures[[name]]$parallel$result, captures[[other]]$parallel$result)
    stopifnot(comparison$same_record_multiset)
    comparison
  })
  names(across_sizes) <- sub("/10$", "", names(captures)[endsWith(names(captures), "/10")])
  # The multiset comparison must reject real data loss and value changes.
  table <- captures[[1L]]$parallel$result
  changed <- table
  changed$dtxsid[[1L]] <- "changed"
  stopifnot(!compare(table, table[-1L, , drop = FALSE])$same_record_multiset,
    !compare(table, changed)$same_record_multiset)
  control_comparisons <- list()
  control_inputs <- head(captures[["ct_bioactivity_data_aed_search_by_dtxsid_bulk/10"]]$args$dtxsid, 10L)
  if (control) {
    withr::local_envvar(c(batch_limit = "10"))
    withr::local_options(list(comptoxr_native.ct_request.batching = list(),
      comptoxr_native.request = list(timeout = 15, max_retries = 0,
        throttle = list(capacity = 2, fill_time_s = 1))))
    stopifnot(nzchar(Sys.getenv("ctx_api_key")))
    state <- get(".ComptoxREnv", asNamespace("ComptoxR"))
    old <- state$probe_observer
    on.exit(state$probe_observer <- old, add = TRUE)
    saved <- list()
    for (i in seq_len(4L)) {
      bodies <- list()
      state$probe_observer <- function(response) {
        stopifnot(httr2::resp_status(response) == 200L)
        bodies[[length(bodies) + 1L]] <<- httr2::resp_body_string(response)
      }
      result <- ComptoxR::ct_bioactivity_data_aed_search_by_dtxsid_bulk(control_inputs)
      stopifnot(length(bodies) == 1L, nrow(result) > 1L)
      saved[[i]] <- list(result = result, bodies = bodies)
      saveRDS(saved, file.path(folder, "aed-sequential-captures.rds"))
      if (i > 1L) {
        verdict <- compare(saved[[1L]]$result, result)
        control_comparisons[[i - 1L]] <- verdict
        message("AED sequential repeat ", i, ": same order=", verdict$same_ordered_records,
          ", same records=", verdict$same_record_multiset)
        stopifnot(verdict$same_record_multiset)
        if (!verdict$same_ordered_records) break
      }
    }
  }
  wire_order_preserved <- NULL
  control_file <- file.path(folder, "aed-sequential-captures.rds")
  if (file.exists(control_file)) {
    saved <- readRDS(control_file)
    control_comparisons <- lapply(saved[-1L], function(x) compare(saved[[1L]]$result, x$result))
    wire_order_preserved <- vapply(saved, function(x) {
      body <- jsonlite::fromJSON(x$bodies[[1L]], simplifyVector = FALSE)
      identical(vapply(body, function(row) row$aeid, integer(1)), x$result$aeid)
    }, FALSE)
    stopifnot(all(wire_order_preserved),
      all(vapply(control_comparisons, function(x) x$same_record_multiset, FALSE)))
  }
  summary <- list(checked_at = format(Sys.time(), tz = "UTC"), paired_comparisons = comparisons,
    cross_chunk_sizes = across_sizes, rejects_missing_rows = TRUE, rejects_changed_values = TRUE,
    aed_control_inputs = if (file.exists(control_file)) control_inputs else NULL,
    aed_table_follows_wire_row_order = wire_order_preserved,
    original_sequential_aed_control = control_comparisons)
  jsonlite::write_json(summary, file.path(folder, "extended-assessment.json"),
    pretty = TRUE, auto_unbox = TRUE)
  invisible(summary)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(TRUE)
  stopifnot(all(args %in% "--aed-control"))
  assess_extended("--aed-control" %in% args)
}
