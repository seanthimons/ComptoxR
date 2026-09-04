#' Returns an Excel file containing a deduplicated list of substances that appear in a given set of database record IDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id_list Array of record IDs.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_ids_staging(internal_id_list = "DTXSID1024122")
#' }
chemi_amos_substances_for_ids_staging <- function(internal_id_list = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_substances_for_ids_staging", "pre_request", list(params = list(`internal_id_list` = internal_id_list, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("internal_id_list" %in% names(req_data$params)) {
    internal_id_list <- req_data$params[["internal_id_list"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = internal_id_list,
    endpoint = "amos/substances_for_ids/",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
