root <- normalizePath(".")
.libPaths(c(file.path(root, "dev/specmill-pilot/artifacts/toolkit-library"), .libPaths()))
suppressMessages(devtools::load_all(root, quiet = TRUE))
ns <- asNamespace("ComptoxR")
fixture <- readRDS(file.path(root, "tests/testthat/fixtures/native-toxprint.rds"))
old <- eval(fixture$legacy[[3]], ns)
new <- get("chemi_toxprint", ns)
stopifnot(identical(formals(old), formals(new)))
local({
    directory <- tempfile("tox31-")
    dir.create(directory)
    proc <- callr::r_bg(function(directory) {
        counter <- 0L
        port <- httpuv::randomPort()
        server <- httpuv::startServer("127.0.0.1", port, list(call = function(req) {
            counter <<- counter + 1L
            saveRDS(list(method = req$REQUEST_METHOD, path = req$PATH_INFO, query = req$QUERY_STRING,
                accept = req$HTTP_ACCEPT, media = req$CONTENT_TYPE, body = req$rook.input$read()), file.path(directory,
                sprintf("request-%04d.rds", counter)))
            list(status = 200L, headers = list(`Content-Type` = "application/json"), body = paste(readLines(file.path(directory,
                "response.json")), collapse = "\n"))
        }))
        on.exit(httpuv::stopServer(server))
        saveRDS(port, file.path(directory, "ready.rds"))
        repeat httpuv::service(100)
    }, args = list(directory), supervise = TRUE)
    on.exit(proc$kill())
    for (i in seq_len(100)) {
        if (file.exists(file.path(directory, "ready.rds")))
            break
        Sys.sleep(0.05)
    }
    withr::local_options(list(ComptoxR.chemi_burl = paste0("http://127.0.0.1:", readRDS(file.path(directory,
        "ready.rds")), "/api")))
    captures <- function() lapply(sort(list.files(directory, pattern = "^request-", full.names = TRUE)),
        readRDS)
    payloads <- c("[{\"id\":\"one\",\"value\":0,\"flag\":false},{\"id\":\"two\",\"value\":1,\"flag\":true}]",
        "{\"one\":{\"value\":0,\"flag\":false},\"two\":{\"value\":1,\"flag\":true}}", "[]", "{\"score\":0,\"flag\":false}",
        "null")
    cases <- list(list(query = c("one", "two")), list(query = c("one", "café", "one", "", NA_character_)),
        list(query = "one", odds_ratio = NULL, p_val = NULL, true_pos = NULL), list(query = "one", odds_ratio = FALSE,
            p_val = 0, true_pos = 0), list(query = "one", odds_ratio = list(absent = NULL, flag = FALSE,
            count = 0)), list(query = 0), list(query = FALSE))
    results <- list()
    for (payload in payloads) {
        writeLines(payload, file.path(directory, "response.json"))
        for (args in cases) {
            before <- length(captures())
            a <- withVisible(do.call(old, args))
            b <- withVisible(do.call(new, args))
            wire <- tail(captures(), 2L)
            saveRDS(list(args = args, payload = payload, old = a, new = b, wire = wire), file.path(directory,
                "last-comparison.rds"))
            stopifnot(length(captures()) == before + 2L, identical(a, b), identical(wire[[1]], wire[[2]]))
            c <- withVisible(do.call(new, unname(args)))
            stopifnot(identical(c, b), identical(tail(captures(), 1L)[[1]], wire[[2]]))
            results[[length(results) + 1L]] <- list(args = args, payload = payload, result = b, wire = wire[[2]])
        }
    }
    before <- length(captures())
    for (query in list(NULL, character(), c("", NA_character_))) {
        args <- list(query = query, odds_ratio = quote(stop("option evaluated")))
        a <- tryCatch(do.call(old, args), error = conditionMessage)
        b <- tryCatch(do.call(new, args), error = conditionMessage)
        stopifnot(identical(a, b), grepl("Either query or chemicals parameter must be provided", b, fixed = TRUE),
            length(captures()) == before)
    }
    stopifnot(length(results) == 35L)
    cat("PASS35 actual localhost comparisons: exact body/headers/path, old/new result/visibility, named/positional, defaults/NULL/FALSE/zero/nested options, cleanup/UTF8 and empty guard before option evaluation.\n")
})
local({
    for (value in list(NULL, FALSE, 0, list(score = 0, flag = FALSE, nested = list(absent = NULL)))) local({
        testthat::local_mocked_bindings(generic_chemi_request = function(...) invisible(value), .ct_request = function(...) invisible(value),
            .package = "ComptoxR")
        stopifnot(identical(withVisible(old("one")), withVisible(new("one"))))
    })
    cat("PASS final helper visibility propagates for invisible NULL/FALSE/zero/nested values.\n")
})
