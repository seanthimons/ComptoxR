#' Returns an Excel file containing a deduplicated list of substances that appear in a given set of database record IDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id_list Array of record IDs.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_ids(internal_id_list = "DTXSID7020182")
#' }
chemi_amos_substances_for_ids <- function(internal_id_list = NULL) {

  result <- generic_chemi_request(
    query = internal_id_list,
    endpoint = "amos/substances_for_ids/",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


