#' Stdizer
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param workflow Required parameter
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer(workflow = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_stdizer <- function(workflow, smiles) {
  params <- list("workflow" = workflow, "smiles" = smiles)
  result <- generic_request(
    "endpoint" = "stdizer",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("workflow" = params[["workflow"]], "smiles" = params[["smiles"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}

#' Stdizer
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param request.filesInfo Optional parameter
#' @param request.options.recordId Optional parameter
#' @param request.options.run Optional parameter
#' @param request.options.workflow Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_bulk(request.filesInfo = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_stdizer_bulk <- function(
  request.filesInfo = NULL,
  request.options.recordId = NULL,
  request.options.run = NULL,
  request.options.workflow = NULL
) {
  params <- list(
    "request.filesInfo" = request.filesInfo,
    "request.options.recordId" = request.options.recordId,
    "request.options.run" = request.options.run,
    "request.options.workflow" = request.options.workflow
  )
  result <- generic_chemi_request(
    "endpoint" = "stdizer",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "request.filesInfo" = params[["request.filesInfo"]],
          "request.options.recordId" = params[["request.options.recordId"]],
          "request.options.run" = params[["request.options.run"]],
          "request.options.workflow" = params[["request.options.workflow"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
