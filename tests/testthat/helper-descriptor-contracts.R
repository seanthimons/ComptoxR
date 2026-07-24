descriptor_contract_response <- function(
  records = list(),
  headers = character(),
  extra = list()
) {
  body <- c(extra, list(chemicals = records))
  if (length(headers) > 0) {
    body$headers <- headers
  }
  body
}

descriptor_contract_record <- function(
  smiles = "CCO",
  descriptors = c(1, 2),
  ordinal = NULL,
  id = NULL
) {
  record <- list(
    smiles = smiles,
    inchi = "InChI=1S/C2H6O",
    inchiKey = "LFQSCWFLJHTTHZ-UHFFFAOYSA-N",
    descriptors = descriptors
  )
  if (!is.null(ordinal)) {
    record$ordinal <- ordinal
  }
  if (!is.null(id)) {
    record$id <- id
  }
  record
}

webtest_contract_prediction <- function(
  chemical_id = "DTXSID7020182",
  smiles = "resolved-smiles"
) {
  list(
    chemicalId = chemical_id,
    chemical = list(
      sid = chemical_id,
      smiles = smiles,
      inchi = "InChI=mock",
      inchiKey = "MOCK-INCHI-KEY"
    ),
    endpoints = list(
      list(
        endpoint = list(
          id = "LC50",
          name = "Fathead minnow LC50 (96 hr)",
          units = "mg/L",
          logUnits = "-Log10(mol/L)"
        ),
        experimental = list(list(value = 4.651, logValue = 4.691)),
        predicted = list(
          list(method = "consensus", value = 3.241, logValue = 4.848),
          list(method = "hc", value = 4.151, logValue = 4.740)
        )
      ),
      list(
        endpoint = list(id = "LD50", name = "Oral rat LD50", units = "mg/kg"),
        predicted = list(list(method = "consensus", value = 100))
      )
    )
  )
}
