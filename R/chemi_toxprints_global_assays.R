#' Toxprints Global Assays
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
#' chemi_toxprints_global_assays(category = "DTXSID7020182")
#' }
chemi_toxprints_global_assays <- function(category = NULL, label = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_toxprints_global_assays", "pre_request", list(params = list(`category` = category, `label` = label, `server` = server)))
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
  if (!is.null(category)) options[['category']] <- category
  if (!is.null(label)) options[['label']] <- label
    result <- generic_request(
    endpoint = "toxprints/global_assays",
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
