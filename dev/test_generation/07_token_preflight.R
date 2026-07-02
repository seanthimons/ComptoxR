# Token preflight for live cassette recording.

ctx_api_key_status <- function(value = Sys.getenv("ctx_api_key")) {
  value <- trimws(value %tg||% "")
  lower <- tolower(value)

  placeholder_patterns <- c(
    "^$",
    "dummy",
    "placeholder",
    "your_?key",
    "token here",
    "api[_ -]?key",
    "redacted",
    "masked",
    "^x+$",
    "^\\*+$",
    "^<+.*>+$",
    "<<<.*>>>",
    "test_api_key",
    "logic_test_key"
  )

  if (!nzchar(value)) {
    return(list(valid = FALSE, reason = "ctx_api_key is not set"))
  }

  for (pattern in placeholder_patterns) {
    if (grepl(pattern, lower, perl = TRUE)) {
      return(list(valid = FALSE, reason = "ctx_api_key looks like a placeholder or redacted value"))
    }
  }

  list(valid = TRUE, reason = "ok")
}

ctx_api_key_preflight <- function(value = Sys.getenv("ctx_api_key"), abort = TRUE) {
  status <- ctx_api_key_status(value)
  if (isTRUE(status$valid)) {
    tg_cli_success("ctx_api_key preflight passed")
    return(invisible(TRUE))
  }

  guidance <- c(
    "x" = status$reason,
    "i" = "Set a real token in the ctx_api_key environment variable before live recording.",
    "i" = "Do not paste or print the token in logs. In GitHub Actions, map secrets.CTX_API_KEY to ctx_api_key."
  )

  if (abort) {
    tg_cli_abort(guidance)
  }

  tg_cli_warning(paste(unname(guidance), collapse = "\n"))
  invisible(FALSE)
}
