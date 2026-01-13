# Quick test to show what chemi_endpoint_eval generates

library(glue)

# Example of what a generated chemi function stub looks like

example_query <- "DTXSID7020182"
fn <- "chemi_toxprints_calculate"
endpoint <- "api/toxprints/calculate"
title <- "Calculate toxprints for chemicals"

# For a function with optional parameters (smiles, labels, profile)
param_info <- list(
  fn_signature = "query, smiles = NULL, labels = NULL, profile = NULL",
  param_docs = "#' @param smiles Optional parameter\n#' @param labels Optional parameter\n#' @param profile Optional parameter\n",
  extra_params_code = "  # Collect optional parameters\n  options <- list()\n  if (!is.null(smiles)) options$smiles <- smiles\n  if (!is.null(labels)) options$labels <- labels\n  if (!is.null(profile)) options$profile <- profile\n\n  ",
  extra_params_call = ",\n    options = options",
  has_params = TRUE
)

stub_text <- glue("
#' {title}
#'
#' @description
#' `r lifecycle::badge(\\\"experimental\\\")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
{param_info$param_docs}
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \\\\\\\\dontrun{{
#' {fn}(query = \\\"{example_query}\\\")
#' }}
{fn} <- function({param_info$fn_signature}) {{
{param_info$extra_params_code}generic_chemi_request(
    query = query,
    endpoint = \\\"{endpoint}\\\",
    server = \\\"chemi_burl\\\",
    auth = FALSE{param_info$extra_params_call}
  )
}}
")

cat(stub_text)
