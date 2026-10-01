test_that("adopted decoder and paginator handle ChET responses on localhost", {
  skip_if_not_installed("httpuv")
  skip_if_not_installed("callr")
  directory <- tempfile("chet-local-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  server <- callr::r_bg(
    function(directory) {
      port <- httpuv::randomPort()
      requests <- list()
      png <- magick::image_write(magick::image_blank(1L, 1L, color = 'white'), format = 'png')
      app <- list(call = function(request) {
        query <- httr2::url_parse(paste0("http://localhost/", request$QUERY_STRING))$query
        requests[[length(requests) + 1L]] <<- list(path = request$PATH_INFO, query = query)
        saveRDS(requests, file.path(directory, "requests.rds"))
        if (request$PATH_INFO == "/partial") {
          page <- as.integer(query$pageNumber)
          return(list(
            status = if (page == 1L) 200L else 400L,
            headers = list("Content-Type" = "application/json"),
            body = '[{"id":1}]'
          ))
        }
        if (request$PATH_INFO == "/chet/chemicals/1/image") {
          format <- query$format
          media <- switch(format, png = "image/png", svg = "image/svg+xml", pdf = "application/pdf")
          body <- switch(
            format,
            png = png,
            svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"><rect width="1" height="1"/></svg>',
            pdf = charToRaw("%PDF-1.4\nlocal fixture")
          )
          return(list(status = 200L, headers = list("Content-Type" = media), body = body))
        }
        page <- as.integer(query$page)
        rows <- if (page <= 2L) list(list(id = page * 2L - 1L), list(id = page * 2L)) else list()
        value <- if (request$PATH_INFO == "/chet/chemicals/counts") {
          rows
        } else {
          list(data = rows, length = length(rows), totallength = 4L)
        }
        list(
          status = if (page < 1L) 500L else 200L,
          headers = list("Content-Type" = "application/json"),
          body = as.character(jsonlite::toJSON(value, auto_unbox = TRUE))
        )
      })
      handle <- httpuv::startServer("127.0.0.1", port, app)
      on.exit(httpuv::stopServer(handle))
      saveRDS(port, file.path(directory, "ready.rds"))
      repeat {
        httpuv::service(100)
      }
    },
    args = list(directory),
    supervise = TRUE
  )
  on.exit(server$kill(), add = TRUE)
  ready <- file.path(directory, "ready.rds")
  for (i in seq_len(100L)) {
    if (file.exists(ready) || !server$is_alive()) {
      break
    }
    Sys.sleep(0.05)
  }
  expect_true(file.exists(ready), info = server$read_error())
  withr::local_options(list(
    ComptoxR.chemi_burl = paste0("http://127.0.0.1:", readRDS(ready)),
    ComptoxR.run_verbose = FALSE
  ))
  wrappers <- list(
    "/chet/chemicals/counts" = chemi_chet_chemicals_counts,
    "/chet/chemicals/database" = chemi_chet_chemicals_database,
    "/chet/reaction/database" = chemi_chet_reaction_database
  )
  for (path in names(wrappers)) {
    wrapper <- wrappers[[path]]
    result <- wrapper(size = 2)
    expect_identical(vapply(result, `[[`, integer(1), "id"), 1:4)
    calls <- tail(readRDS(file.path(directory, "requests.rds")), 3L)
    expect_identical(vapply(calls, `[[`, character(1), "path"), rep(path, 3L))
    expect_identical(vapply(calls, function(x) x$query$page, character(1)), as.character(1:3))
    manual <- wrapper(page = 2, size = 2, all_pages = FALSE)
    rows <- if (identical(wrapper, chemi_chet_chemicals_counts)) manual else manual[[1L]]$data
    expect_identical(rows, list(list(id = 3L), list(id = 4L)))
  }
  for (format in c("png", "svg", "pdf")) {
    result <- chemi_chet_chemicals_image(1, format = format)
    if (format == "pdf") {
      expect_type(result, "raw")
    } else {
      expect_s3_class(result, "magick-image")
    }
  }
  observed <- NULL
  testthat::with_mocked_bindings(
    {
      expect_no_warning(
        result <- generic_request(
          endpoint = "partial",
          method = "GET",
          batch_limit = 0,
          server = "chemi_burl",
          auth = FALSE,
          tidy = FALSE,
          paginate = TRUE,
          pagination_strategy = "page_number",
          pageNumber = 1
        )
      )
      expect_identical(result, list(list(id = 1L)))
    },
    observe_api_responses = function(responses) {
      observed <<- responses
    },
    .package = "ComptoxR"
  )
  expect_length(observed, 2L)
  expect_s3_class(observed[[2L]], "httr2_error")
})
