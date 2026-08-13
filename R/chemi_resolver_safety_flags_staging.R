#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param additionalProps Optional parameter
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
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags_bulk_staging(additionalProps = "DTXSID1024122")
#' }
chemi_resolver_safety_flags_bulk_staging <- function(
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
  smiles = NULL
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_resolver_safety_flags_bulk_staging",
    "pre_request",
    list(
      params = list(
        `additionalProps` = additionalProps,
        `averageMass` = averageMass,
        `canonicalSmiles` = canonicalSmiles,
        `casrn` = casrn,
        `chemId` = chemId,
        `cid` = cid,
        `id` = id,
        `image` = image,
        `inchi` = inchi,
        `inchiKey` = inchiKey,
        `mol` = mol,
        `molFormula` = molFormula,
        `monoisotopicMass` = monoisotopicMass,
        `name` = name,
        `sid` = sid,
        `smiles` = smiles,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("additionalProps" %in% names(req_data$params)) {
    additionalProps <- req_data$params[["additionalProps"]]
  }
  if ("averageMass" %in% names(req_data$params)) {
    averageMass <- req_data$params[["averageMass"]]
  }
  if ("canonicalSmiles" %in% names(req_data$params)) {
    canonicalSmiles <- req_data$params[["canonicalSmiles"]]
  }
  if ("casrn" %in% names(req_data$params)) {
    casrn <- req_data$params[["casrn"]]
  }
  if ("chemId" %in% names(req_data$params)) {
    chemId <- req_data$params[["chemId"]]
  }
  if ("cid" %in% names(req_data$params)) {
    cid <- req_data$params[["cid"]]
  }
  if ("id" %in% names(req_data$params)) {
    id <- req_data$params[["id"]]
  }
  if ("image" %in% names(req_data$params)) {
    image <- req_data$params[["image"]]
  }
  if ("inchi" %in% names(req_data$params)) {
    inchi <- req_data$params[["inchi"]]
  }
  if ("inchiKey" %in% names(req_data$params)) {
    inchiKey <- req_data$params[["inchiKey"]]
  }
  if ("mol" %in% names(req_data$params)) {
    mol <- req_data$params[["mol"]]
  }
  if ("molFormula" %in% names(req_data$params)) {
    molFormula <- req_data$params[["molFormula"]]
  }
  if ("monoisotopicMass" %in% names(req_data$params)) {
    monoisotopicMass <- req_data$params[["monoisotopicMass"]]
  }
  if ("name" %in% names(req_data$params)) {
    name <- req_data$params[["name"]]
  }
  if ("sid" %in% names(req_data$params)) {
    sid <- req_data$params[["sid"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(averageMass)) {
    options$averageMass <- averageMass
  }
  if (!is.null(canonicalSmiles)) {
    options$canonicalSmiles <- canonicalSmiles
  }
  if (!is.null(casrn)) {
    options$casrn <- casrn
  }
  if (!is.null(chemId)) {
    options$chemId <- chemId
  }
  if (!is.null(cid)) {
    options$cid <- cid
  }
  if (!is.null(id)) {
    options$id <- id
  }
  if (!is.null(image)) {
    options$image <- image
  }
  if (!is.null(inchi)) {
    options$inchi <- inchi
  }
  if (!is.null(inchiKey)) {
    options$inchiKey <- inchiKey
  }
  if (!is.null(mol)) {
    options$mol <- mol
  }
  if (!is.null(molFormula)) {
    options$molFormula <- molFormula
  }
  if (!is.null(monoisotopicMass)) {
    options$monoisotopicMass <- monoisotopicMass
  }
  if (!is.null(name)) {
    options$name <- name
  }
  if (!is.null(sid)) {
    options$sid <- sid
  }
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  result <- generic_chemi_request(
    query = additionalProps,
    endpoint = "resolver/safety-flags",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
