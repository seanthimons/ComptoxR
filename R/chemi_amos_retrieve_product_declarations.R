#' Returns information on a batch of product declarations specified by internal ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_ids List of product declaration IDs to return information on.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_retrieve_product_declarations(internal_ids = "DTXSID7020182")
#' }
chemi_amos_retrieve_product_declarations <- function(internal_ids = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_retrieve_product_declarations", "pre_request", list(params = list(`internal_ids` = internal_ids, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("internal_ids" %in% names(req_data$params)) {
    internal_ids <- req_data$params[["internal_ids"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(internal_ids)) options[['internal_ids']] <- internal_ids
    result <- generic_chemi_request(
    endpoint = "amos/retrieve_product_declarations/",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
