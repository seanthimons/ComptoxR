#' Run CTS Metabolizer
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Runs CTS metabolizer transformation tree prediction. Identifier inputs are
#' resolved to one SMILES string per query by default.
#'
#' @param query Chemical identifier or SMILES string.
#' @param id_type Identifier type passed to `chemi_resolver_lookup()`. Defaults
#'   to `"AnyId"`.
#' @param generation_limit Number of transformation generations to request.
#'   Defaults to `1`.
#' @param transformation_libraries Character vector of CTS transformation
#'   libraries. Defaults to `"hydrolysis"`.
#' @param resolve Logical; if `TRUE`, resolve `query` through
#'   `chemi_resolver_lookup()`. If `FALSE`, treat `query` as SMILES.
#' @param tidy Logical; if `TRUE`, flatten the metabolizer tree to a tibble.
#'   Defaults to `FALSE`, returning the parsed nested CTS response unchanged.
#'
#' @return Parsed CTS response when `tidy = FALSE`; a flattened tibble when
#'   `tidy = TRUE`.
#' @export
#'
#' @examples
#' \dontrun{
#' cts_metabolizer_run("DTXSID7020182")
#' cts_metabolizer_run("CCCC", resolve = FALSE, tidy = TRUE)
#' }
cts_metabolizer_run <- function(query, id_type = "AnyId", generation_limit = 1,
                                transformation_libraries = "hydrolysis",
                                resolve = TRUE, tidy = FALSE) {
  if (length(generation_limit) != 1 || is.na(generation_limit)) {
    cli::cli_abort("{.arg generation_limit} must be a single non-missing value.")
  }

  transformation_libraries <- as.character(transformation_libraries)
  transformation_libraries <- transformation_libraries[
    !is.na(transformation_libraries) & nzchar(transformation_libraries)
  ]

  if (length(transformation_libraries) == 0) {
    cli::cli_abort("{.arg transformation_libraries} must contain at least one value.")
  }

  smiles <- cts_resolve_smiles(query, id_type = id_type, resolve = resolve)

  results <- purrr::imap(smiles, function(smiles_one, query_one) {
    body <- list(
      structure = smiles_one,
      generationLimit = as.integer(generation_limit),
      transformationLibraries = as.list(transformation_libraries)
    )

    response <- generic_cts_request(
      endpoint = "metabolizer/run",
      body = body,
      method = "POST",
      tidy = FALSE
    )

    if (isTRUE(tidy)) {
      cts_flatten_metabolizer_tree(response, query = query_one)
    } else {
      response
    }
  })

  if (isTRUE(tidy)) {
    return(purrr::list_rbind(results))
  }

  if (length(results) == 1) {
    return(results[[1]])
  }

  results
}
