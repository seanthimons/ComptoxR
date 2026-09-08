render_endpoint_site <- function() {
  pkgdown::build_site(new_process = TRUE, preview = FALSE, lazy = TRUE)
  source('dev/check_public_api.R')
  check_public_api('docs', membership = FALSE)
}
if (sys.nframe() == 0L) {
  render_endpoint_site()
}
