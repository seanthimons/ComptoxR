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
      withr::local_envvar(chemi_burl = "https://configured.example/api")
      captured <- NULL
      local_mocked_bindings(
        chemi_resolver_lookup_bulk = function(...) {
          list(list(
            result = "FOUND",
            chemical = list(canonicalSmiles = "c1ccccc1")
          ))
        },
        .package = "ComptoxR"
      )
      local_mocked_bindings(
        req_perform = function(req, ...) {
          captured <<- httr2::url_parse(req$url)$query
          payload <- descriptor_contract_response(
            records = list(descriptor_contract_record(
              smiles = "c1ccccc1",
              descriptors = if (identical(nm, "chemi_rdkit")) 1:1024 else c(1, 2)
            )),
            headers = if (identical(nm, "chemi_rdkit")) character() else c("a", "b")
          )
          httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"),
            body = charToRaw(jsonlite::toJSON(payload, auto_unbox = TRUE)))
        },
        .package = "httr2"
      )

      get(nm, envir = asNamespace("ComptoxR"))(smiles = "DTXSID7020182")

      expect_identical(captured$smiles, "c1ccccc1")
      expect_false(identical(captured$smiles, "DTXSID7020182"))
    })
  })
}
