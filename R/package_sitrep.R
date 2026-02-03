#' Package Situation Report (Diagnostics)
#'
#' Creates a diagnostic log file with useful troubleshooting information including
#' package version, API token status, server paths, and ping test results.
#' The output is saved to a timestamped .log file in the working directory and
#' also displayed in the console.
#'
#' @return Invisibly returns a list with diagnostic information. Also writes
#'   a timestamped .log file to the current working directory and displays
#'   information to the console.
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate diagnostic report
#' package_sitrep()
#' }
package_sitrep <- function() {
  # Generate timestamp for log file
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  log_filename <- paste0("comptoxr_sitrep_", timestamp, ".log")
  
  # Initialize log content
  log_lines <- character()
  
  # Helper function to add lines to log
  add_log <- function(...) {
    log_lines <<- c(log_lines, paste0(..., collapse = ""))
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
  pkg_date <- tryCatch({
    date <- utils::packageDate('ComptoxR')
    if (is.na(date)) {
      "Development/Nightly Build"
    } else {
      as.character(date)
    }
  }, error = function(e) "Unknown")
  
  add_log("Version: ", pkg_version)
  add_log("Build Date: ", pkg_date)
  add_log("")
  
  # API Tokens Status
  add_log("API TOKENS STATUS")
  add_log(paste0(rep("-", 70), collapse = ""))
  
  ctx_api_key <- Sys.getenv("ctx_api_key")
  ctx_key_set <- nzchar(ctx_api_key) && !is.na(ctx_api_key)
  add_log("CompTox API Key: ", if (ctx_key_set) "SET" else "NOT SET")
  
  cc_api_key <- Sys.getenv("cc_api_key")
  cc_key_set <- nzchar(cc_api_key) && !is.na(cc_api_key)
  add_log("Common Chemistry API Key: ", if (cc_key_set) "SET" else "NOT SET")
  add_log("")
  
  # Server Paths
  add_log("CONFIGURED SERVER PATHS")
  add_log(paste0(rep("-", 70), collapse = ""))
  
  servers <- list(
    "CompTox Dashboard API" = "ctx_burl",
    "Cheminformatics API" = "chemi_burl",
    "ECOTOX API" = "eco_burl",
    "EPI Suite API" = "epi_burl",
    "Natural Products API" = "np_burl",
    "Common Chemistry API" = "cc_burl"
  )
  
  server_paths <- list()
  for (name in names(servers)) {
    env_var <- servers[[name]]
    path <- Sys.getenv(env_var)
    server_paths[[name]] <- path
    add_log(sprintf("%-30s: %s", name, if (nzchar(path)) path else "NOT CONFIGURED"))
  }
  add_log("")
  
  # Ping Test Results
  add_log("PING TEST RESULTS")
  add_log(paste0(rep("-", 70), collapse = ""))
  
  # Define ping endpoints
  ping_endpoints <- list(
    "CompTox Dashboard API" = list(
      url = Sys.getenv("ctx_burl"),
      ping_path = "chemical/health"
    ),
    "ECOTOX" = list(
      url = Sys.getenv("eco_burl"),
      ping_path = ""
    ),
    "EPI Suite API" = list(
      url = Sys.getenv("epi_burl"),
      ping_path = ""
    ),
    "Common Chemistry API" = list(
      url = Sys.getenv("cc_burl"),
      ping_path = ""
    )
  )
  
  # Helper function to ping a URL
  ping_server <- function(name, url, ping_path = "") {
    if (!nzchar(url) || is.na(url)) {
      return(list(
        name = name,
        status = "SKIPPED",
        message = "Not configured",
        latency = NA_real_
      ))
    }
    
    # Construct full ping URL
    full_url <- if (nzchar(ping_path)) {
      paste0(url, ping_path)
    } else {
      url
    }
    
    tryCatch({
      # Use HEAD request for efficiency
      req <- httr2::request(full_url) %>%
        httr2::req_method("HEAD") %>%
        httr2::req_timeout(5) %>%
        httr2::req_error(is_error = function(resp) FALSE)
      
      start_time <- Sys.time()
      resp <- httr2::req_perform(req)
      end_time <- Sys.time()
      
      latency <- as.numeric(difftime(end_time, start_time, units = "secs"))
      status_code <- httr2::resp_status(resp)
      
      if (status_code >= 200 && status_code < 400) {
        list(
          name = name,
          status = "OK",
          message = paste0("HTTP ", status_code),
          latency = latency
        )
      } else {
        list(
          name = name,
          status = "WARNING",
          message = paste0("HTTP ", status_code),
          latency = latency
        )
      }
    }, error = function(e) {
      error_msg <- if (inherits(e, "httr2_timeout")) {
        "Request timed out"
      } else if (inherits(e, "httr2_connect_error")) {
        "Connection failed"
      } else {
        "Request failed"
      }
      list(
        name = name,
        status = "ERROR",
        message = error_msg,
        latency = NA_real_
      )
    })
  }
  
  # Perform ping tests
  ping_results <- list()
  for (name in names(ping_endpoints)) {
    endpoint <- ping_endpoints[[name]]
    result <- ping_server(name, endpoint$url, endpoint$ping_path)
    ping_results[[name]] <- result
    
    latency_str <- if (is.finite(result$latency)) {
      sprintf("%.0fms", result$latency * 1000)
    } else {
      ""
    }
    
    add_log(sprintf("%-30s: %-10s %-30s %s", 
                    name, 
                    result$status, 
                    result$message,
                    latency_str))
  }
  
  # Check Cheminformatics endpoints separately
  chemi_result <- tryCatch({
    chemi_url <- Sys.getenv('chemi_burl')
    if (nzchar(chemi_url)) {
      start_time <- Sys.time()
      resp <- httr2::request(paste0(chemi_url, "/services/cim_component_info")) %>%
        httr2::req_timeout(5) %>%
        httr2::req_error(is_error = function(resp) FALSE) %>%
        httr2::req_perform()
      end_time <- Sys.time()
      
      latency <- as.numeric(difftime(end_time, start_time, units = "secs"))
      
      endpoints <- resp %>%
        httr2::resp_body_json() %>%
        purrr::map(~ tibble::as_tibble(.x)) %>%
        purrr::list_rbind() %>%
        dplyr::filter(!is.na(is_available))
      
      active <- sum(endpoints$is_available, na.rm = TRUE)
      total <- nrow(endpoints)
      
      list(
        name = "Cheminformatics API",
        status = "OK",
        message = sprintf("%d/%d endpoints active", active, total),
        latency = latency
      )
    } else {
      list(
        name = "Cheminformatics API",
        status = "SKIPPED",
        message = "Not configured",
        latency = NA_real_
      )
    }
  }, error = function(e) {
    list(
      name = "Cheminformatics API",
      status = "ERROR",
      message = "Failed to get endpoints",
      latency = NA_real_
    )
  })
  
  ping_results[["Cheminformatics API"]] <- chemi_result
  
  latency_str <- if (is.finite(chemi_result$latency)) {
    sprintf("%.0fms", chemi_result$latency * 1000)
  } else {
    ""
  }
  
  add_log(sprintf("%-30s: %-10s %-30s %s", 
                  chemi_result$name, 
                  chemi_result$status, 
                  chemi_result$message,
                  latency_str))
  add_log("")
  
  # Local Fallback Implementation (Future Development)
  add_log("LOCAL FALLBACK IMPLEMENTATION")
  add_log(paste0(rep("-", 70), collapse = ""))
  add_log("Status: Not yet implemented (future development)")
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
  if (cc_key_set) {
    cli::cli_li("{.strong Common Chemistry API Key}: {cli::col_green('SET')}")
  } else {
    cli::cli_li("{.strong Common Chemistry API Key}: {cli::col_red('NOT SET')}")
  }
  cli::cli_end()
  
  cli::cli_h2("Server Status")
  for (name in names(ping_results)) {
    result <- ping_results[[name]]
    status_color <- switch(result$status,
                          "OK" = cli::col_green(result$status),
                          "WARNING" = cli::col_yellow(result$status),
                          "ERROR" = cli::col_red(result$status),
                          "SKIPPED" = cli::col_grey(result$status),
                          result$status)
    
    latency_display <- if (is.finite(result$latency)) {
      sprintf("[%dms]", round(result$latency * 1000))
    } else {
      ""
    }
    
    cli::cli_alert_info("{.strong {name}}: {status_color} - {result$message} {latency_display}")
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
      ctx_api_key = ctx_key_set,
      cc_api_key = cc_key_set
    ),
    server_paths = server_paths,
    ping_results = ping_results,
    local_fallback = "Not yet implemented"
  ))
}
