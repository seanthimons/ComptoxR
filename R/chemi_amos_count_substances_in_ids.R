#' Counts the number of unique substances seen in a set of records.
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
#' chemi_amos_count_substances_in_ids(internal_id_list = c("DTXSID1025568", "DTXSID1049641", "DTXSID901336502"))
#' }
chemi_amos_count_substances_in_ids <- function(internal_id_list = NULL) {

  result <- generic_chemi_request(
    query = internal_id_list,
    endpoint = "amos/count_substances_in_ids/",
    wrap = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


