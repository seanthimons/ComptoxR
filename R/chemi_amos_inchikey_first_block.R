#' Returns a list of substances found by InChIKey.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param first_block First block of an InChIKey.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_inchikey_first_block(first_block = "DTXSID7020182")
#' }
chemi_amos_inchikey_first_block <- function(first_block) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_inchikey_first_block", "pre_request", list(params = list(`first_block` = first_block, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("first_block" %in% names(req_data$params)) {
    first_block <- req_data$params[["first_block"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = first_block,
    endpoint = "amos/inchikey_first_block_search/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
