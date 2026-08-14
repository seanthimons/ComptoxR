#' Alerts Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param aux Optional parameter
#' @param description Optional parameter
#' @param frozen Optional parameter
#' @param id Optional parameter
#' @param logicType Optional parameter. Options: NONE, OR, AND, NOT
#' @param name Optional parameter
#' @param operations Optional parameter
#' @param text Optional parameter
#' @param type Optional parameter. Options: METHOD, SMILES, SMARTS, TOXPRINT, HAZARD, PROPERTY, GROUP, REFERENCE
#' @param value Optional parameter
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_alerts_groups_bulk_staging(aux = "DTXSID1024122")
#' }
chemi_alerts_groups_bulk_staging <- function(
  aux = NULL,
  description = NULL,
  frozen = NULL,
  id = NULL,
  logicType = NULL,
  name = NULL,
  operations = NULL,
  text = NULL,
  type = NULL,
  value = NULL
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_alerts_groups_bulk_staging",
    "pre_request",
    list(
      params = list(
        `aux` = aux,
        `description` = description,
        `frozen` = frozen,
        `id` = id,
        `logicType` = logicType,
        `name` = name,
        `operations` = operations,
        `text` = text,
        `type` = type,
        `value` = value,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("aux" %in% names(req_data$params)) {
    aux <- req_data$params[["aux"]]
  }
  if ("description" %in% names(req_data$params)) {
    description <- req_data$params[["description"]]
  }
  if ("frozen" %in% names(req_data$params)) {
    frozen <- req_data$params[["frozen"]]
  }
  if ("id" %in% names(req_data$params)) {
    id <- req_data$params[["id"]]
  }
  if ("logicType" %in% names(req_data$params)) {
    logicType <- req_data$params[["logicType"]]
  }
  if ("name" %in% names(req_data$params)) {
    name <- req_data$params[["name"]]
  }
  if ("operations" %in% names(req_data$params)) {
    operations <- req_data$params[["operations"]]
  }
  if ("text" %in% names(req_data$params)) {
    text <- req_data$params[["text"]]
  }
  if ("type" %in% names(req_data$params)) {
    type <- req_data$params[["type"]]
  }
  if ("value" %in% names(req_data$params)) {
    value <- req_data$params[["value"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(description)) {
    options$description <- description
  }
  if (!is.null(frozen)) {
    options$frozen <- frozen
  }
  if (!is.null(id)) {
    options$id <- id
  }
  if (!is.null(logicType)) {
    options$logicType <- logicType
  }
  if (!is.null(name)) {
    options$name <- name
  }
  if (!is.null(operations)) {
    options$operations <- operations
  }
  if (!is.null(text)) {
    options$text <- text
  }
  if (!is.null(type)) {
    options$type <- type
  }
  if (!is.null(value)) {
    options$value <- value
  }
  result <- generic_chemi_request(
    query = aux,
    endpoint = "alerts/groups",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
