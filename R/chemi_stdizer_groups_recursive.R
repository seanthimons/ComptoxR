#' Stdizer Groups Recursive
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_recursive(id = "DTXSID7020182")
#' }
chemi_stdizer_groups_recursive <- function(id) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_stdizer_groups_recursive", "pre_request", list(params = list(`id` = id, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("id" %in% names(req_data$params)) {
    id <- req_data$params[["id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = id,
    endpoint = "stdizer/groups/recursive",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
