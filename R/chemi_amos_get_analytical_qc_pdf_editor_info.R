#' Retrieve editor metadata for an Analytical QC PDF.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_analytical_qc_pdf_editor_info(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_analytical_qc_pdf_editor_info <- function(internal_id) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_get_analytical_qc_pdf_editor_info", "pre_request", list(params = list(`internal_id` = internal_id, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("internal_id" %in% names(req_data$params)) {
    internal_id <- req_data$params[["internal_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = internal_id,
    endpoint = "amos/get_analytical_qc_pdf_editor_info/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
