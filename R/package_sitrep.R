#' Package Situation Report (Diagnostics)
#'
#' Creates a diagnostic log file with useful troubleshooting information including
#' package version, API token status, server paths, and ping test results.
#' The output is saved to a timestamped .log file in the working directory and
#' also displayed in the console.
#'
#' @details
#' The Cheminformatics endpoint list and individual components are checked
#' separately. If the list is unavailable, checks use the last valid component
#' names seen for that server in this R session, or the shipped probe list.
#' The shipped list contains lightweight GET routes from the package schemas.
#' Cached availability is never treated as a current health result. Components
#' without a shipped probe are reported as unverified.
#'
#' CTX domains and the other configured HTTP services receive named checks too.
#' EPI checks its specification separately from a lightweight search, so a failed
#' specification does not prevent checking the shipped search route.
#' Local ECOTOX and ToxValDB files are reported under local databases; HTTP
#' deployments use their health-check route. An HTTP 401 or 403 is reported as
#' unverified rather than an outage. A successful health, version, or root check
#' establishes reachability of that route, not every operation in the service.
#' Checks use a five-second timeout and run component probes concurrently.
#'
#' Console and log output identify each checked endpoint and its result.
#' Each entry in `ping_results` includes an `endpoints` tibble with name, path,
#' status, message, and HTTP status. Cheminformatics additionally includes
#' `endpoint_list` and `source` (`live`, `last-known`, or `shipped`).
#'
#' @return Invisibly returns a list with diagnostic information. Also writes
#'   a timestamped .log file to the current working directory and displays
#'   information to the console.
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate diagnostic report
#' ComptoxR_package_sitrep()
#' }
ComptoxR_package_sitrep <- function() {
  # Generate timestamp for log file
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  log_filename <- paste0("comptoxr_sitrep_", timestamp, ".log")

  # Initialize log content
  log_lines <- character()

  # Helper function to add lines to log
  add_log <- function(...) {
    log_lines <<- c(log_lines, .diagnostic_endpoint(paste0(..., collapse = "")))
  }

  # Header
  add_log(paste0(rep("=", 70), collapse = ""))
  add_log("ComptoxR Package Situation Report")
  add_log("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  add_log(paste0(rep("=", 70), collapse = ""))
  add_log("")

  # Package Version
  add_log("PACKAGE VERSION")
  add_log(paste0(rep("-", 70), collapse = ""))
  pkg_version <- tryCatch(
    as.character(utils::packageVersion('ComptoxR')),
    error = function(e) "Unknown"
  )
  pkg_date <- tryCatch(
    {
      date <- utils::packageDate('ComptoxR')
      if (is.na(date)) {
        "Development/Nightly Build"
      } else {
        as.character(date)
      }
    },
    error = function(e) "Unknown"
  )

  add_log("Version: ", pkg_version)
  add_log("Build Date: ", pkg_date)
  add_log("")

  # API Tokens Status
  add_log("API TOKENS STATUS")
  add_log(paste0(rep("-", 70), collapse = ""))

  ctx_api_key <- Sys.getenv("ctx_api_key")
  ctx_key_set <- nzchar(ctx_api_key) && !is.na(ctx_api_key)
  add_log("CompTox API Key: ", if (ctx_key_set) "SET" else "NOT SET")

  add_log("")

  # Server Paths
  add_log("CONFIGURED SERVER PATHS")
  add_log(paste0(rep("-", 70), collapse = ""))

  servers <- list(
    "CompTox Dashboard API" = "ctx_burl",
    "Cheminformatics API" = "chemi_burl",
    "ECOTOX API" = "eco_burl",
    "ToxValDB" = "toxval_burl",
    "EPI Suite API" = "epi_burl",
    "Natural Products API" = "np_burl",
    "PubChem PUG REST" = "pubchem_burl"
  )

  server_paths <- list()
  for (name in names(servers)) {
    env_var <- servers[[name]]
    path <- .endpoint_target(env_var)
    server_paths[[name]] <- .diagnostic_endpoint(path)
    add_log(sprintf("%-30s: %s", name, .diagnostic_endpoint(path)))
  }
  add_log("")

  # Ping Test Results
  add_log("PING TEST RESULTS")
  add_log(paste0(rep("-", 70), collapse = ""))

  ping_results <- .sitrep_checks()

  for (name in names(ping_results)) {
    result <- ping_results[[name]]
    add_log(sprintf("%-30s: %-10s %s %.0fms", name, result$status, result$message, result$latency * 1000))
    if (!is.null(result$endpoint_list)) {
      add_log(
        "  Endpoint list: ",
        result$endpoint_list$status,
        " ",
        result$endpoint_list$message,
        " [",
        result$endpoint_list$path,
        "]"
      )
    }
    for (i in seq_len(nrow(result$endpoints))) {
      endpoint <- result$endpoints[i, ]
      add_log("  ", endpoint$name, ": ", endpoint$status, " ", endpoint$message, " [", endpoint$path, "]")
    }
  }
  add_log("")

  # Local Database Status
  add_log("LOCAL DATABASES")
  add_log(paste0(rep("-", 70), collapse = ""))

  local_dbs <- list(
    list(label = "DSSTox", path = dss_path()),
    list(label = "ECOTOX", path = eco_path()),
    list(label = "ToxValDB", path = toxval_path())
  )

  local_db_status <- list()
  for (db in local_dbs) {
    installed <- file.exists(db$path)
    size_str <- if (installed) {
      sz_mb <- file.size(db$path) / 1024^2
      sprintf("%.1f MB", sz_mb)
    } else {
      "not installed"
    }
    local_db_status[[db$label]] <- list(
      path = db$path,
      installed = installed,
      size_str = size_str
    )
    add_log(sprintf("%-30s: %-15s %s", db$label, size_str, db$path))
  }
  add_log("")

  # Footer
  add_log(paste0(rep("=", 70), collapse = ""))
  add_log("End of Report")
  add_log(paste0(rep("=", 70), collapse = ""))

  # Write to log file
  writeLines(log_lines, log_filename)

  # Display to console
  cli::cli_rule(left = "ComptoxR Package Situation Report")
  cli::cli_alert_info(sprintf("Report generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
  cli::cli_alert_info(sprintf("Log file saved: {.file %s}", log_filename))
  cli::cli_text("")

  # Display key information to console
  cli::cli_h2("Package Information")
  cli::cli_dl(c(
    "Version" = pkg_version,
    "Build Date" = pkg_date
  ))

  cli::cli_h2("API Tokens")
  cli::cli_ul()
  if (ctx_key_set) {
    cli::cli_li("{.strong CompTox API Key}: {cli::col_green('SET')}")
  } else {
    cli::cli_li("{.strong CompTox API Key}: {cli::col_red('NOT SET')}")
  }
  cli::cli_end()

  cli::cli_h2("Server Status")
  for (name in names(ping_results)) {
    result <- ping_results[[name]]
    status_color <- switch(
      result$status,
      "OK" = cli::col_green(result$status),
      "WARNING" = cli::col_yellow(result$status),
      "ERROR" = cli::col_red(result$status),
      "SKIPPED" = cli::col_grey(result$status),
      "UNKNOWN" = cli::col_yellow(result$status),
      result$status
    )

    latency_display <- if (is.finite(result$latency)) {
      sprintf("[%dms]", round(result$latency * 1000))
    } else {
      ""
    }

    cli::cli_alert_info("{.strong {name}}: {status_color} - {result$message} {latency_display}")
    if (!is.null(result$endpoint_list)) {
      cli::cli_text("  Endpoint list: {result$endpoint_list$status} - {result$endpoint_list$message}")
    }
    for (i in seq_len(nrow(result$endpoints))) {
      endpoint <- result$endpoints[i, ]
      cli::cli_text("  {endpoint$name}: {endpoint$status} - {endpoint$message} [{endpoint$path}]")
    }
  }

  cli::cli_h2("Local Databases")
  for (label in names(local_db_status)) {
    db_info <- local_db_status[[label]]
    if (db_info$installed) {
      cli::cli_alert_success("{.strong {label}}: {.path {db_info$path}} ({db_info$size_str})")
    } else {
      cli::cli_alert_warning("{.strong {label}}: not installed")
    }
  }

  cli::cli_rule()
  cli::cli_alert_success("Full diagnostic report saved to: {.file {log_filename}}")

  # Return diagnostic data invisibly
  invisible(list(
    timestamp = Sys.time(),
    log_file = log_filename,
    package_version = pkg_version,
    package_date = pkg_date,
    api_tokens = list(
      ctx_api_key = ctx_key_set
    ),
    server_paths = server_paths,
    ping_results = ping_results,
    local_databases = list(
      dsstox = list(path = dss_path(), installed = file.exists(dss_path())),
      ecotox = list(path = eco_path(), installed = file.exists(eco_path())),
      toxvaldb = list(path = toxval_path(), installed = file.exists(toxval_path()))
    )
  ))
}
