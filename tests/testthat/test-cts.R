cts_test_reply <- function(json) {
  httr2::response(
    status_code = 200L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(json)
  )
}

cts_aspirin_body <- list(
  structure = "CC(=O)Oc1ccccc1C(=O)O",
  generationLimit = 4L,
  transformationLibraries = "hydrolysis"
)

test_that("CTS returns discovery metadata and sends an empty JSON input object", {
  local_mocked_bindings(
    req_perform = function(req, ...) {
      if (endsWith(req$url, "/metabolizer")) {
        expect_identical(req$method, "GET")
        return(cts_test_reply('{"metaInfo":{},"links":null}'))
      }

      expect_identical(req$method, "POST")
      expect_identical(req$url, "https://qed.epa.gov/cts/rest/metabolizer/inputs")
      expect_identical(as.character(jsonlite::toJSON(req$body$data, auto_unbox = TRUE)), "{}")
      cts_test_reply('{"metaInfo":{},"inputs":{"structure":"","generationLimit":1}}')
    },
    .package = "httr2"
  )

  expect_named(cts_metabolizer(), c("metaInfo", "links"))
  expect_identical(cts_metabolizer_inputs(list())$inputs$structure, "")
})

test_that("CTS sends a one-library array and keeps the aspirin product tree", {
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) stop("Unexpected lookup"),
    .package = "ComptoxR"
  )
  local_mocked_bindings(
    req_perform = function(req, ...) {
      expect_identical(req$method, "POST")
      expect_identical(req$url, "https://qed.epa.gov/cts/rest/metabolizer/run")
      expect_identical(req$body$data$structure, cts_aspirin_body$structure)
      expect_identical(req$body$data$generationLimit, 4L)
      wire <- jsonlite::toJSON(req$body$data, auto_unbox = TRUE)
      expect_match(as.character(wire), '"transformationLibraries":["hydrolysis"]', fixed = TRUE)
      cts_test_reply(paste0(
        '{"metaInfo":{},"data":{"unique_products":2,"data":{"children":[',
        '{"data":{"smiles":"CC(O)=O","generation":1}},',
        '{"data":{"smiles":"OC(=O)c1ccccc1O","generation":1}}]}}}'
      ))
    },
    .package = "httr2"
  )

  result <- cts_metabolizer_run(cts_aspirin_body)
  expect_identical(result$data$unique_products, 2L)
  expect_identical(
    vapply(result$data$data$children, function(node) node$data$smiles, character(1)),
    c("CC(O)=O", "OC(=O)c1ccccc1O")
  )
})

test_that("CTS resolves one DTXSID to a single usable SMILES before sending it", {
  found <- function(smiles) {
    list(result = "FOUND", chemical = list(canonicalSmiles = smiles))
  }
  records <- list(found(cts_aspirin_body$structure), found(cts_aspirin_body$structure))
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      expect_identical(ids, "DTXSID5020108")
      expect_identical(idsType, "DTXSID")
      expect_false(tidy)
      records
    },
    .package = "ComptoxR"
  )
  sent <- 0L
  local_mocked_bindings(
    req_perform = function(req, ...) {
      sent <<- sent + 1L
      expect_identical(req$body$data$structure, cts_aspirin_body$structure)
      cts_test_reply('{"metaInfo":{},"data":{"unique_products":0}}')
    },
    .package = "httr2"
  )

  body <- cts_aspirin_body
  body$structure <- " dtxsid5020108 "
  expect_identical(cts_metabolizer_run(body)$data$unique_products, 0L)

  records <- list(list(result = "NOT_FOUND"))
  expect_error(cts_metabolizer_run(body), "returned 0 distinct structures")
  records <- list(found("CC"), found("CCC"))
  expect_error(cts_metabolizer_run(body), "returned 2 distinct structures")
  expect_identical(sent, 1L)
})

test_that("CTS distinguishes a zero-product result from a calculation failure", {
  json <- '{"metaInfo":{},"data":{"unique_products":0,"data":{"children":[]}}}'
  local_mocked_bindings(req_perform = function(...) cts_test_reply(json), .package = "httr2")

  body <- cts_aspirin_body
  body$structure <- "CCCC"
  expect_length(cts_metabolizer_run(body)$data$data$children, 0)

  json <- '{"metaInfo":{},"data":{"unique_products":0,"data":null,"error":"Error getting transformation products"}}'
  expect_error(
    cts_metabolizer_run(body),
    "Error getting transformation products",
    class = "comptoxr_cts_calculation_error"
  )
})

test_that("CTS rejects incomplete run inputs and multiple libraries before the request", {
  local_mocked_bindings(req_perform = function(...) stop("Unexpected request"), .package = "httr2")

  for (field in names(cts_aspirin_body)) {
    expect_error(cts_metabolizer_run(cts_aspirin_body[names(cts_aspirin_body) != field]), "Invalid body")
  }
  body <- cts_aspirin_body
  body$transformationLibraries <- c("hydrolysis", "abiotic_reduction")
  expect_error(cts_metabolizer_run(body), "Invalid body")
})
