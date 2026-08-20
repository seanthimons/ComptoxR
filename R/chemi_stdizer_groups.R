#' Stdizer Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups()
#' }
chemi_stdizer_groups <- function() {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_stdizer_groups", "pre_request", list(params = list(`server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    endpoint = "stdizer/groups",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}

#' Stdizer Groups
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param acl Optional parameter
#' @param description Optional parameter
#' @param flag Optional parameter
#' @param frozen Optional parameter
#' @param id Optional parameter
#' @param invalid Optional parameter
#' @param invalidMessage Optional parameter
#' @param operations Optional parameter
#' @param text Optional parameter
#' @param type Optional parameter. Options: METHOD, SMIRKS, SMILES, SMARTS, GROUP, REFERENCE
#' @param value Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.replace Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_bulk(acl = "DTXSID1024122")
#' }
chemi_stdizer_groups_bulk <- function(
  acl = NULL,
  description = NULL,
  flag = NULL,
  frozen = NULL,
  id = NULL,
  invalid = NULL,
  invalidMessage = NULL,
  operations = NULL,
  text = NULL,
  type = NULL,
  value = NULL,
  request.filesInfo = NULL,
  request.replace = NULL
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_stdizer_groups_bulk",
    "pre_request",
    list(
      params = list(
        `acl` = acl,
        `description` = description,
        `flag` = flag,
        `frozen` = frozen,
        `id` = id,
        `invalid` = invalid,
        `invalidMessage` = invalidMessage,
        `operations` = operations,
        `text` = text,
        `type` = type,
        `value` = value,
        `request.filesInfo` = request.filesInfo,
        `request.replace` = request.replace,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("acl" %in% names(req_data$params)) {
    acl <- req_data$params[["acl"]]
  }
  if ("description" %in% names(req_data$params)) {
    description <- req_data$params[["description"]]
  }
  if ("flag" %in% names(req_data$params)) {
    flag <- req_data$params[["flag"]]
  }
  if ("frozen" %in% names(req_data$params)) {
    frozen <- req_data$params[["frozen"]]
  }
  if ("id" %in% names(req_data$params)) {
    id <- req_data$params[["id"]]
  }
  if ("invalid" %in% names(req_data$params)) {
    invalid <- req_data$params[["invalid"]]
  }
  if ("invalidMessage" %in% names(req_data$params)) {
    invalidMessage <- req_data$params[["invalidMessage"]]
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
  if ("request.filesInfo" %in% names(req_data$params)) {
    request.filesInfo <- req_data$params[["request.filesInfo"]]
  }
  if ("request.replace" %in% names(req_data$params)) {
    request.replace <- req_data$params[["request.replace"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(description)) {
    options$description <- description
  }
  if (!is.null(flag)) {
    options$flag <- flag
  }
  if (!is.null(frozen)) {
    options$frozen <- frozen
  }
  if (!is.null(id)) {
    options$id <- id
  }
  if (!is.null(invalid)) {
    options$invalid <- invalid
  }
  if (!is.null(invalidMessage)) {
    options$invalidMessage <- invalidMessage
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
    query = acl,
    endpoint = "stdizer/groups",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
