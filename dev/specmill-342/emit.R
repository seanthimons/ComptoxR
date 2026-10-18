# Reviewed manual adoption: expose the native decoder for existing httr2 execution.
# Transport errors, response observation and collection policy remain client-owned.
emit_issue342 <- function(root = '.', mode = c('check', 'apply'), adopt = NULL) {
  mode <- match.arg(mode)
  source('dev/install_specmill.R', local = TRUE)
  verify_specmill()
  scaffold <- specmill:::request_helper_scaffold(
    '.ct_request',
    'https://example.invalid',
    NULL,
    'COMPTOXR_NATIVE_DRY_RUN',
    companions = c('batching', 'pagination')
  )
  code <- scaffold$code
  # These companions are internal implementation details, not new public APIs.
  code <- gsub("#' @export", "#' @noRd", code, fixed = TRUE)
  code <- paste(sub('[ \t]+$', '', strsplit(code, '\n', fixed = TRUE)[[1L]]), collapse = '\n')
  helper <- file.path(root, 'R/z_specmill_request.R')
  record <- file.path(root, '.specmill/helpers/.ct_request.json')
  matches <- file.exists(helper) && identical(readLines(helper), strsplit(code, '\n', fixed = TRUE)[[1L]])
  if (mode == 'check') {
    stopifnot(matches, identical(paste(readLines(record), collapse = '\n'), scaffold$provenance))
    return(invisible(scaffold))
  }
  if (file.exists(helper) && !matches && !identical(digest::digest(file = helper, algo = 'sha256'), adopt)) {
    stop('Protected native helper; supply its reviewed SHA256 for manual adoption.')
  }
  dir.create(file.path(root, '.specmill/helpers'), recursive = TRUE, showWarnings = FALSE)
  writeLines(code, helper)
  writeLines(scaffold$provenance, record)
  invisible(scaffold)
}

if (sys.nframe() == 0L) {
  emit_issue342()
}
