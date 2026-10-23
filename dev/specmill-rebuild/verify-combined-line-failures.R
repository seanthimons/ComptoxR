args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply the candidate checkout path.")
root <- normalizePath(args[[1L]])
.libPaths(c(file.path(root, "dev/specmill-pilot/artifacts/toolkit-library"), .libPaths()))
suppressMessages(devtools::load_all(root, quiet = TRUE))
ns <- asNamespace("ComptoxR")
fixture <- readRDS(file.path(root, "dev/specmill-rebuild/pending-exact-search-lines.rds"))
old <- eval(fixture$legacy[[3L]], ns)
native <- get("ct_chemical_search_equal_bulk", ns)
stopifnot(identical(formals(old), formals(native)))
directory <- tempfile("line-warning-http-")
dir.create(directory)
server <- callr::r_bg(function(directory) {
    count <- 0L
    port <- httpuv::randomPort()
    httpuv::startServer("127.0.0.1", port, list(call = function(req) {
        count <<- count + 1L
        body <- req$rook.input$read()
        mode <- readRDS(file.path(directory, "mode.rds"))
        status <- if (mode$partial && !grepl("one", rawToChar(body), fixed = TRUE)) 200L else mode$status
        saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, media = req$CONTENT_TYPE, accept = req$HTTP_ACCEPT,
            key = req$HTTP_X_API_KEY, body = body, status = status), file.path(directory, sprintf("request-%05d.rds",
            count)))
        list(status = status, headers = list(`Content-Type` = "application/json"), body = "[{\"id\":1}]")
    }))
    saveRDS(port, file.path(directory, "port.rds"))
    repeat httpuv::service(50)
}, args = list(directory), supervise = TRUE)
local({
    on.exit({
        server$kill()
        unlink(directory, recursive = TRUE)
    })
    for (i in seq_len(500L)) {
        if (file.exists(file.path(directory, "port.rds")))
            break
        if (!server$is_alive())
            stop("Local HTTP server failed")
        Sys.sleep(0.02)
    }
    withr::local_options(ComptoxR.ctx_burl = paste0("http://127.0.0.1:", readRDS(file.path(directory,
        "port.rds"))))
    withr::local_envvar(ctx_api_key = "local-line-warning-key")
    testthat::local_mocked_bindings(req_retry = function(req, ...) req, .package = "httr2")
    capture <- function() lapply(sort(list.files(directory, pattern = "^request-", full.names = TRUE)),
        readRDS)
    invoke <- function(fn, input) {
        before <- length(capture())
        warnings <- character()
        value <- withCallingHandlers(tryCatch(suppressMessages(fn(input)), error = identity), warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
        })
        after <- capture()
        list(value = value, warnings = warnings, wire = if (length(after) > before) after[seq.int(before +
            1L, length(after))] else list())
    }
    inputs <- list("one", c("one", "one"), c("one", "two"), c("one", "two", "three"), "one\ntwo", c("one",
        "two", "one\ntwo"), c("one", "", "one", NA_character_, "café"))
    results <- list()
    for (limit in c("1", "2")) local({
        withr::local_envvar(batch_limit = limit)
        for (status in c(404L, 500L)) for (partial in c(FALSE, TRUE)) for (input in inputs) {
            saveRDS(list(status = status, partial = partial), file.path(directory, "mode.rds"))
            a <- invoke(old, input)
            b <- invoke(native, input)
            if (!identical(a$wire, b$wire) || !identical(a$warnings, b$warnings) || inherits(a$value,
                "error") != inherits(b$value, "error") || !inherits(a$value, "error") && !identical(a$value,
                b$value)) {
                print(list(limit = limit, status = status, partial = partial, input = input, old = a,
                  native = b))
                stop("Actual line failure parity mismatch")
            }
            if (!inherits(b$value, "error"))
                stopifnot(is.null(attr(b$value, "failed")))
            results[[length(results) + 1L]] <<- list(limit = limit, status = status, partial = partial,
                input = input, old = a, native = b)
        }
    })
    cat("PASS", length(results), "actual localhost404/500 single/all/partial cases: exact full values/attrs/warnings/wire, empty tibbles, duplicates/normalization, LF ambiguity and effective request count.\n")
    for (limit in c("1", "2")) local({
        withr::local_envvar(batch_limit = limit)
        for (input in list("one", c("one", "two"), "one\ntwo")) {
            saveRDS(list(status = 401L, partial = FALSE), file.path(directory, "mode.rds"))
            b <- invoke(native, input)
            stopifnot(inherits(b$value, "specmill_call_error"), !length(b$warnings))
        }
    })
    cat("PASS6 native actual401 cases stay hard without formatter/drop; legacy multi401 explicitly excluded from parity claim.\n")
})
