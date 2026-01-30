#!/usr/bin/env Rscript
# Coverage verification script for ComptoxR
# Run: Rscript dev/scripts/check-coverage.R
#
# Checks both R/ package code and dev/endpoint_eval/ pipeline code
# Enforces thresholds: R/ >= 75%, dev/ >= 80%
#
# COVERAGE STRATEGY:
# - R/ code: Sent to Codecov + checked in GHA (>=75%)
# - dev/ code: GHA-only check (>=80%), not sent to Codecov
# - Rationale: dev/ is internal tooling, Codecov focuses on shipped package code

cat("=== ComptoxR Coverage Verification ===\n\n")

# Load covr
if (!requireNamespace("covr", quietly = TRUE)) {
  stop("covr package required. Install with: install.packages('covr')")
}

# Define thresholds
R_THRESHOLD <- 75
DEV_THRESHOLD <- 80

# Check R/ package coverage
cat("📊 Measuring R/ package coverage...\n")
r_cov <- covr::package_coverage()
r_pct <- covr::percent_coverage(r_cov)
cat(sprintf("   R/ Coverage: %.2f%% (threshold: %d%%)\n", r_pct, R_THRESHOLD))

# Check dev/endpoint_eval/ coverage
cat("\n📊 Measuring dev/endpoint_eval/ coverage...\n")
dev_files <- list.files("dev/endpoint_eval", pattern = "\\.R$", full.names = TRUE)
dev_tests <- list.files("tests/testthat", pattern = "^test-pipeline", full.names = TRUE)

if (length(dev_files) == 0) {
  cat("   No dev/endpoint_eval/ files found\n")
  dev_pct <- NA
} else if (length(dev_tests) == 0) {
  cat("   No pipeline test files found\n")
  dev_pct <- NA
} else {
  dev_cov <- covr::file_coverage(source_files = dev_files, test_files = dev_tests)
  dev_pct <- covr::percent_coverage(dev_cov)
  cat(sprintf("   dev/ Coverage: %.2f%% (threshold: %d%%)\n", dev_pct, DEV_THRESHOLD))
}

# Summary
cat("\n=== Summary ===\n")
failures <- character(0)

if (r_pct < R_THRESHOLD) {
  failures <- c(failures, sprintf("R/ coverage (%.2f%%) below %d%% threshold", r_pct, R_THRESHOLD))
}

if (!is.na(dev_pct) && dev_pct < DEV_THRESHOLD) {
  failures <- c(failures, sprintf("dev/ coverage (%.2f%%) below %d%% threshold", dev_pct, DEV_THRESHOLD))
}

if (length(failures) > 0) {
  cat("\n❌ FAILED:\n")
  for (f in failures) cat("   -", f, "\n")
  quit(status = 1)
} else {
  cat("\n✅ All coverage thresholds met\n")
  quit(status = 0)
}
