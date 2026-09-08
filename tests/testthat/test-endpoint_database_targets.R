endpoint_database_fixture <- function() {
  directory <- tempfile("endpoint databases ")
  dir.create(directory)
  withr::defer(unlink(directory, recursive = TRUE), envir = parent.frame())
  paths <- file.path(directory, c("first database", "second database.db"))
  for (i in seq_along(paths)) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = paths[i])
    DBI::dbWriteTable(con, "marker", data.frame(value = i))
    DBI::dbDisconnect(con, shutdown = TRUE)
  }
  list(paths = paths, hashes = tools::md5sum(paths))
}

endpoint_database_services <- list(
  list(
    key = "eco_burl",
    path_option = "ComptoxR.ecotox_path",
    selector = eco_server,
    get_con = .eco_get_con,
    close_con = .eco_close_con,
    tables = eco_tables,
    fields = eco_fields,
    route = "all_tbls"
  ),
  list(
    key = "toxval_burl",
    path_option = "ComptoxR.toxval_path",
    selector = toxval_server,
    get_con = .tox_get_con,
    close_con = .tox_close_con,
    tables = toxval_tables,
    fields = toxval_fields,
    route = "tables"
  )
)

test_that("legacy database path options switch cached connections without changing files", {
  fixture <- endpoint_database_fixture()
  withr::defer(.eco_close_con())
  withr::defer(.tox_close_con())
  withr::local_envvar(eco_burl = NA_character_, toxval_burl = NA_character_)
  withr::local_options(
    ComptoxR.eco_burl = NULL,
    ComptoxR.toxval_burl = NULL,
    ComptoxR.ecotox_path = NULL,
    ComptoxR.toxval_path = NULL
  )
  for (service in endpoint_database_services) {
    options(setNames(list(fixture$paths[1]), service$path_option))
    first <- service$get_con()
    expect_identical(DBI::dbReadTable(first, "marker")$value, 1L)
    options(setNames(list(fixture$paths[2]), service$path_option))
    second <- service$get_con()
    expect_false(DBI::dbIsValid(first))
    expect_identical(DBI::dbReadTable(second, "marker")$value, 2L)
    expect_identical(Sys.getenv(service$key), "")
    service$close_con()
    expect_identical(tools::md5sum(fixture$paths), fixture$hashes)
  }
})

test_that("database resets retain endpoint options and lookup leaves state unchanged", {
  fixture <- endpoint_database_fixture()
  withr::defer(.eco_close_con())
  withr::defer(.tox_close_con())
  withr::local_envvar(eco_burl = fixture$paths[1], toxval_burl = fixture$paths[1])
  withr::local_options(
    ComptoxR.eco_burl = fixture$paths[2],
    ComptoxR.toxval_burl = fixture$paths[2],
    ComptoxR.ecotox_path = fixture$paths[1],
    ComptoxR.toxval_path = fixture$paths[1]
  )
  for (service in endpoint_database_services) {
    con <- service$get_con()
    expect_identical(service$selector(NULL, url_only = TRUE), fixture$paths[2])
    expect_identical(Sys.getenv(service$key), fixture$paths[1])
    expect_true(DBI::dbIsValid(con))
    expect_identical(service$selector(NULL), fixture$paths[2])
    expect_identical(Sys.getenv(service$key), "")
    expect_identical(service$get_con(), con)
    options(setNames(list(NULL), paste0("ComptoxR.", service$key)))
    expect_identical(service$selector(NULL), fixture$paths[1])
    expect_false(DBI::dbIsValid(con))
    expect_identical(DBI::dbReadTable(service$get_con(), "marker")$value, 1L)
    service$close_con()
    expect_identical(tools::md5sum(fixture$paths), fixture$hashes)
  }
})

test_that("database clients send requests to option URLs and close old local connections", {
  fixture <- endpoint_database_fixture()
  withr::defer(.eco_close_con())
  withr::defer(.tox_close_con())
  withr::local_envvar(eco_burl = fixture$paths[1], toxval_burl = fixture$paths[1])
  withr::local_options(ComptoxR.eco_burl = NULL, ComptoxR.toxval_burl = NULL)
  requested <- character()
  local_mocked_bindings(
    req_perform = function(req, ...) {
      requested <<- c(requested, req$url)
      httr2::response(
        status_code = 200L,
        body = charToRaw('["marker"]'),
        headers = list("content-type" = "application/json")
      )
    },
    .package = "httr2"
  )
  for (service in endpoint_database_services) {
    local_con <- service$get_con()
    do.call(Sys.setenv, setNames(list("https://ignored.example/api"), service$key))
    options(setNames(list("https://configured.example/local-api"), paste0("ComptoxR.", service$key)))
    expect_identical(service$tables(), "marker")
    expect_false(DBI::dbIsValid(local_con))
    expect_identical(tail(requested, 1L), paste0("https://configured.example/local-api/", service$route))
    expect_identical(service$fields("tests"), "marker")
    expect_identical(tail(requested, 1L), "https://configured.example/local-api/fields/tests")
    expect_identical(Sys.getenv(service$key), "https://ignored.example/api")
    expect_identical(tools::md5sum(fixture$paths), fixture$hashes)
  }
  expect_length(requested, 4L)
})

test_that("database paths with spaces and relative aliases retain the same connection", {
  fixture <- endpoint_database_fixture()
  withr::defer(.eco_close_con())
  withr::defer(.tox_close_con())
  withr::local_envvar(eco_burl = NA_character_, toxval_burl = NA_character_)
  withr::local_options(ComptoxR.eco_burl = NULL, ComptoxR.toxval_burl = NULL)
  withr::local_dir(dirname(fixture$paths[1]))
  for (service in endpoint_database_services) {
    selected <- service$selector(basename(fixture$paths[1]))
    expect_identical(selected, normalizePath(fixture$paths[1]))
    original <- service$get_con()
    expect_identical(DBI::dbReadTable(original, "marker")$value, 1L)
    relative <- paste0("./", basename(fixture$paths[1]))
    do.call(Sys.setenv, setNames(list(relative), service$key))
    expect_identical(service$get_con(), original)
    expect_true(DBI::dbIsValid(original))
    options(setNames(list(fixture$paths[1]), paste0("ComptoxR.", service$key)))
    expect_identical(service$get_con(), original)
    service$close_con()
    expect_identical(tools::md5sum(fixture$paths), fixture$hashes)
  }
})
