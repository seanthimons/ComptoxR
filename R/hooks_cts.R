.cts_resolve_structure <- function(body) {
  if (!is.list(body)) {
    return(body)
  }
  structure <- body[["structure"]]
  if (
    !is.character(structure) ||
      length(structure) != 1L ||
      is.na(structure) ||
      !grepl("^DTXSID[0-9]+$", trimws(structure), ignore.case = TRUE)
  ) {
    return(body)
  }

  sid <- toupper(trimws(structure))
  records <- chemi_resolver_lookup_bulk(ids = sid, idsType = "DTXSID", tidy = FALSE)
  smiles <- unique(vapply(records, descriptor_resolved_smiles, character(1)))
  smiles <- smiles[!is.na(smiles) & nzchar(smiles)]
  if (length(smiles) != 1L) {
    cli::cli_abort(
      "CTS requires one SMILES for {.val {sid}}. The resolver returned {length(smiles)} distinct structures."
    )
  }

  body[["structure"]] <- smiles[[1L]]
  body
}

.cts_check_calculation <- function(response, context, decode) {
  result <- decode()
  if (is.list(result) && is.list(result[["data"]])) {
    failure <- result[["data"]][["error"]]
    if (is.character(failure) && length(failure) == 1L && !is.na(failure) && nzchar(failure)) {
      cli::cli_abort("CTS calculation failed: {failure}", class = "comptoxr_cts_calculation_error")
    }
  }
  result
}
