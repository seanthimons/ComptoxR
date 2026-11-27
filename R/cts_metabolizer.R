#' Get CTS metabolizer metadata
#'
#' @noMd
#' @return A list containing CTS metadata and links.
#' @export
# Generated with specmill; do not edit by hand.
cts_metabolizer <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/metabolizer",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    server = list(url = "https://qed.epa.gov/cts/rest"),
    auth = list()
  )
  result
}
