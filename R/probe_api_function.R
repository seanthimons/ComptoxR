#' Probe an API wrapper across configured servers
#'
#' Runs one exported `chemi_*` or `ct_*` API wrapper against each server
#' recognized by [chemi_server()] or [ctx_server()]. HTTP responses are observed
#' internally without changing the wrapper's return value or public signature.
#'
#' @param function_name A single exported `chemi_*` or `ct_*` function name.
#'   Matching is case-insensitive.
#' @param ... Arguments forwarded unchanged to the wrapper.
#'
#' @return A tibble with one row per server and columns `function`,
#'   `environment`, `server_id`, `configured_url`, `observed_urls`,
#'   `status_codes`, `result`, `valid`, and `error`. The observed values and
#'   result are list-columns. A row is `valid` only when the call succeeds,
#'   returns nonempty data, every observed response has status 200, and every
#'   observed URL uses the configured server.
#' @keywords internal
probe_api_function <- function(function_name, ...) {
  if (!is.character(function_name) || length(function_name) != 1L || is.na(function_name) || !nzchar(function_name)) {
    cli::cli_abort("{.arg function_name} must be one non-empty function name.")
  }

  exports <- getNamespaceExports("ComptoxR")
  matches <- exports[tolower(exports) == tolower(function_name)]
  if (length(matches) == 0L) {
    cli::cli_abort("No exported ComptoxR function named {.val {function_name}}.")
  }

  function_name <- matches[[1]]
  family <- if (startsWith(tolower(function_name), "chemi_")) {
    "chemi"
  } else if (startsWith(tolower(function_name), "ct_")) {
    "ct"
  } else {
    cli::cli_abort("{.arg function_name} must name an exported {.code chemi_*} or {.code ct_*} wrapper.")
  }

  if (function_name %in% c("chemi_server", "ct_api_key", "ct_classify")) {
    cli::cli_abort("{.val {function_name}} is not an API wrapper.")
  }

  wrapper <- getExportedValue("ComptoxR", function_name)
  legacy_direct <- function_name %in%
    c(
      "chemi_functional_use",
      "chemi_predict",
      "chemi_safety_section"
    )
  server_ids <- if (family == "chemi") 1:3 else c(1L, 2L, 3L, 5L)
  environments <- if (family == "chemi") {
    c("production", "staging", "development")
  } else {
    c("production", "staging", "development", "legacy staging")
  }
  server_function <- if (family == "chemi") chemi_server else ctx_server
  envvar <- if (family == "chemi") "chemi_burl" else "ctx_burl"
  configured_urls <- vapply(server_ids, server_function, character(1), url_only = TRUE)

  old_url <- Sys.getenv(envvar, unset = NA_character_)
  had_observer <- exists("probe_observer", envir = .ComptoxREnv, inherits = FALSE)
  old_observer <- if (had_observer) .ComptoxREnv$probe_observer else NULL
  on.exit(
    {
      if (is.na(old_url)) {
        Sys.unsetenv(envvar)
      } else {
        do.call(Sys.setenv, stats::setNames(list(old_url), envvar))
      }
      if (had_observer) {
        .ComptoxREnv$probe_observer <- old_observer
      } else if (exists("probe_observer", envir = .ComptoxREnv, inherits = FALSE)) {
        rm("probe_observer", envir = .ComptoxREnv)
      }
    },
    add = TRUE
  )

  observed_urls <- character()
  status_codes <- integer()
  .ComptoxREnv$probe_observer <- function(response) {
    observed_urls <<- c(observed_urls, httr2::resp_url(response))
    status_codes <<- c(status_codes, httr2::resp_status(response))
  }

  purrr::map2_dfr(
    seq_along(server_ids),
    configured_urls,
    function(index, configured_url) {
      observed_urls <<- character()
      status_codes <<- integer()
      do.call(Sys.setenv, stats::setNames(list(configured_url), envvar))

      call_error <- NULL
      result <- tryCatch(
        wrapper(...),
        error = function(error) {
          call_error <<- conditionMessage(error)
          NULL
        }
      )
      if (legacy_direct) {
        observed_urls <<- character()
        status_codes <<- integer()
      }

      nonempty <- if (is.data.frame(result)) nrow(result) > 0L else length(result) > 0L
      configured_base <- sub("/+$", "", configured_url)
      urls_match <- length(observed_urls) == length(status_codes) &&
        length(observed_urls) > 0L &&
        all(observed_urls == configured_base | startsWith(observed_urls, paste0(configured_base, "/")))

      valid <- is.null(call_error) &&
        nonempty &&
        length(status_codes) > 0L &&
        all(status_codes == 200L) &&
        urls_match

      error_message <- call_error
      if (is.null(error_message) && !valid) {
        issues <- c(
          if (!nonempty) "Result is empty.",
          if (length(status_codes) == 0L) "HTTP status not observable.",
          if (length(status_codes) > 0L && any(status_codes != 200L)) "HTTP status was not 200.",
          if (length(status_codes) > 0L && !urls_match) "Observed URL does not match configured server."
        )
        error_message <- paste(issues, collapse = " ")
      }

      tibble::tibble(
        `function` = function_name,
        environment = environments[[index]],
        server_id = server_ids[[index]],
        configured_url = configured_url,
        observed_urls = list(observed_urls),
        status_codes = list(status_codes),
        result = list(result),
        valid = valid,
        error = if (is.null(error_message)) NA_character_ else error_message
      )
    }
  )
}

# Notify an active probe without changing ordinary request behavior.
#' @noRd
observe_api_responses <- function(responses) {
  observer <- .ComptoxREnv$probe_observer
  if (!is.function(observer)) {
    return(invisible(NULL))
  }

  for (response in responses) {
    if (inherits(response, "httr2_error")) {
      response <- response$resp
    }
    if (inherits(response, "httr2_response")) {
      tryCatch(observer(response), error = function(error) NULL)
    }
  }
  invisible(NULL)
}
