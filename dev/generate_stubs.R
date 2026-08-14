#!/usr/bin/env Rscript
# ==============================================================================
# Automated Function Stub Generation for CI
# ==============================================================================
#
# This script generates R function stubs from OpenAPI schemas for active APIs:
#   - CompTox Dashboard (ct_*)
#   - Cheminformatics (chemi_*)
#
# Designed to be run in CI after schema downloads to automatically create
# function stubs for any new or changed API endpoints.
#
# Usage:
#   Rscript dev/generate_stubs.R
#
# Output:
#   - New function stubs in R/ directory
#   - Summary statistics printed to stdout
#   - Exit code 0 on success
#
# ==============================================================================

# Configs, per-API specs (ct_spec/chemi_spec/api_specs), run_generator(), and the
# endpoint_eval utilities all live in the sourceable module below. Sourcing it has
# no side effects; it is shared with dev/calculate_coverage.R.
suppressPackageStartupMessages(library(here))
source(here::here("dev", "stub_specs.R"))

# Reset endpoint tracking at start of generation run
reset_endpoint_tracking()

# ==============================================================================
# Main Execution
# ==============================================================================

cli_h1("Function Stub Generation")
cli_alert_info("Working directory: {getwd()}")

# Each result is list(scaffold = <tibble>, drift = <tibble>) — uniform shape.
results <- map(api_specs, run_generator)

# Combine scaffold and drift results, tagging each row with its API.
all_results <- imap(results, ~ .x$scaffold %>% mutate(api = .y)) %>% list_rbind()
all_drift <- imap(results, ~ .x$drift %>% mutate(api = .y)) %>% list_rbind()

# Report skipped/suspicious endpoints
report_skipped_endpoints(log_dir = here::here("dev", "logs"))

# ==============================================================================
# Summary
# ==============================================================================

cli_h1("Summary")

# Count actions by type
summary_stats <- all_results %>%
  count(action) %>%
  arrange(desc(n))

if (nrow(all_results) == 0) {
  cli_alert_success("No new function stubs needed - all endpoints are implemented!")
} else {
  # Print summary
  created <- sum(all_results$action == "created", na.rm = TRUE)
  appended <- sum(all_results$action == "appended", na.rm = TRUE)
  skipped <- sum(str_detect(all_results$action, "skipped"), na.rm = TRUE)
  errors <- sum(all_results$action == "error", na.rm = TRUE)

  protected <- sum(all_results$action == "skipped_lifecycle", na.rm = TRUE)

  cli_alert_info("Created: {created} file(s)")
  cli_alert_info("Appended: {appended} file(s)")
  cli_alert_info("Skipped: {skipped} file(s)")
  if (protected > 0) {
    cli_alert_warning("Protected (lifecycle guard): {protected} file(s)")
  }
  if (errors > 0) {
    cli_alert_danger("Errors: {errors} file(s)")
  }

  # List created files
  created_files <- all_results %>%
    filter(action %in% c("created", "appended")) %>%
    pull(path)

  if (length(created_files) > 0) {
    cli_h2("Files Modified")
    for (f in created_files) {
      cli_alert_success("{basename(f)}")
    }
  }
}

# ==============================================================================
# Drift Reporting
# ==============================================================================

if (nrow(all_drift) > 0) {
  cli_h2("Parameter Drift Detected")
  cli_alert_warning(
    "{nrow(all_drift)} parameter drift(s) detected across {length(unique(all_drift$endpoint))} endpoint(s)"
  )

  # Group by endpoint
  for (ep in unique(all_drift$endpoint)) {
    ep_drifts <- all_drift %>% filter(endpoint == ep)
    cli_alert_info("Endpoint: {ep} ({ep_drifts$file[1]})")

    for (i in seq_len(nrow(ep_drifts))) {
      if (ep_drifts$drift_type[i] == "param_added") {
        cli_bullets(c("+" = "Added: {ep_drifts$param_name[i]} ({ep_drifts$schema_value[i]})"))
      } else if (ep_drifts$drift_type[i] == "param_removed") {
        cli_bullets(c("-" = "Removed: {ep_drifts$param_name[i]} (no longer in schema)"))
      }
    }
  }

  # Write drift report to file for CI
  drift_report_path <- here::here("drift_report.csv")
  write.csv(all_drift, drift_report_path, row.names = FALSE)
  cli_alert_info("Drift report written to: {drift_report_path}")
} else {
  cli_alert_success("No parameter drift detected")
}

# Output for GitHub Actions
if (Sys.getenv("GITHUB_OUTPUT") != "") {
  output_file <- Sys.getenv("GITHUB_OUTPUT")

  created <- sum(all_results$action == "created", na.rm = TRUE)
  appended <- sum(all_results$action == "appended", na.rm = TRUE)
  total_new <- created + appended

  drift_count <- nrow(all_drift)
  drift_endpoints <- length(unique(all_drift$endpoint))

  skipped <- sum(str_detect(all_results$action, "skipped"), na.rm = TRUE)
  protected <- sum(all_results$action == "skipped_lifecycle", na.rm = TRUE)

  # Count endpoints that were found but skipped during rendering (empty schemas)
  render_skipped <- sum(vapply(.StubGenEnv$skipped, nrow, integer(1)), na.rm = TRUE)

  cat(sprintf("stubs_generated=%d\n", total_new), file = output_file, append = TRUE)
  cat(sprintf("stubs_created=%d\n", created), file = output_file, append = TRUE)
  cat(sprintf("stubs_appended=%d\n", appended), file = output_file, append = TRUE)
  cat(sprintf("stubs_skipped=%d\n", skipped + render_skipped), file = output_file, append = TRUE)
  cat(sprintf("stubs_protected=%d\n", protected), file = output_file, append = TRUE)
  cat(sprintf("drift_count=%d\n", drift_count), file = output_file, append = TRUE)
  cat(sprintf("drift_endpoints=%d\n", drift_endpoints), file = output_file, append = TRUE)

  cli_alert_info("Output written to GITHUB_OUTPUT")
}

cli_alert_success("Stub generation complete!")
