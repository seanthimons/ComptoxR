resolved_payloads <- list(
  chemi_resolver_getsimilaritymap = list(
    flat = TRUE,
    args = list(section = 'Names and Identifiers', sort = TRUE, format = 'raw')
  ),
  chemi_alerts = list(flat = TRUE, args = list(options = list(alerts = 'group'))),
  chemi_hazard_bulk = list(flat = FALSE, args = list(empty = TRUE, options = list(noRecords = TRUE), format = 'raw')),
  chemi_resolver_orderBySimilarity = list(flat = FALSE, args = list(fingerprintName = 'TP', rdkitBits = 64L)),
  chemi_resolver_pubchem_section_bulk = list(flat = TRUE, args = list(section = 'Toxicity')),
  chemi_stdizer_chemicals = list(
    flat = TRUE,
    args = list(full = TRUE, options = list(run = 'run', workflow = 'workflow'))
  ),
  chemi_toxprints_calculate_bulk = list(
    flat = TRUE,
    args = list(labels = TRUE, options = list(profile = 'toxprint_V2_0_r711'))
  )
)

test_that('resolved native operations send the schema-declared chemical and option fields', {
  ns <- asNamespace('ComptoxR')
  lookup <- list(
    list(result = 'FOUND', chemical = list(chemId = 'ONE', canonicalSmiles = 'C')),
    list(result = 'FOUND', chemical = list(chemId = 'TWO', canonicalSmiles = 'CC'))
  )
  local_mocked_bindings(chemi_resolver_lookup_bulk = function(...) lookup, .package = 'ComptoxR')
  requests <- list()
  local_mocked_bindings(
    req_perform = function(req, ...) {
      requests[[length(requests) + 1L]] <<- req
      httr2::response(
        status_code = 200L,
        headers = list(`Content-Type` = 'application/json'),
        body = charToRaw('[{"value":1}]')
      )
    },
    .package = 'httr2'
  )
  for (name in names(resolved_payloads)) {
    spec <- resolved_payloads[[name]]
    requests <- list()
    result <- do.call(get(name, ns), c(list(query = c('one', 'two')), spec$args))
    expect_identical(result, list(list(value = 1L)), info = name)
    expect_length(requests, 1L)
    req <- requests[[1L]]
    expect_identical(req$method, 'POST')
    expect_identical(req$headers$Accept, 'application/json')
    body <- req$body$data
    expect_length(body$chemicals, 2L)
    if (spec$flat) {
      expect_identical(body$chemicals[[1L]]$sid, 'ONE')
      expect_identical(body$chemicals[[2L]]$smiles, 'CC')
      expect_null(body$chemicals[[1L]]$chemical)
    } else {
      expect_identical(body$chemicals[[1L]]$chemical$sid, 'ONE')
      expect_identical(body$chemicals[[2L]]$chemical$smiles, 'CC')
    }
    fields <- setdiff(names(spec$args), c('format', 'sort'))
    expect_setequal(names(body), c('chemicals', fields))
    for (field in fields) {
      expected <- spec$args[[field]]
      if (name == 'chemi_alerts' && field == 'options') {
        expected$alerts <- list(expected$alerts)
      }
      expect_identical(body[[field]], expected)
    }
  }
})

test_that('resolved native operations retain early unresolved skips and malformed JSON conditions', {
  ns <- asNamespace('ComptoxR')
  fixture <- readRDS(test_path('fixtures/native-resolved-chemical-contracts.rds'))
  for (name in names(resolved_payloads)) {
    for (found in c(TRUE, FALSE)) {
      local({
        requests <- 0L
        local_mocked_bindings(
          chemi_resolver_lookup_bulk = function(...) {
            if (found) {
              list(list(result = 'FOUND', chemical = list(chemId = 'ONE', canonicalSmiles = 'C')))
            } else {
              list(list(result = 'NOT_FOUND'))
            }
          },
          .package = 'ComptoxR'
        )
        local_mocked_bindings(
          req_perform = function(req, ...) {
            requests <<- requests + 1L
            httr2::response(
              status_code = 200L,
              headers = list(`Content-Type` = 'application/json'),
              body = charToRaw('{')
            )
          },
          .package = 'httr2'
        )
        invoke <- function(fn) {
          requests <<- 0L
          warnings <- character()
          value <- withCallingHandlers(tryCatch(fn('one'), error = identity), warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart('muffleWarning')
          })
          list(
            value = if (!inherits(value, 'error')) value,
            error = if (inherits(value, 'error')) list(class = class(value), message = conditionMessage(value)),
            warnings = warnings,
            requests = requests
          )
        }
        old <- eval(fixture$legacy[[name]][[3L]], ns)
        expect_identical(invoke(get(name, ns)), invoke(old), info = name)
        expect_identical(formals(get(name, ns)), formals(old), info = name)
      })
    }
  }
})

test_that('default ToxPrint options serialize as an object and resolved fields survive', {
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(list(result = 'FOUND', chemical = list(chemId = 'ONE', canonicalSmiles = 'C', mol = 'MOL', cid = 'CID')))
    },
    .package = 'ComptoxR'
  )
  sent <- NULL
  local_mocked_bindings(
    req_perform = function(req, ...) {
      sent <<- req$body$data
      httr2::response(
        status_code = 200L,
        headers = list(`Content-Type` = 'application/json'),
        body = charToRaw('{"total":1}')
      )
    },
    .package = 'httr2'
  )
  expect_identical(chemi_toxprints_calculate_bulk('one')$total, 1L)
  expect_identical(sent$options, structure(list(), names = character()))
  expect_match(jsonlite::toJSON(sent, auto_unbox = TRUE), '"options":{}', fixed = TRUE)
  expect_identical(sent$chemicals[[1L]]$mol, 'MOL')
  expect_identical(sent$chemicals[[1L]]$cid, 'CID')
})

test_that('resolved options reject invalid types before the target request', {
  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(list(result = 'FOUND', chemical = list(chemId = 'ONE', canonicalSmiles = 'C')))
    },
    .package = 'ComptoxR'
  )
  sent <- FALSE
  local_mocked_bindings(
    req_perform = function(...) {
      sent <<- TRUE
      stop('target sent')
    },
    .package = 'httr2'
  )
  expect_error(chemi_alerts('one', options = 'not an object'))
  expect_false(sent)
  expect_error(chemi_stdizer_chemicals('one', options = list(workflow = list('bad'))))
  expect_false(sent)
})
