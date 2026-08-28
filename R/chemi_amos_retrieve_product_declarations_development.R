#' Returns information on a batch of product declarations specified by internal ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_ids Required parameter
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_retrieve_product_declarations_development(internal_ids = "DTXSID1024122")
#' }
chemi_amos_retrieve_product_declarations_development <- function(internal_ids) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_retrieve_product_declarations_development", "pre_request", list(params = list(`internal_ids` = internal_ids, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("internal_ids" %in% names(req_data$params)) {
    internal_ids <- req_data$params[["internal_ids"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = internal_ids,
    endpoint = "amos/retrieve_product_declarations/",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
