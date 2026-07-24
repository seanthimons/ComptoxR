#!/usr/bin/env Rscript
# Calculate operation-level API coverage for CCD (ct_*) and Cheminformatic
# (chemi_*) services.
#
# Coverage = implemented operations / total operations, where the operation set
# for each API is exactly what its stub generator builds (one row per
# (route, method); GET and POST on a route are distinct operations). Because
# "implemented" is a subset of "total", coverage is always <= 100% (no artificial
# cap). ct_spec / chemi_spec / endpoint_coverage() come from the shared module so
# coverage matches the stub generator's own notion of an endpoint 1:1.

suppressPackageStartupMessages(library(here))
source(here::here("dev", "stub_specs.R"))

# ==============================================================================
# Coverage (operation-level, from the shared stub-generator specs)
# ==============================================================================
# endpoint_coverage() returns list(total, covered) for one API by counting how
# many of the generator's (route, method) operations have an implemented wrapper.
# `*_functions` therefore holds "covered operations", not raw function defs.

coverage_pct <- function(cov) {
  if (cov$total > 0) round(100 * cov$covered / cov$total, 1) else 0
}

cat("Calculating CCD (CompTox Chemical Dashboard) coverage...\n")
ccd_cov <- endpoint_coverage(ct_spec)
ccd_endpoints <- ccd_cov$total
ccd_functions <- ccd_cov$covered
ccd_coverage <- coverage_pct(ccd_cov)

cat(sprintf("CCD Endpoints: %d\n", ccd_endpoints))
cat(sprintf("CCD Covered: %d\n", ccd_functions))
cat(sprintf("CCD Coverage: %.1f%%\n\n", ccd_coverage))

cat("Calculating Cheminformatic coverage...\n")
chemi_cov <- endpoint_coverage(chemi_spec)
chemi_endpoints <- chemi_cov$total
chemi_functions <- chemi_cov$covered
chemi_coverage <- coverage_pct(chemi_cov)

cat(sprintf("Cheminformatic Endpoints: %d\n", chemi_endpoints))
cat(sprintf("Cheminformatic Covered: %d\n", chemi_functions))
cat(sprintf("Cheminformatic Coverage: %.1f%%\n\n", chemi_coverage))

# ==============================================================================
# Badge colors
# ==============================================================================

get_badge_color <- function(coverage) {
  if (coverage >= 80) {
    "brightgreen"
  } else if (coverage >= 60) {
    "green"
  } else if (coverage >= 40) {
    "yellow"
  } else if (coverage >= 20) {
    "orange"
  } else {
    "red"
  }
}

ccd_color <- get_badge_color(ccd_coverage)
chemi_color <- get_badge_color(chemi_coverage)

# ==============================================================================
# Badge JSON (consumed by README shields.io endpoint badges)
# ==============================================================================

write_badge <- function(path, label, coverage, color) {
  jsonlite::write_json(
    list(
      schemaVersion = 1,
      label = label,
      message = sprintf("%.1f%%", coverage),
      color = color
    ),
    path,
    auto_unbox = TRUE,
    pretty = TRUE
  )
}

write_badge(here::here(".github/badges/ccd-coverage.json"), "CCD coverage", ccd_coverage, ccd_color)
write_badge(here::here(".github/badges/chemi-coverage.json"), "Cheminformatic coverage", chemi_coverage, chemi_color)
cat("Badge JSON updated: .github/badges/{ccd,chemi}-coverage.json\n")

# ==============================================================================
# Coverage deltas (vs baseline)
# ==============================================================================

baseline_path <- here::here("schema", "coverage_baseline.json")
baseline <- if (file.exists(baseline_path)) {
  tryCatch(jsonlite::fromJSON(baseline_path), error = function(e) {
    warning(sprintf("Error reading baseline: %s", e$message))
    NULL
  })
} else {
  NULL
}

format_delta <- function(current, baseline_val) {
  if (is.null(baseline_val) || is.na(baseline_val)) {
    return("")
  }
  diff <- current - baseline_val
  if (abs(diff) < 1e-9) {
    return("")
  }
  is_whole <- abs(current - round(current)) < 1e-9
  if (is_whole) {
    sprintf(" (%+d)", as.integer(round(diff)))
  } else {
    sprintf(" (%+.1f)", diff)
  }
}

ccd_coverage_fmt <- paste0(sprintf("%.1f%%", ccd_coverage), format_delta(ccd_coverage, baseline$ccd_coverage))
ccd_endpoints_fmt <- paste0(ccd_endpoints, format_delta(ccd_endpoints, baseline$ccd_endpoints))
ccd_functions_fmt <- paste0(ccd_functions, format_delta(ccd_functions, baseline$ccd_functions))
chemi_coverage_fmt <- paste0(sprintf("%.1f%%", chemi_coverage), format_delta(chemi_coverage, baseline$chemi_coverage))
chemi_endpoints_fmt <- paste0(chemi_endpoints, format_delta(chemi_endpoints, baseline$chemi_endpoints))
chemi_functions_fmt <- paste0(chemi_functions, format_delta(chemi_functions, baseline$chemi_functions))

cat("\nCoverage deltas (vs baseline):\n")
cat(sprintf("  CCD:   %s | %s endpoints | %s functions\n", ccd_coverage_fmt, ccd_endpoints_fmt, ccd_functions_fmt))
cat(sprintf(
  "  Chemi: %s | %s endpoints | %s functions\n",
  chemi_coverage_fmt,
  chemi_endpoints_fmt,
  chemi_functions_fmt
))

# Write updated baseline
new_baseline <- list(
  ccd_coverage = ccd_coverage,
  ccd_endpoints = ccd_endpoints,
  ccd_functions = ccd_functions,
  chemi_coverage = chemi_coverage,
  chemi_endpoints = chemi_endpoints,
  chemi_functions = chemi_functions,
  timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)
jsonlite::write_json(new_baseline, baseline_path, auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("Baseline updated: %s\n", baseline_path))

# ==============================================================================
# GitHub Actions output
# ==============================================================================

if (Sys.getenv("GITHUB_OUTPUT") != "") {
  output_file <- Sys.getenv("GITHUB_OUTPUT")
  cat(sprintf("ccd_coverage=%.1f\n", ccd_coverage), file = output_file, append = TRUE)
  cat(sprintf("ccd_color=%s\n", ccd_color), file = output_file, append = TRUE)
  cat(sprintf("chemi_coverage=%.1f\n", chemi_coverage), file = output_file, append = TRUE)
  cat(sprintf("chemi_color=%s\n", chemi_color), file = output_file, append = TRUE)
  cat(sprintf("ccd_endpoints=%d\n", ccd_endpoints), file = output_file, append = TRUE)
  cat(sprintf("ccd_functions=%d\n", ccd_functions), file = output_file, append = TRUE)
  cat(sprintf("chemi_endpoints=%d\n", chemi_endpoints), file = output_file, append = TRUE)
  cat(sprintf("chemi_functions=%d\n", chemi_functions), file = output_file, append = TRUE)

  cat(sprintf("ccd_coverage_fmt=%s\n", ccd_coverage_fmt), file = output_file, append = TRUE)
  cat(sprintf("ccd_endpoints_fmt=%s\n", ccd_endpoints_fmt), file = output_file, append = TRUE)
  cat(sprintf("ccd_functions_fmt=%s\n", ccd_functions_fmt), file = output_file, append = TRUE)
  cat(sprintf("chemi_coverage_fmt=%s\n", chemi_coverage_fmt), file = output_file, append = TRUE)
  cat(sprintf("chemi_endpoints_fmt=%s\n", chemi_endpoints_fmt), file = output_file, append = TRUE)
  cat(sprintf("chemi_functions_fmt=%s\n", chemi_functions_fmt), file = output_file, append = TRUE)

  cat("Coverage data written to GITHUB_OUTPUT\n")
}

cat("\n=== Summary ===\n")
cat(sprintf("CCD Coverage: %.1f%% (%d/%d) - Color: %s\n", ccd_coverage, ccd_functions, ccd_endpoints, ccd_color))
cat(sprintf(
  "Cheminformatic Coverage: %.1f%% (%d/%d) - Color: %s\n",
  chemi_coverage,
  chemi_functions,
  chemi_endpoints,
  chemi_color
))
