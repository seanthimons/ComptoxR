candidate <- commandArgs(trailingOnly = TRUE)
stopifnot(length(candidate) == 1L)
root <- normalizePath(candidate[[1L]])
fixture <- readRDS("dev/specmill-rebuild/pending-exact-search-lines.rds")
.libPaths(c(normalizePath("dev/specmill-pilot/artifacts/toolkit-library"), .libPaths()))
suppressMessages(devtools::load_all(root, quiet = TRUE))
ns <- asNamespace("ComptoxR")
old <- eval(fixture$legacy[[3L]], ns)
native <- get("ct_chemical_search_equal_bulk", ns)
stopifnot(identical(formals(old), formals(native)))
directory <- tempfile("line32-http-")
dir.create(directory)
server <- callr::r_bg(function(directory) {
    port <- httpuv::randomPort()
    count <- 0L
    httpuv::startServer("127.0.0.1", port, list(call = function(req) {
        count <<- count + 1L
        body <- req$rook.input$read()
        mode <- readRDS(file.path(directory, "mode.rds"))
        status <- if (mode$partial && rawToChar(body) != "one") 200L else mode$status
        saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, body = body, status = status),
            file.path(directory, sprintf("request-%04d.rds", count)))
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
            stop("Local HTTP failed")
        Sys.sleep(0.02)
    }
    stopifnot(file.exists(file.path(directory, "port.rds")))
    withr::local_options(ComptoxR.ctx_burl = paste0("http://127.0.0.1:", readRDS(file.path(directory,
        "port.rds"))))
    withr::local_envvar(ctx_api_key = "local-line32-key", batch_limit = "1")
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
        error <- inherits(value, "error")
        list(error = error, value = if (error) NULL else value, classes = if (error) class(value) else NULL,
            message = if (error) conditionMessage(value) else NULL, warnings = warnings, wire = if (length(after) >
                before) after[seq.int(before + 1L, length(after))] else list())
    }
    results <- list()
    for (status in c(404L, 500L, 401L)) for (kind in c("single", "all", "partial")) {
        saveRDS(list(status = status, partial = kind == "partial"), file.path(directory, "mode.rds"))
        input <- if (kind == "single")
            "one"
        else c("one", "two")
        name <- paste(status, kind, sep = "_")
        a <- invoke(old, input)
        b <- invoke(native, input)
        results[[name]] <- list(input = input, old = a, native = b)
        cat(name, "old error=", a$error, "native error=", b$error, "old failed=", paste(attr(a$value,
            "failed"), collapse = ","), "native failed=", paste(attr(b$value, "failed"), collapse = ","),
            "\n")
    }
    stopifnot(results[["404_single"]]$old$error, !results[["404_single"]]$native$error, results[["500_single"]]$old$error,
        !results[["500_single"]]$native$error, is.null(attr(results[["500_partial"]]$old$value, "failed")),
        !is.null(attr(results[["500_partial"]]$native$value, "failed")))
    stopifnot(length(results) == 9L)
    cat("CONFIRMED released32 line success fix; exact-search bulk still needs request-count errors + failure metadata release.\n")
})
