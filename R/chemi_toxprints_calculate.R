#' Toxprints Calculate
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles Required parameter
#' @param labels Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return A list of decoded response records.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate(smiles = "CCCC")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_calculate <- function(smiles, labels = FALSE, profile = NULL) {
  params <- base::list("smiles" = smiles, "labels" = labels, "profile" = profile)
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/toxprints/calculate",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list("smiles" = params[["smiles"]], "labels" = params[["labels"]], "profile" = params[["profile"]]),
    "body" = NULL,
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      .ct_static_json_result(response, context, decode, "toxprints/calculate")
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
