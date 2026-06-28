#' Run metabolizer calculator for p-chem data.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param structure Chemical for metabolizer in smiles format. (default: CCCC)
#' @param generationLimit Number of generations for structure's transformation products. (default: 1)
#' @param transformationLibraries Optional parameter (default: hydrolysis)
#' @param resolve Logical; whether to resolve identifiers to SMILES before submitting to CTS. Defaults to `FALSE`.
#' @param id_type Identifier type passed to the resolver when `resolve = TRUE`.
#' @param tidy Logical; whether to flatten the CTS metabolizer tree into a tibble.
#' @return Returns a list with result object, or a tibble when `tidy = TRUE`.
#' @export
#'
#' @examples
#' \dontrun{
#' cts_metabolizer_run(structure = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
cts_metabolizer_run <- function(
  structure = "CCCC",
  generationLimit = 1L,
  transformationLibraries = list("hydrolysis"),
  resolve = FALSE,
  id_type = "AnyId",
  tidy = FALSE
) {
  structures <- cts_resolve_smiles(structure, id_type = id_type, resolve = resolve)

  results <- purrr::imap(structures, function(smiles, query) {
    body <- list(
      structure = smiles,
      generationLimit = generationLimit,
      transformationLibraries = transformationLibraries
    )
    body <- purrr::compact(body)

    result <- generic_cts_request(
      endpoint = "metabolizer/run",
      body = body,
      method = "POST",
      tidy = FALSE
    )

    if (isTRUE(tidy)) {
      return(cts_flatten_metabolizer_tree(result, query = query))
    }

    result
  })

  if (isTRUE(tidy)) {
    return(purrr::list_rbind(results))
  }

  if (length(results) == 1L) {
    return(results[[1L]])
  }

  results
}
