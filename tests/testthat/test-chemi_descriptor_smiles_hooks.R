if (!exists("generated_contract_ensure_package", mode = "function")) {
  source(file.path("tests", "testthat", "helper-generated-contracts.R"))
}
generated_contract_ensure_package()

descriptor_smiles_wrappers <- c(
  "chemi_padel",
  "chemi_rdkit",
  "chemi_mordred",
  "chemi_webtest"
)

for (wrapper_name in descriptor_smiles_wrappers) {
  local({
    nm <- wrapper_name

    test_that(paste0(nm, " resolves identifier-like smiles before helper options"), {
      captured <- NULL
      local_mocked_bindings(
        chemi_resolver_lookup_bulk = function(...) {
          list(list(
            result = "FOUND",
            chemical = list(canonicalSmiles = "c1ccccc1")
          ))
        },
        generic_request = function(...) {
          captured <<- list(...)
          list()
        },
        .package = "ComptoxR"
      )

      get(nm, envir = asNamespace("ComptoxR"))(smiles = "DTXSID7020182")

      expect_identical(captured$options$smiles, "c1ccccc1")
      expect_false(identical(captured$options$smiles, "DTXSID7020182"))
    })
  })
}
