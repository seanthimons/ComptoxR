# Shared helpers for generated offline wrapper contract tests.

generated_contract_package_root <- function(package = "ComptoxR") {
  candidates <- c(".", "../..", "../../..")

  if (requireNamespace("here", quietly = TRUE)) {
    candidates <- c(candidates, here::here())
  }

  for (candidate in unique(candidates)) {
    description <- file.path(candidate, "DESCRIPTION")
    if (!file.exists(description)) {
      next
    }

    package_name <- tryCatch(
      read.dcf(description, fields = "Package")[[1]],
      error = function(e) NA_character_
    )
    if (identical(package_name, package)) {
      return(normalizePath(candidate, winslash = "/", mustWork = TRUE))
    }
  }

  NULL
}

generated_contract_ensure_package <- function(package = "ComptoxR") {
  root <- generated_contract_package_root(package)
  if (requireNamespace("pkgload", quietly = TRUE) && !is.null(root)) {
    suppressPackageStartupMessages(pkgload::load_all(root, quiet = TRUE))
    return(invisible(package))
  }

  if (paste0("package:", package) %in% search()) {
    return(invisible(package))
  }

  suppressPackageStartupMessages(library(package, character.only = TRUE))
  invisible(package)
}

generated_contract_response <- function(...) {
  tibble::tibble(
    count = 1L,
    results = list(list(name = "Mock chemical", rn = "80-05-7")),
    data = list(list(dtxsid = "DTXSID7020182", relationship = "mock")),
    sid = "DTXSID7020182",
    dtxsid = "DTXSID7020182",
    query = "DTXSID7020182",
    result = "FOUND",
    value = "mock",
    chemical = list(list(
      name = "Mock chemical",
      chemId = "DTXSID7020182",
      sid = "DTXSID7020182",
      canonicalSmiles = "CCCC",
      smiles = "CCCC",
      casrn = "80-05-7",
      inchi = "InChI=1S/C4H10/c1-3-4-2/h3-4H2,1-2H3",
      inchiKey = "IJDNQMDRQITEOD-UHFFFAOYSA-N",
      flags = list(),
      NFPA = list(),
      `GHS Codes` = list()
    ))
  )
}

generated_contract_resolver_lookup <- function(query, idType = "AnyId", mol = FALSE, ...) {
  tibble::tibble(
    query = query,
    dtxsid = "DTXSID7020182",
    sid = "DTXSID7020182",
    result = "FOUND",
    smiles = "CCCC",
    chemical = list(list(
      name = "Mock chemical",
      chemId = "DTXSID7020182",
      sid = "DTXSID7020182",
      canonicalSmiles = "CCCC",
      smiles = "CCCC",
      casrn = "80-05-7",
      inchi = "InChI=1S/C4H10/c1-3-4-2/h3-4H2,1-2H3",
      inchiKey = "IJDNQMDRQITEOD-UHFFFAOYSA-N"
    ))
  )
}

generated_contract_resolver_lookup_bulk <- function(ids, idsType = "AnyId", tidy = FALSE, ...) {
  lapply(ids, function(id) {
    list(
      query = id,
      result = "FOUND",
      chemical = list(
        name = "Mock chemical",
        chemId = "DTXSID7020182",
        sid = "DTXSID7020182",
        canonicalSmiles = "CCCC",
        smiles = "CCCC",
        casrn = "80-05-7",
        inchi = "InChI=1S/C4H10/c1-3-4-2/h3-4H2,1-2H3",
        inchiKey = "IJDNQMDRQITEOD-UHFFFAOYSA-N"
      )
    )
  })
}
