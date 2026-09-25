#!/usr/bin/env Rscript
# Installed-client transport comparison. All service URLs are localhost.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
libs <- normalizePath(args[1:2], mustWork = TRUE)
dir.create(args[[3]], recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(args[[3]])

# Independent transport expectations for the second lookup tranche.
lookup_cases <- list(
  chemi_alerts_alerts = list(path = "/chemi/alerts/alerts"),
  chemi_alerts_operations = list(path = "/chemi/alerts/operations"),
  chemi_amos_release_notes = list(path = "/chemi/amos/release_notes"),
  chemi_amos_get_data_source_info = list(path = "/chemi/amos/get_data_source_info/"),
  chemi_amos_get_ir_spectrum = list(path = "/chemi/amos/get_ir_spectrum/", parameter = "internal_id"),
  chemi_amos_get_nmr_spectrum = list(path = "/chemi/amos/get_nmr_spectrum/", parameter = "internal_id"),
  chemi_amos_get_mass_spectrum = list(path = "/chemi/amos/get_mass_spectrum/", parameter = "internal_id"),
  chemi_amos_get_info_by_id = list(path = "/chemi/amos/get_info_by_id/", parameter = "internal_id"),
  chemi_amos_get_classification_for_dtxsid = list(
    path = "/chemi/amos/get_classification_for_dtxsid/",
    parameter = "dtxsid"
  ),
  chemi_amos_by_text = list(path = "/chemi/amos/search_by_text/", parameter = "substr")
)
verify_client <- function(lib, out, lookup_cases) {
  library(ComptoxR, lib.loc = lib)
  stopifnot(identical(normalizePath(find.package("ComptoxR")), normalizePath(file.path(lib, "ComptoxR"))))
  options(cli.num_colors = 1, width = 100, ComptoxR.run_verbose = FALSE)
  Sys.setenv(ctx_api_key = "pilot-local-key", batch_limit = "2")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  unlink(list.files(out, pattern = "^request-[0-9]+[.]rds$", full.names = TRUE))
  ready <- file.path(out, "ready.rds")
  unlink(ready)
  server <- callr::r_bg(
    function(out, ready) {
      port <- httpuv::randomPort()
      n <- 0L
      srv <- httpuv::startServer(
        "127.0.0.1",
        port,
        list(call = function(req) {
          n <<- n + 1L
          raw <- req$rook.input$read()
          record <- list(
            method = req$REQUEST_METHOD,
            path = req$PATH_INFO,
            query = req$QUERY_STRING,
            content_type = req$CONTENT_TYPE,
            body = raw,
            key = req$HTTP_X_API_KEY
          )
          saveRDS(record, file.path(out, sprintf("request-%04d.rds", n)))
          control <- readRDS(file.path(out, "response.rds"))
          response <- control$body
          if (isTRUE(control$pagination)) {
            offset <- jsonlite::fromJSON(rawToChar(raw))$offset
            if (is.null(offset)) {
              offset <- 0L
            }
            response <- sprintf(
              '{"totalRecordsCount":2,"recordsCount":1,"offset":%d,"records":[{"sid":"DTXSID%d"}]}',
              offset,
              offset + 1L
            )
          }
          list(status = control$status, headers = list("Content-Type" = "application/json"), body = response)
        })
      )
      saveRDS(port, ready)
      on.exit(httpuv::stopServer(srv))
      repeat {
        httpuv::service(100)
      }
    },
    args = list(out, ready),
    supervise = TRUE
  )
  on.exit(server$kill(), add = TRUE)
  for (i in seq_len(100)) {
    if (file.exists(ready)) {
      break
    }
    if (!server$is_alive()) {
      stop(server$read_all_error())
    }
    Sys.sleep(0.05)
  }
  stopifnot(file.exists(ready))
  base <- paste0("http://127.0.0.1:", readRDS(ready))
  options(
    ComptoxR.ctx_burl = paste0(base, "/ctx/"),
    ComptoxR.epi_burl = paste0(base, "/epi/"),
    ComptoxR.chemi_burl = paste0(base, "/chemi/"),
    ComptoxR.pubchem_burl = paste0(base, "/pubchem/"),
    ComptoxR.np_burl = paste0(base, "/np/")
  )
  records <- function() lapply(sort(list.files(out, "^request-[0-9]+[.]rds$", full.names = TRUE)), readRDS)
  expected <- function(method, path, query = "", body = "", auth = FALSE) {
    list(
      method = method,
      path = path,
      query = if (nzchar(query)) paste0("?", query) else "",
      content_type = if (nzchar(body)) "application/json" else "",
      body = charToRaw(body),
      key = if (auth) "pilot-local-key" else NULL
    )
  }
  results <- list()
  probe <- function(
    name,
    expr,
    wire = list(),
    response = '[{"name":"benzene","smiles":"c1ccccc1","cas":"71-43-2"}]',
    status = 200L,
    pagination = FALSE,
    error = FALSE
  ) {
    saveRDS(list(body = response, status = status, pagination = pagination), file.path(out, "response.rds"))
    start <- length(records())
    warnings <- character()
    value <- tryCatch(
      withCallingHandlers(force(expr), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }),
      error = function(e) {
        list(
          error_class = class(e),
          message = conditionMessage(e),
          parent = if (!is.null(e$parent)) conditionMessage(e$parent) else NULL
        )
      }
    )
    actual <- records()
    actual <- if (length(actual) > start) actual[seq.int(start + 1L, length(actual))] else list()
    # httpuv represents an absent content type as NULL on some versions.
    actual <- lapply(actual, function(x) {
      if (is.null(x$content_type)) {
        x$content_type <- ""
      }
      x
    })
    # wire = NULL records requests without a modeled expectation; callers then rely on
    # the original-versus-candidate snapshot comparison.
    if (!is.null(wire) && !identical(actual, wire)) {
      saveRDS(list(actual = actual, expected = wire), file.path(out, paste0(name, "-wire-failure.rds")))
      stop("Exact wire assertion failed: ", name, "; inspect ", out)
    }
    if (!identical(is.list(value) && "error_class" %in% names(value), error)) {
      stop("Unexpected ", if (error) "success" else paste("error:", value$message), " in ", name)
    }
    results[[name]] <<- list(value = value, warnings = warnings, requests = actual)
    invisible(value)
  }
  probe("epi-default", epi_search("benzene"), list(expected("GET", "/epi/search", "query=benzene&limit=20")))
  probe(
    "epi-override-encoding",
    epi_search("a +&/", 3),
    list(expected("GET", "/epi/search", "query=a%20%2B%26%2F&limit=3"))
  )
  probe("alerts-minimal", chemi_alerts_groups_by_id("group 1"), list(expected("GET", "/chemi/alerts/groups/group%201")))
  probe(
    "detail-default",
    ct_chemical_detail_search("DTXSID7020182"),
    list(expected(
      "GET",
      "/ctx/chemical/detail/search/by-dtxsid/DTXSID7020182",
      "projection=chemicaldetailall",
      auth = TRUE
    ))
  )
  probe(
    "bulk-batches",
    ct_chemical_detail_search_bulk(c("DTXSID1", "DTXSID2", "DTXSID1", "DTXSID3"), "compact"),
    list(
      expected("POST", "/ctx/chemical/detail/search/by-dtxsid/", "projection=compact", '["DTXSID1","DTXSID2"]', TRUE),
      expected("POST", "/ctx/chemical/detail/search/by-dtxsid/", "projection=compact", '["DTXSID3"]', TRUE)
    )
  )
  probe(
    "list-transform",
    ct_chemical_list_all(return_dtxsid = TRUE, coerce = TRUE),
    list(expected("GET", "/ctx/chemical/list/all", "projection=chemicallistwithdtxsids", auth = TRUE)),
    '[{"listName":"PILOT","dtxsids":"DTXSID1,DTXSID2"}]'
  )
  body <- '{"inputType":"MOL","searchType":"MASS","params":{"limit":1,"mass-type":"monoisotopic-mass","min-mass":100,"max-mass":200}}'
  probe(
    "mass-body",
    chemi_search(search_type = "mass", mass_type = "mono", min_mass = 100, max_mass = 200, limit = 1),
    list(expected("POST", "/chemi/search", body = body)),
    '{"totalRecordsCount":1,"records":[{"sid":"DTXSID1"}]}'
  )
  probe(
    "mass-pagination",
    chemi_search(search_type = "mass", mass_type = "mono", min_mass = 100, max_mass = 200, limit = 1, all_pages = TRUE),
    list(
      expected("POST", "/chemi/search", body = body),
      expected("POST", "/chemi/search", body = paste0(substr(body, 1, nchar(body) - 1), ',"offset":1}'))
    ),
    pagination = TRUE
  )
  probe("invalid-missing-epi-query", epi_search(), error = TRUE)
  probe("invalid-missing-alert-id", chemi_alerts_groups_by_id(), error = TRUE)
  probe("invalid-search", chemi_search(search_type = "invalid"), error = TRUE)
  probe("invalid-similarity", chemi_search(search_type = "mass", min_similarity = 2), error = TRUE)
  probe("invalid-empty-detail", ct_chemical_detail_search(character()), error = TRUE)
  probe("invalid-empty-bulk", ct_chemical_detail_search_bulk(character()), error = TRUE)
  Sys.unsetenv("ctx_api_key")
  probe("missing-auth", ct_chemical_detail_search("DTXSID1"), error = TRUE)
  probe("public-without-auth", epi_search("benzene"), list(expected("GET", "/epi/search", "query=benzene&limit=20")))
  Sys.setenv(ctx_api_key = "pilot-local-key")
  probe(
    "http-400",
    epi_search("benzene"),
    list(expected("GET", "/epi/search", "query=benzene&limit=20")),
    '{"error":"pilot bad request"}',
    status = 400L,
    error = TRUE
  )
  for (name in names(lookup_cases)) {
    item <- lookup_cases[[name]]
    fun <- getExportedValue("ComptoxR", name)
    inputs <- if (is.null(item$parameter)) list() else setNames(list("DTXSID7020182"), item$parameter)
    path <- paste0(item$path, if (!is.null(item$parameter)) "DTXSID7020182" else "")
    probe(paste0(name, "-minimal"), do.call(fun, inputs), list(expected("GET", path)))
    if (!is.null(item$parameter)) {
      probe(paste0("invalid-missing-", name), do.call(fun, list()), error = TRUE)
      probe(paste0("invalid-empty-", name), do.call(fun, setNames(list(character()), item$parameter)), error = TRUE)
      probe(paste0("invalid-blank-", name), do.call(fun, setNames(list(""), item$parameter)), error = TRUE)
    }
  }
  probe(
    "amos-text-encoded",
    chemi_amos_by_text("caf\u00e9 +/&"),
    list(expected("GET", "/chemi/amos/search_by_text/caf%C3%A9%20%2B%2F%26"))
  )
  probe(
    "amos-id-batches",
    chemi_amos_get_info_by_id(c("record 1", "record 2", "record 1", NA_character_, "")),
    list(
      expected("GET", "/chemi/amos/get_info_by_id/record%201"),
      expected("GET", "/chemi/amos/get_info_by_id/record%202")
    )
  )
  registry <- get(".HookRegistry", asNamespace("ComptoxR"))
  saved <- registry$config
  hook <- function(name, fn) assign(name, fn, envir = .GlobalEnv)
  order <- character()
  hook("pilot_first", function(data) {
    order <<- c(order, "first")
    list(params = list(projection = "compact"))
  })
  hook("pilot_second", function(data) {
    order <<- c(order, "second")
    stopifnot(data$params$projection == "compact")
    data
  })
  hook("pilot_post", function(data) {
    order <<- c(order, "post")
    stopifnot(isTRUE(data$params$return_dtxsid), isTRUE(data$params$coerce))
    data$result
  })
  registry$config$ct_chemical_list_all <- list(
    pre_request = c("pilot_first", "pilot_second"),
    post_response = "pilot_post"
  )
  probe(
    "partial-hook-update",
    ct_chemical_list_all(return_dtxsid = TRUE, coerce = TRUE),
    list(expected("GET", "/ctx/chemical/list/all", "projection=compact", auth = TRUE))
  )
  stopifnot(identical(order, c("first", "second", "post")))
  hook("pilot_skip", function(data) {
    data$skip_request <- TRUE
    data$result <- "cached"
    data$state <- "retained"
    data
  })
  hook("pilot_forbidden", function(data) stop("post must not run"))
  registry$config$ct_chemical_list_all <- list(pre_request = "pilot_skip", post_response = "pilot_forbidden")
  stopifnot(identical(probe("list-skip", ct_chemical_list_all()), "cached"))
  hook("pilot_state", function(data) {
    stopifnot(data$state == "retained", data$result == "cached")
    "post-ran"
  })
  registry$config$chemi_search <- list(pre_request = "pilot_skip", post_response = "pilot_state")
  stopifnot(identical(probe("search-post-on-skip", chemi_search()), "post-ran"))
  hook("pilot_throw", function(data) stop("pilot hook exception"))
  registry$config$chemi_search <- list(pre_request = "pilot_throw")
  probe("pre-hook-exception", chemi_search(search_type = "mass"), error = TRUE)
  registry$config$chemi_search <- list(pre_request = "pilot_skip", post_response = "pilot_throw")
  probe("post-hook-exception", chemi_search(search_type = "mass"), error = TRUE)
  registry$config$epi_search <- list(post_response = "pilot_throw")
  probe(
    "generated-post-hook-exception",
    epi_search("benzene"),
    list(expected("GET", "/epi/search", "query=benzene&limit=20")),
    error = TRUE
  )
  registry$config <- saved
  exports <- sort(getNamespaceExports("ComptoxR"))
  stopifnot(!any(c("specmill", "wrapmaint") %in% loadedNamespaces()))
  interfaces <- lapply(exports, function(name) {
    object <- getExportedValue("ComptoxR", name)
    if (is.function(object)) formals(object) else class(object)
  })
  names(interfaces) <- exports
  snapshot <- list(
    interfaces = interfaces,
    exported_function_count = sum(vapply(
      exports,
      function(name) is.function(getExportedValue("ComptoxR", name)),
      logical(1)
    )),
    cases = results
  )
  saveRDS(snapshot, file.path(out, "snapshot.rds"))
  snapshot
}

before <- callr::r(
  verify_client,
  list(libs[[1]], file.path(out, "before"), lookup_cases),
  libpath = c(libs[[1]], .libPaths())
)
after <- callr::r(
  verify_client,
  list(libs[[2]], file.path(out, "after"), lookup_cases),
  libpath = c(libs[[2]], .libPaths())
)
stopifnot(identical(before, after))
# Resolve stable operation identities from the adopted mappings, not function-name guesses.
script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
pilot_dir <- dirname(normalizePath(sub("^--file=", "", script_arg[[1]])))
root <- normalizePath(file.path(pilot_dir, "../.."))
case_groups <- list(
  epi_search = c(
    "epi-default",
    "epi-override-encoding",
    "invalid-missing-epi-query",
    "public-without-auth",
    "http-400",
    "generated-post-hook-exception"
  ),
  chemi_alerts_groups_by_id = c("alerts-minimal", "invalid-missing-alert-id"),
  ct_chemical_detail_search = c("detail-default", "invalid-empty-detail", "missing-auth"),
  ct_chemical_detail_search_bulk = c("bulk-batches", "invalid-empty-bulk"),
  ct_chemical_list_all = c("list-transform", "partial-hook-update", "list-skip"),
  chemi_search = c(
    "mass-body",
    "mass-pagination",
    "invalid-search",
    "invalid-similarity",
    "search-post-on-skip",
    "pre-hook-exception",
    "post-hook-exception"
  )
)
for (name in names(lookup_cases)) {
  case_groups[[name]] <- paste0(name, "-minimal")
  if (!is.null(lookup_cases[[name]]$parameter)) {
    case_groups[[name]] <- c(
      case_groups[[name]],
      paste0(c("invalid-missing-", "invalid-empty-", "invalid-blank-"), name)
    )
  }
}
case_groups$chemi_amos_by_text <- c(case_groups$chemi_amos_by_text, "amos-text-encoded")
case_groups$chemi_amos_get_info_by_id <- c(case_groups$chemi_amos_get_info_by_id, "amos-id-batches")
stopifnot(setequal(unlist(case_groups), names(before$cases)), !anyDuplicated(unlist(case_groups)))
identities <- list()
for (path in sort(list.files(file.path(root, "apis"), "-pilot[.]yml$", full.names = TRUE))) {
  config <- yaml::read_yaml(path)
  stopifnot(length(config$schemas$files) == 1L)
  for (key in names(config$operations)) {
    operation <- config$operations[[key]]
    if (!operation$name %in% names(case_groups)) {
      next
    }
    identities[[operation$name]] <- list(
      schema = config$schemas$files[[1]],
      method = sub(" .*", "", key),
      path = sub("^[^ ]+ ", "", key),
      stable_key = paste(config$schemas$files[[1]], key, sep = " | "),
      function_name = operation$name,
      implementation = operation$implementation
    )
  }
}
stopifnot(setequal(names(identities), names(case_groups)))
mode <- function(name) {
  if (name %in% c("epi-default", "detail-default")) {
    return("required input with public optional defaults")
  }
  if (grepl("-minimal$", name)) {
    return("minimal required public input")
  }
  if (grepl("^invalid-", name)) {
    return("invalid public input")
  }
  if (name %in% c("missing-auth", "public-without-auth")) {
    return("authentication environment override")
  }
  if (name == "http-400") {
    return("HTTP error response override")
  }
  if (grepl("hook|skip", name)) {
    return("explicit test hook override")
  }
  "explicit public argument overrides"
}
rows <- lapply(names(case_groups), function(name) {
  cases <- lapply(case_groups[[name]], function(case_name) {
    case <- before$cases[[case_name]]
    failed <- is.list(case$value) && "error_class" %in% names(case$value)
    list(
      case = case_name,
      mode = mode(case_name),
      exact_wire_equal = TRUE,
      received_requests = length(case$requests),
      authentication = if (!length(case$requests)) {
        "no request"
      } else {
        vapply(
          case$requests,
          function(request) if (is.null(request$key)) "x-api-key absent" else "x-api-key equals local test key",
          character(1)
        )
      },
      result_classes = if (!failed) class(case$value) else character(),
      result_rows = if (is.data.frame(case$value)) nrow(case$value) else NULL,
      error_classes = if (failed) case$value$error_class else character(),
      error_message = if (failed) case$value$message else NULL,
      parent_error = if (failed) case$value$parent else NULL,
      warnings = case$warnings
    )
  })
  c(identities[[name]], list(covered_cases = cases))
})
summary <- list(
  scope = "Installed baseline and migrated clients, offline localhost only. Synthetic response fixtures; no verified live API behavior.",
  comparison = "identical objects, warnings, errors, exports and formals; independently asserted exact received methods, paths, query encoding, content types, body bytes and authentication",
  fixture_modes = "Public defaults, explicit argument overrides, minimal public inputs, invalid inputs and hook overrides are labeled per case. Source-schema default/override/minimal fixtures remain separate in schema-results.json.",
  baseline_commit = "4fd720b97fb2f7f2abf131925e9270b0c11b057a",
  passed_cases = length(before$cases),
  exported_names_compared = length(before$interfaces),
  exported_function_formals_compared = before$exported_function_count,
  operations = rows
)
jsonlite::write_json(
  summary,
  file.path(pilot_dir, "runtime-results.json"),
  pretty = TRUE,
  auto_unbox = TRUE,
  null = "null"
)
writeLines(
  c(
    sprintf(
      "PASS: %d installed-client localhost cases; exact requests, objects, errors, warnings, exports and formals identical.",
      length(before$cases)
    ),
    "No live API behavior was tested.",
    "The existing chemi_search all_pages result shaping is preserved, including its empty tibble for collected raw records."
  ),
  file.path(out, "RESULT.txt")
)
cat(readLines(file.path(out, "RESULT.txt")), sep = "\n")
