#!/usr/bin/env Rscript

probe_response <- function(ok, body = NULL, status = NA_integer_, error = NA_character_) {
  list(ok = ok, body = body, status = status, error = error)
}

probe_http <- function(base_url, path, method = "GET", query = list(), body = NULL, api_key = NULL) {
  tryCatch(
    {
      request <- httr2::request(base_url) |>
        httr2::req_url_path_append(path) |>
        httr2::req_method(method) |>
        httr2::req_timeout(60) |>
        httr2::req_error(is_error = \(response) FALSE)
      if (length(query) > 0) {
        request <- do.call(httr2::req_url_query, c(list(request), query))
      }
      if (!is.null(body)) {
        request <- httr2::req_body_json(request, body)
      }
      if (!is.null(api_key)) {
        request <- httr2::req_headers(request, `x-api-key` = api_key)
      }
      response <- httr2::req_perform(request)
      status <- httr2::resp_status(response)
      parsed <- tryCatch(
        httr2::resp_body_json(response, simplifyVector = FALSE),
        error = function(error) NULL
      )
      probe_response(status >= 200L && status < 300L, parsed, status)
    },
    error = function(error) probe_response(FALSE, error = conditionMessage(error))
  )
}

probe_body <- function(response) {
  body <- response$body
  if (
    is.list(body) &&
      length(body) == 1L &&
      is.list(body[[1]]) &&
      !is.null(names(body[[1]]))
  ) {
    body[[1]]
  } else {
    body
  }
}

probe_descriptor_counts <- function(response) {
  body <- probe_body(response)
  records <- body$chemicals %||% list()
  headers <- unlist(body$headers %||% character(), use.names = FALSE)
  values <- if (length(records) == 0L) {
    integer()
  } else {
    vapply(records, function(record) length(record$descriptors %||% list()), integer(1))
  }
  list(headers = length(headers), values = values)
}

probe_find_values <- function(value, names) {
  found <- list()
  visit <- function(node) {
    if (!is.list(node)) {
      return(invisible(NULL))
    }
    for (name in intersect(names, base::names(node) %||% character())) {
      found[[name]] <<- node[[name]]
    }
    for (item in node) {
      visit(item)
    }
    invisible(NULL)
  }
  visit(value)
  found
}

evaluate_probe <- function(kind, value, expected = NULL) {
  fail <- function(detail) list(pass = FALSE, detail = detail)
  pass <- function(detail = "contract satisfied") list(pass = TRUE, detail = detail)

  if (kind == "http") {
    return(if (isTRUE(value$ok)) pass() else fail("request failed"))
  }
  if (kind == "descriptor") {
    if (!isTRUE(value$ok)) {
      return(fail("request failed"))
    }
    counts <- probe_descriptor_counts(value)
    if (!identical(counts$headers, as.integer(expected))) {
      return(fail(sprintf("expected %d headers; received %d", expected, counts$headers)))
    }
    if (length(counts$values) == 0L || any(counts$values != expected)) {
      return(fail(sprintf("descriptor values are not aligned to %d headers", expected)))
    }
    return(pass(sprintf("%d aligned descriptors", expected)))
  }
  if (kind == "metadata") {
    if (!isTRUE(value$ok)) {
      return(fail("request failed"))
    }
    descriptors <- probe_body(value)$descriptors %||% list()
    advertised <- tolower(vapply(descriptors, function(item) as.character(item$name %||% ""), character(1)))
    missing <- setdiff(tolower(expected), advertised)
    return(if (length(missing) == 0L) pass("required engines advertised") else fail("required engines missing"))
  }
  if (kind == "formaldehyde") {
    if (!isTRUE(value$ok)) {
      return(fail("request failed"))
    }
    smiles <- probe_find_values(value$body, c("msReadySmiles", "qsarReadySmiles"))
    return(
      if (
        identical(as.character(smiles$msReadySmiles %||% ""), "C=O") &&
          identical(as.character(smiles$qsarReadySmiles %||% ""), "C=O")
      ) {
        pass("MS-ready and QSAR-ready SMILES are C=O")
      } else {
        fail("formaldehyde SMILES are not both C=O")
      }
    )
  }
  if (kind == "wrapper_rdkit") {
    required <- c("query", "input_index", "status", "error", "source_server", "source_endpoint", "fallback_used")
    if (!is.data.frame(value) || !all(required %in% names(value))) {
      return(fail("wrapper result is missing contract columns"))
    }
    if (!identical(value$input_index, seq_len(nrow(value))) || !identical(value$query, expected)) {
      return(fail("wrapper did not preserve inputs and positions"))
    }
    descriptor_columns <- setdiff(
      names(value),
      c(
        "query",
        "input_index",
        "status",
        "error",
        "smiles",
        "inchi",
        "inchi_key",
        "source_server",
        "source_endpoint",
        "fallback_used"
      )
    )
    return(
      if (length(descriptor_columns) == 1024L) {
        pass("1,024-bit RDKit wrapper contract")
      } else {
        fail("RDKit wrapper did not return 1,024 bits")
      }
    )
  }
  if (kind == "wrapper_webtest") {
    required <- c("query", "input_index", "status", "endpoint_id", "method", "source_server", "source_endpoint")
    if (!is.data.frame(value) || !all(required %in% names(value))) {
      return(fail("wrapper result is missing contract columns"))
    }
    if (!all(seq_along(expected) %in% value$input_index) || !identical(unique(value$query), unique(expected))) {
      return(fail("wrapper did not preserve all inputs"))
    }
    successful <- value$status == "ok"
    return(
      if (
        any(successful) &&
          all(value$endpoint_id[successful] == "LC50") &&
          all(value$method[successful] == "consensus")
      ) {
        pass("LC50 consensus filtering preserved")
      } else {
        fail("WebTEST filtering drifted")
      }
    )
  }
  stop("Unknown probe evaluator kind.", call. = FALSE)
}

probe_sanitize <- function(text) {
  text <- gsub("https?://[^[:space:]]+", "[redacted-url]", text)
  gsub("[\r\n]+", " ", text)
}

probe_case <- function(environment, surface, check, kind, value, expected = NULL, known_issue = FALSE) {
  evaluated <- evaluate_probe(kind, value, expected)
  data.frame(
    environment = environment,
    surface = surface,
    check = check,
    status = if (evaluated$pass) {
      "pass"
    } else if (known_issue) {
      "known_defect"
    } else {
      "fail"
    },
    detail = probe_sanitize(evaluated$detail),
    stringsAsFactors = FALSE
  )
}

run_compatibility_probe <- function() {
  pkgload::load_all(".", quiet = TRUE)
  key <- Sys.getenv("CTX_API_KEY", unset = "")
  if (!nzchar(key)) {
    stop("CTX_API_KEY repository secret is required for the production formaldehyde probe.", call. = FALSE)
  }

  previous_server <- Sys.getenv("chemi_burl", unset = NA_character_)
  on.exit(
    {
      if (is.na(previous_server)) {
        Sys.unsetenv("chemi_burl")
      } else {
        Sys.setenv(chemi_burl = previous_server)
      }
    },
    add = TRUE
  )
  labels <- c("production", "staging", "development")
  urls <- vapply(1:3, chemi_server, character(1), url_only = TRUE)
  inputs <- c("CCO", "DTXSID7020182", "DTXSID000000000")
  results <- list()
  add <- function(...) results[[length(results) + 1L]] <<- probe_case(...)

  for (index in seq_along(labels)) {
    label <- labels[[index]]
    url <- urls[[index]]
    direct <- list(
      metadata = probe_http(url, "descriptors/metadata"),
      rdkit_get = probe_http(
        url,
        "descriptors",
        query = list(
          smiles = "CCO",
          type = "rdkit",
          headers = TRUE,
          format = "JSON"
        )
      ),
      rdkit_post = probe_http(
        url,
        "descriptors",
        "POST",
        body = list(
          chemicals = I("CCO"),
          chemIdType = "SMILES",
          format = "JSON",
          options = list(headers = TRUE, type = "ecfp", radius = 3L, bits = 1024L),
          type = "rdkit"
        )
      ),
      mordred_version = probe_http(url, "mordred/version"),
      mordred_metadata = probe_http(url, "mordred/metadata"),
      mordred_get = probe_http(url, "mordred", query = list(smiles = "CCO", headers = TRUE, inchi = TRUE)),
      mordred_post = probe_http(
        url,
        "mordred",
        "POST",
        body = list(
          chemicals = I("CCO"),
          options = list(headers = TRUE, inchi = TRUE)
        )
      )
    )
    add(label, "direct", "aggregate metadata", "metadata", direct$metadata, c("rdkit", "mordred"), TRUE)
    add(label, "direct", "aggregate RDKit GET", "descriptor", direct$rdkit_get, 1024L, TRUE)
    add(label, "direct", "aggregate RDKit POST", "descriptor", direct$rdkit_post, 1024L, TRUE)
    add(label, "direct", "dedicated Mordred version", "http", direct$mordred_version, known_issue = TRUE)
    add(label, "direct", "dedicated Mordred metadata", "http", direct$mordred_metadata, known_issue = TRUE)
    add(label, "direct", "dedicated Mordred GET", "descriptor", direct$mordred_get, 1613L, TRUE)
    add(label, "direct", "dedicated Mordred POST", "descriptor", direct$mordred_post, 1613L, TRUE)

    wrapper_results <- withr::with_envvar(
      c(chemi_burl = url),
      list(
        rdkit = tryCatch(
          suppressWarnings(chemi_descriptors_bulk(inputs, type = "rdkit")),
          error = identity
        ),
        webtest = tryCatch(
          suppressWarnings(chemi_webtest_predict_bulk(
            inputs,
            endpoints = "LC50",
            methods = "consensus"
          )),
          error = identity
        )
      )
    )
    add(
      label,
      "wrapper",
      "RDKit input/header/provenance contract",
      "wrapper_rdkit",
      wrapper_results$rdkit,
      inputs
    )
    add(
      label,
      "wrapper",
      "WebTEST input/filter/provenance contract",
      "wrapper_webtest",
      wrapper_results$webtest,
      inputs
    )
  }

  ctx <- probe_http(
    ctx_server(1, url_only = TRUE),
    "chemical/detail/search/by-dtxsid/50-00-0",
    query = list(projection = "chemicaldetailall"),
    api_key = key
  )
  add("production", "direct", "formaldehyde detail SMILES", "formaldehyde", ctx, known_issue = TRUE)
  do.call(rbind, results)
}

write_probe_outputs <- function(results, artifact = "artifacts/api-compatibility-probe.csv") {
  dir.create(dirname(artifact), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(results, artifact, row.names = FALSE, na = "")
  summary_path <- Sys.getenv("GITHUB_STEP_SUMMARY", unset = "")
  if (nzchar(summary_path)) {
    lines <- c(
      "## API compatibility probe",
      "",
      "| Environment | Surface | Check | Status |",
      "|---|---|---|---|",
      sprintf(
        "| %s | %s | %s | %s |",
        results$environment,
        results$surface,
        results$check,
        results$status
      )
    )
    writeLines(lines, summary_path)
  }
  invisible(results)
}

probe_is_entrypoint <- function() {
  file_args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  length(file_args) > 0L &&
    identical(basename(sub("^--file=", "", tail(file_args, 1L))), "probe_api_compatibility.R")
}

if (probe_is_entrypoint()) {
  results <- tryCatch(
    run_compatibility_probe(),
    error = function(error) {
      data.frame(
        environment = "production",
        surface = "configuration",
        check = "CTX_API_KEY availability",
        status = "fail",
        detail = probe_sanitize(conditionMessage(error)),
        stringsAsFactors = FALSE
      )
    }
  )
  write_probe_outputs(results)
  if (any(results$surface %in% c("wrapper", "configuration") & results$status == "fail")) {
    quit(save = "no", status = 1L)
  }
}
