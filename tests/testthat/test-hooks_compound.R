if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

test_that("resolve_query_to_chemical_records maps resolver records to ChemicalRecord payloads", {
  hook <- get("resolve_query_to_chemical_records", envir = asNamespace("ComptoxR"))

  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(
        list(
          result = "FOUND",
          chemical = list(
            chemId = "DTXSID-A",
            canonicalSmiles = "C",
            casrn = "50-00-0",
            inchi = "InChI=1S/CH2O",
            inchiKey = "WSFSSNUMVMOOMR-UHFFFAOYSA-N",
            name = "formaldehyde"
          )
        ),
        list(result = "NOT_FOUND"),
        list(
          result = "FOUND",
          chemical = list(
            sid = "SID-ONLY",
            smiles = "CC"
          )
        )
      )
    },
    .package = "ComptoxR"
  )

  data <- hook(list(params = list(query = c("50-00-0", "x"), idType = "AnyId")))

  expect_null(data$params$query)
  expect_length(data$params$chemicals, 2L)
  expect_identical(data$params$chemicals[[1]]$chemical$sid, "DTXSID-A")
  expect_identical(data$params$chemicals[[1]]$chemical$smiles, "C")
  expect_identical(data$params$chemicals[[1]]$chemical$casrn, "50-00-0")
  expect_identical(data$params$chemicals[[1]]$chemical$inchi, "InChI=1S/CH2O")
  expect_identical(data$params$chemicals[[1]]$chemical$inchiKey, "WSFSSNUMVMOOMR-UHFFFAOYSA-N")
  expect_identical(data$params$chemicals[[1]]$chemical$name, "formaldehyde")
  expect_identical(data$params$chemicals[[2]]$chemical$sid, "SID-ONLY")
  expect_identical(data$params$chemicals[[2]]$chemical$smiles, "CC")
})

test_that("resolve_query_to_chemical_records short-circuits when nothing resolves", {
  hook <- get("resolve_query_to_chemical_records", envir = asNamespace("ComptoxR"))

  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(list(result = "NOT_FOUND"), list(result = "ERROR"))
    },
    .package = "ComptoxR"
  )

  expect_warning(
    data <- hook(list(params = list(query = "nope", idType = "AnyId"))),
    "No chemicals could be resolved"
  )
  expect_true(data$skip_request)
  expect_null(data$result)
})

test_that("resolve_smiles_identifier leaves normal SMILES unchanged", {
  hook <- get("resolve_smiles_identifier", envir = asNamespace("ComptoxR"))
  called <- FALSE

  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      called <<- TRUE
      list()
    },
    .package = "ComptoxR"
  )

  data <- hook(list(params = list(smiles = "CCCC")))

  expect_identical(data$params$smiles, "CCCC")
  expect_false(called)
})

test_that("resolve_smiles_identifier resolves DTXSID input to canonical SMILES", {
  hook <- get("resolve_smiles_identifier", envir = asNamespace("ComptoxR"))

  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(ids, idsType, tidy) {
      expect_identical(ids, "DTXSID7020182")
      expect_identical(idsType, "AnyId")
      expect_false(tidy)
      list(list(
        result = "FOUND",
        chemical = list(canonicalSmiles = "c1ccccc1")
      ))
    },
    .package = "ComptoxR"
  )

  data <- hook(list(params = list(smiles = "DTXSID7020182")))

  expect_identical(data$params$smiles, "c1ccccc1")
})

test_that("resolve_smiles_identifier errors when identifier cannot resolve", {
  hook <- get("resolve_smiles_identifier", envir = asNamespace("ComptoxR"))

  local_mocked_bindings(
    chemi_resolver_lookup_bulk = function(...) {
      list(list(result = "NOT_FOUND"))
    },
    .package = "ComptoxR"
  )

  expect_error(
    hook(list(params = list(smiles = "DTXSID7020182"))),
    "Unable to resolve chemical identifier"
  )
})
