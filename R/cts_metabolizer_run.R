#' Predict CTS transformation products
#'
#' @noMd
#' @param body A named list with one SMILES string or DTXSID in `structure`, an integer `generationLimit`, and one reaction library in `transformationLibraries`. The wrapper resolves DTXSIDs to SMILES.
#' @return A list containing CTS metadata and calculation data. The product tree is in `data$data`. CTS calculation failures raise an error.
#' @export
#' @examples
#' \dontrun{
#' cts_metabolizer_run(body = list(structure = "CC(=O)Oc1ccccc1C(=O)O", generationLimit = 4L, transformationLibraries = list("hydrolysis")))
#' }
# Generated with specmill; do not edit by hand.
cts_metabolizer_run <- function(body) {
  body <- base::get(
    ".cts_resolve_structure",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(body)
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(
        body,
        structure(
          list(
            type = "object",
            properties = list(
              structure = list(type = "string", description = "Chemical for metabolizer in smiles format."),
              generationLimit = list(
                type = "integer",
                description = "Number of generations for structure's transformation products."
              ),
              transformationLibraries = list(
                type = "array",
                items = list(type = "string"),
                minItems = 1L,
                maxItems = 1L
              )
            ),
            required = list("structure", "generationLimit", "transformationLibraries")
          ),
          specmill_id = "#/components/schemas/MetabolizerInputs"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/metabolizer/run",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    response_policy = ".cts_check_calculation",
    server = list(url = "https://qed.epa.gov/cts/rest"),
    auth = list()
  )
  result
}
