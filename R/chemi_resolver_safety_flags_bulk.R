#' Resolver Safety Flags
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param additionalProps Chemical metadata map. Supply a nonempty map together with the chemical fields.
#' @param averageMass Optional parameter
#' @param canonicalSmiles Optional parameter
#' @param casrn Optional parameter
#' @param chemId Optional parameter
#' @param cid Optional parameter
#' @param id Optional parameter
#' @param image Optional parameter
#' @param inchi Optional parameter
#' @param inchiKey Optional parameter
#' @param mol Optional parameter
#' @param molFormula Optional parameter
#' @param monoisotopicMass Optional parameter
#' @param name Optional parameter
#' @param sid Optional parameter
#' @param smiles Optional parameter
#' @param request.filesInfo Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags_bulk(additionalProps = list(source = "ComptoxR"), sid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_safety_flags_bulk <- function(
  additionalProps = NULL,
  averageMass = NULL,
  canonicalSmiles = NULL,
  casrn = NULL,
  chemId = NULL,
  cid = NULL,
  id = NULL,
  image = NULL,
  inchi = NULL,
  inchiKey = NULL,
  mol = NULL,
  molFormula = NULL,
  monoisotopicMass = NULL,
  name = NULL,
  sid = NULL,
  smiles = NULL,
  request.filesInfo = NULL
) {
  params <- base::list(
    "additionalProps" = function() additionalProps,
    "averageMass" = function() averageMass,
    "canonicalSmiles" = function() canonicalSmiles,
    "casrn" = function() casrn,
    "chemId" = function() chemId,
    "cid" = function() cid,
    "id" = function() id,
    "image" = function() image,
    "inchi" = function() inchi,
    "inchiKey" = function() inchiKey,
    "mol" = function() mol,
    "molFormula" = function() molFormula,
    "monoisotopicMass" = function() monoisotopicMass,
    "name" = function() name,
    "sid" = function() sid,
    "smiles" = function() smiles,
    "request.filesInfo" = function() request.filesInfo
  )
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/resolver/safety-flags",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      body <- base::list(
        averageMass = params[["averageMass"]](),
        canonicalSmiles = params[["canonicalSmiles"]](),
        casrn = params[["casrn"]](),
        chemId = params[["chemId"]](),
        cid = params[["cid"]](),
        id = params[["id"]](),
        image = params[["image"]](),
        inchi = params[["inchi"]](),
        inchiKey = params[["inchiKey"]](),
        mol = params[["mol"]](),
        molFormula = params[["molFormula"]](),
        monoisotopicMass = params[["monoisotopicMass"]](),
        name = params[["name"]](),
        sid = params[["sid"]](),
        smiles = params[["smiles"]](),
        additionalProps = params[["additionalProps"]]()
      )
      value <- unique(as.vector(body[["additionalProps"]]))
      value <- value[!is.na(value) & value != ""]
      if (!length(value)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      body <- base::Filter(base::Negate(base::is.null), body)
      body <- .api_validation$body_value(
        body,
        structure(
          list(
            properties = list(
              additionalProps = list(additionalProperties = structure(list(), names = character(0)), type = "object"),
              averageMass = list(format = "double", type = "number"),
              canonicalSmiles = list(type = "string"),
              casrn = list(type = "string"),
              chemId = list(type = "string"),
              cid = list(type = "string"),
              id = list(type = "string"),
              image = list(type = "string"),
              inchi = list(type = "string"),
              inchiKey = list(type = "string"),
              mol = list(
                type = "string"
              ),
              molFormula = list(type = "string"),
              monoisotopicMass = list(format = "double", type = "number"),
              name = list(type = "string"),
              sid = list(type = "string"),
              smiles = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/Chemical"
        )
      )
      if (TRUE) {
        list(body)
      } else {
        body
      }
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "resolver/safety-flags"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
