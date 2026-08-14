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

test_that("flatten_similarity_map_chemicals unwraps Chemical records", {
  hook <- get("flatten_similarity_map_chemicals", envir = asNamespace("ComptoxR"))
  data <- hook(list(
    params = list(
      chemicals = list(
        list(chemical = list(sid = "DTXSID-A", name = "A")),
        list(chemical = list(sid = "DTXSID-B", name = "B"))
      )
    )
  ))

  expect_identical(data$params$chemicals[[1]]$sid, "DTXSID-A")
  expect_null(data$params$chemicals[[1]]$chemical)
})

similarity_map_payload <- function() {
  list(
    order = list(
      list(chemical = list(sid = "DTXSID-A", name = "A")),
      list(chemical = list(name = "B"))
    ),
    similarity = list(
      list(list(sim = 0), list(sim = 0.25, cl = "low")),
      list(list(sim = 0.25, cl = "low"), list(sim = 0))
    )
  )
}

test_that("format_similarity_map_result returns cluster, long, and raw outputs", {
  hook <- get("format_similarity_map_result", envir = asNamespace("ComptoxR"))
  payload <- similarity_map_payload()

  cluster <- hook(list(
    result = payload,
    params = list(format = "cluster", hclust_method = "single")
  ))
  long <- hook(list(
    result = payload,
    params = list(format = "long", hclust_method = "complete")
  ))

  expect_identical(cluster$mol_names$dtxsid, c("DTXSID-A", NA_character_))
  expect_identical(
    cluster$similarity,
    matrix(
      c(0, 0.25, 0.25, 0),
      nrow = 2,
      byrow = TRUE,
      dimnames = list(c("DTXSID-A", "B"), c("DTXSID-A", "B"))
    )
  )
  expect_identical(cluster$hc$method, "single")
  expect_named(long, c("parent", "child", "value"))
  expect_equal(nrow(long), 2L)
  expect_identical(long$parent, c("DTXSID-A", "B"))
  expect_identical(long$child, c("B", "DTXSID-A"))
  expect_identical(
    hook(list(result = payload, params = list(format = "raw"))),
    payload
  )
})

test_that("similarity_map_long preserves row-major values and duplicate labels", {
  format_long <- get("similarity_map_long", envir = asNamespace("ComptoxR"))
  similarity <- matrix(
    1:9,
    nrow = 3,
    byrow = TRUE,
    dimnames = list(c("A", "A", "C"), c("A", "A", "C"))
  )

  result <- format_long(list(similarity = similarity))

  expect_identical(result$parent, c("A", "A", "A", "A", "C", "C"))
  expect_identical(result$child, c("A", "C", "A", "C", "A", "A"))
  expect_identical(result$value, c(2L, 3L, 4L, 6L, 7L, 8L))
})

test_that("format_similarity_map_result preserves true zero similarities", {
  hook <- get("format_similarity_map_result", envir = asNamespace("ComptoxR"))
  payload <- list(
    order = purrr::map(
      c("A", "B", "C"),
      ~ list(chemical = list(name = .x))
    ),
    similarity = list(
      list(list(sim = 0), list(sim = 0), list(sim = 0.9)),
      list(list(sim = 0), list(sim = 0), list(sim = 0.1)),
      list(list(sim = 0.9), list(sim = 0.1), list(sim = 0))
    )
  )

  result <- hook(list(
    result = payload,
    params = list(format = "cluster", hclust_method = "complete")
  ))

  expect_true(is.matrix(result$similarity))
  expect_equal(result$similarity[1, 2], 0)
  expect_equal(sort(result$hc$merge[1, ]), c(-3, -1))
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
