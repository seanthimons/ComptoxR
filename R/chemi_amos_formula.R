#' Returns a list of substances that have the given molecular formula.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param formula Molecular furmula to search by.  Formula should be in Hill form.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_formula(formula = "DTXSID7020182")
#' }
chemi_amos_formula <- function(formula) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_formula", "pre_request", list(params = list(`formula` = formula, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("formula" %in% names(req_data$params)) {
    formula <- req_data$params[["formula"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = formula,
    endpoint = "amos/formula_search/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
