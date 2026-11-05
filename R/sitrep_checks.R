# Paths are relative to the configured API base, never URLs supplied by discovery.
.sitrep_probes <- function() {
  unlist(
    jsonlite::read_json(system.file(
      "diagnostics",
      "chemi-probes.json",
      package = "ComptoxR"
    )),
    use.names = TRUE
  )
}

.sitrep_request <- function(url, path) {
  target <- if (nzchar(path)) paste0(sub("/+$", "", url), "/", path) else url
  httr2::request(target) %>%
    httr2::req_timeout(5) %>%
    httr2::req_error(is_error = function(resp) FALSE)
}

.sitrep_probe <- function(url, paths) {
  start <- Sys.time()
  requests <- lapply(paths, function(path) .sitrep_request(url, path))
  responses <- tryCatch(
    httr2::req_perform_parallel(requests, on_error = "continue", progress = FALSE),
    error = function(e) rep(list(NULL), length(paths))
  )
  latency <- as.numeric(difftime(Sys.time(), start, units = "secs"))
  rows <- lapply(seq_along(paths), function(i) {
    response <- responses[[i]]
    code <- if (inherits(response, "httr2_response")) httr2::resp_status(response) else NA_integer_
    status <- if (is.na(code)) {
      "ERROR"
    } else if (code %in% c(401L, 403L)) {
      "UNKNOWN"
    } else if (code >= 200 && code < 400) {
      "OK"
    } else {
      "WARNING"
    }
    message <- if (is.na(code)) "Connection, TLS, or timeout failure" else paste0("HTTP ", code)
    if (code %in% c(401L, 403L)) {
      message <- paste0(message, "; authentication required, availability unverified")
    }
    tibble::tibble(
      name = names(paths)[i],
      path = unname(paths[i]),
      status = status,
      message = message,
      http_status = code
    )
  })
  list(endpoints = dplyr::bind_rows(rows), latency = latency)
}

.sitrep_summary <- function(name, checked, endpoint_list = NULL, source = "shipped") {
  endpoints <- checked$endpoints
  up <- sum(endpoints$status == "OK")
  total <- nrow(endpoints)
  status <- if (up == total && total > 0) {
    "OK"
  } else if (all(endpoints$status == "UNKNOWN")) {
    "UNKNOWN"
  } else if (up > 0) {
    "WARNING"
  } else {
    "ERROR"
  }
  message <- sprintf("%d/%d endpoints active", up, total)
  if (!is.null(endpoint_list) && endpoint_list$status != "OK") {
    if (status %in% c("OK", "UNKNOWN")) {
      status <- "WARNING"
    }
    message <- paste0(
      "Endpoint list unavailable (",
      endpoint_list$message,
      "); ",
      message,
      " using ",
      source,
      " probes"
    )
  }
  list(
    name = name,
    status = status,
    message = message,
    latency = checked$latency,
    endpoint_list = endpoint_list,
    source = source,
    endpoints = endpoints
  )
}

.sitrep_chemi <- function(url) {
  start <- Sys.time()
  discovery <- tryCatch(
    {
      resp <- tryCatch(
        httr2::req_perform(.sitrep_request(url, "services/cim_component_info")),
        error = function(e) stop("Connection, TLS, or timeout failure", call. = FALSE)
      )
      code <- httr2::resp_status(resp)
      if (code < 200 || code >= 400) {
        stop(paste0("HTTP ", code), call. = FALSE)
      }
      entries <- tryCatch(httr2::resp_body_json(resp), error = function(e) {
        stop("Invalid JSON endpoint list", call. = FALSE)
      })
      if (!is.list(entries) || !length(entries)) {
        stop("Empty or invalid endpoint list")
      }
      valid <- vapply(
        entries,
        function(x) {
          is.list(x) &&
            is.character(x$name) &&
            length(x$name) == 1L &&
            !is.na(x$name) &&
            grepl("^[A-Za-z0-9_-]+$", x$name) &&
            is.logical(x$is_available) &&
            length(x$is_available) == 1L &&
            !is.na(x$is_available)
        },
        logical(1)
      )
      if (!any(valid)) {
        stop("No named endpoints with availability in endpoint list")
      }
      entries <- entries[valid]
      nms <- vapply(entries, `[[`, character(1), "name")
      available <- vapply(entries, `[[`, logical(1), "is_available")
      list(status = "OK", message = paste0("HTTP ", code), available = stats::setNames(available, nms))
    },
    error = function(e) {
      # Keep HTTP status and parsing failures, never raw transport errors with URLs.
      msg <- conditionMessage(e)
      list(
        status = "ERROR",
        message = if (
          grepl("^HTTP [0-9]{3}$", msg) ||
            msg %in%
              c(
                "Connection, TLS, or timeout failure",
                "Invalid JSON endpoint list",
                "Empty or invalid endpoint list",
                "No named endpoints with availability in endpoint list"
              )
        ) {
          msg
        } else {
          "Invalid endpoint list"
        }
      )
    }
  )
  shipped <- .sitrep_probes()
  cache <- .ComptoxREnv$sitrep_endpoints
  key <- sub("/+$", "", url)
  if (discovery$status == "OK") {
    nms <- names(discovery$available)
    .ComptoxREnv$sitrep_endpoints[[key]] <- unique(nms)
    source <- "live"
  } else if (length(cache[[key]])) {
    nms <- cache[[key]]
    source <- "last-known"
  } else {
    nms <- names(shipped)
    source <- "shipped"
  }
  paths <- shipped[intersect(nms, names(shipped))]
  checked <- .sitrep_probe(url, paths)
  unknown <- setdiff(nms, names(shipped))
  if (length(unknown)) {
    checked$endpoints <- dplyr::bind_rows(
      checked$endpoints,
      tibble::tibble(
        name = unknown,
        path = NA_character_,
        status = "UNKNOWN",
        message = "No shipped probe; availability unverified",
        http_status = NA_integer_
      )
    )
  }
  # A successful probe does not erase a component's reported outage.
  reported_down <- if (is.null(discovery$available)) {
    character()
  } else {
    names(discovery$available)[!discovery$available]
  }
  for (name in reported_down) {
    i <- match(name, checked$endpoints$name)
    if (checked$endpoints$status[i] %in% c("OK", "UNKNOWN")) {
      checked$endpoints$status[i] <- "WARNING"
    }
    checked$endpoints$message[i] <- paste0("Reported unavailable; ", checked$endpoints$message[i])
  }
  discovery$available <- NULL
  discovery$path <- "services/cim_component_info"
  checked$latency <- as.numeric(difftime(Sys.time(), start, units = "secs"))
  .sitrep_summary("Cheminformatics API", checked, discovery, source)
}

# Shared by the startup summary and the full diagnostic report.
.sitrep_checks <- function() {
  ping_results <- list()
  probes <- list(
    "CompTox Dashboard API" = list(
      key = "ctx_burl",
      paths = c(
        chemical = "chemical/health",
        hazard = "hazard/health",
        exposure = "exposure/health",
        bioactivity = "bioactivity/health"
      )
    ),
    "EPI Suite API" = list(
      key = "epi_burl",
      paths = c(
        specification = "",
        search = "search?query=benzene&limit=1"
      )
    ),
    "PubChem PUG REST" = list(
      key = "pubchem_burl",
      paths = c(
        molecular_formula = "compound/cid/2244/property/MolecularFormula/JSON"
      )
    ),
    "ECOTOX" = list(key = "eco_burl", paths = c(health = "health-check")),
    "ToxValDB" = list(key = "toxval_burl", paths = c(health = "health-check"))
  )
  for (name in names(probes)) {
    probe <- probes[[name]]
    url <- .endpoint_target(probe$key)
    # Local database files are described below rather than sent to HTTP.
    if (!grepl("^https?://", url, ignore.case = TRUE)) {
      next
    }
    checked <- .sitrep_probe(url, probe$paths)
    endpoint_list <- if (probe$key == "epi_burl") {
      as.list(checked$endpoints[1, c("status", "message", "path")])
    } else {
      NULL
    }
    ping_results[[name]] <- .sitrep_summary(name, checked, endpoint_list)
  }
  ping_results[["Cheminformatics API"]] <- .sitrep_chemi(.endpoint_target("chemi_burl"))

  ping_results
}
