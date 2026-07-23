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
      withr::local_envvar(chemi_burl = "https://cim.sciencedataexperts.com/api")
      captured <- NULL
      local_mocked_bindings(
        chemi_resolver_lookup_bulk = function(...) {
          list(list(
            result = "FOUND",
            chemical = list(canonicalSmiles = "c1ccccc1")
          ))
        },
        descriptor_perform_request = function(spec) {
          captured <<- spec
          descriptor_contract_response(
            records = list(descriptor_contract_record(
              smiles = "c1ccccc1",
              descriptors = if (identical(spec$engine, "rdkit")) 1:1024 else c(1, 2)
            )),
            headers = if (identical(spec$engine, "rdkit")) character() else c("a", "b")
          )
        },
        .package = "ComptoxR"
      )

      get(nm, envir = asNamespace("ComptoxR"))(smiles = "DTXSID7020182")

      expect_identical(captured$query$smiles, "c1ccccc1")
      expect_false(identical(captured$query$smiles, "DTXSID7020182"))
    })
  })
}
