#!/usr/bin/env Rscript
.coverage_check_root <- specmill::script_root('check-coverage.R')
R_THRESHOLD <- 75
check_coverage <- function(root = .coverage_check_root, threshold = R_THRESHOLD) {
  coverage <- covr::package_coverage(path = root)
  percent <- covr::percent_coverage(coverage)
  cat(sprintf('R/ Coverage: %.2f%% (threshold: %d%%)\n', percent, threshold))
  if (percent < threshold) {
    stop('Package coverage is below the required threshold')
  }
  invisible(percent)
}
if (sys.nframe() == 0L) {
  check_coverage()
}
