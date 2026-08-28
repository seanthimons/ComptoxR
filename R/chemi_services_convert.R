#' Services Convert
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param content Optional parameter
#' @param type Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_convert(content = "DTXSID1024122")
#' }
chemi_services_convert <- function(content = NULL, type = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_services_convert", "pre_request", list(params = list(`content` = content, `type` = type, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("content" %in% names(req_data$params)) {
    content <- req_data$params[["content"]]
  }
  if ("type" %in% names(req_data$params)) {
    type <- req_data$params[["type"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(type)) options$type <- type
  result <- generic_chemi_request(
    query = content,
    endpoint = "services/convert",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
