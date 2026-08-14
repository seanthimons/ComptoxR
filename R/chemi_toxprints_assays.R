#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param category Optional parameter
#' @param label Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays(category = "DTXSID7020182")
#' }
chemi_toxprints_assays <- function(category = NULL, label = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_toxprints_assays",
    "pre_request",
    list(params = list(`category` = category, `label` = label, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("category" %in% names(req_data$params)) {
    category <- req_data$params[["category"]]
  }
  if ("label" %in% names(req_data$params)) {
    label <- req_data$params[["label"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(category)) {
    options[['category']] <- category
  }
  if (!is.null(label)) {
    options[['label']] <- label
  }
  result <- generic_request(
    endpoint = "toxprints/assays",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}

#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param acl Optional parameter
#' @param actives Optional parameter
#' @param category Optional parameter
#' @param chemicals Optional parameter
#' @param id Optional parameter
#' @param labels Optional parameter
#' @param metrics Optional parameter
#' @param name Optional parameter
#' @param options Optional parameter
#' @param total Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_bulk(acl = "DTXSID1024122")
#' }
chemi_toxprints_assays_bulk <- function(
  acl = NULL,
  actives = NULL,
  category = NULL,
  chemicals = NULL,
  id = NULL,
  labels = NULL,
  metrics = NULL,
  name = NULL,
  options = NULL,
  total = NULL
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_toxprints_assays_bulk",
    "pre_request",
    list(
      params = list(
        `acl` = acl,
        `actives` = actives,
        `category` = category,
        `chemicals` = chemicals,
        `id` = id,
        `labels` = labels,
        `metrics` = metrics,
        `name` = name,
        `options` = options,
        `total` = total,
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
  if ("actives" %in% names(req_data$params)) {
    actives <- req_data$params[["actives"]]
  }
  if ("category" %in% names(req_data$params)) {
    category <- req_data$params[["category"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("id" %in% names(req_data$params)) {
    id <- req_data$params[["id"]]
  }
  if ("labels" %in% names(req_data$params)) {
    labels <- req_data$params[["labels"]]
  }
  if ("metrics" %in% names(req_data$params)) {
    metrics <- req_data$params[["metrics"]]
  }
  if ("name" %in% names(req_data$params)) {
    name <- req_data$params[["name"]]
  }
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("total" %in% names(req_data$params)) {
    total <- req_data$params[["total"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(actives)) {
    options$actives <- actives
  }
  if (!is.null(category)) {
    options$category <- category
  }
  if (!is.null(chemicals)) {
    options$chemicals <- chemicals
  }
  if (!is.null(id)) {
    options$id <- id
  }
  if (!is.null(labels)) {
    options$labels <- labels
  }
  if (!is.null(metrics)) {
    options$metrics <- metrics
  }
  if (!is.null(name)) {
    options$name <- name
  }
  if (!is.null(options)) {
    options$options <- options
  }
  if (!is.null(total)) {
    options$total <- total
  }
  result <- generic_chemi_request(
    query = acl,
    endpoint = "toxprints/assays",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
