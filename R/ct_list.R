
#' Returns all compounds on a given list
#' `r lifecycle::badge("stable")`
#'
#' Can be used to return all compounds from a single list (e.g.:'PRODWATER') or a list of aggregated lists.
#'
#' @param list_name Search parameter (list name or vector of list names)
#' @param extract_dtxsids Boolean to pluck out just the DTXSIDs.
#'
#' @return Returns a character vector (if extract_dtxsids=TRUE) or list of results (if FALSE)
#' @export
#'
#' @examples
#' \dontrun{
#'  ct_list(list_name = c("PRODWATER", "CWA311HS"), extract_dtxsids = TRUE)
#' }
ct_list <- function(list_name, extract_dtxsids = TRUE) {

  # Uppercase list names (API expects uppercase)
  list_name_upper <- stringr::str_to_upper(list_name)

  # Use generic_request with tidy=FALSE to get list output
  dat <- generic_request(
    query = list_name_upper,
    endpoint = "chemical/list/search/by-name/",
    method = "GET",
    batch_limit = 1,
    tidy = FALSE,
    projection = 'chemicallistwithdtxsids'
  )

  if (extract_dtxsids) {
    # Check if dat has duplicate names (multiple results concatenated)
    if (anyDuplicated(names(dat)) > 0) {
      # Multiple results - extract all dtxsids fields
      dtxsid_indices <- which(names(dat) == "dtxsids")
      dat <- dat[dtxsid_indices] %>%
        purrr::map(~ stringr::str_split(.x, pattern = ',')) %>%
        unlist() %>%
        unique()
    } else {
      # Single result - extract and split directly
      dat <- dat$dtxsids %>%
        stringr::str_split(pattern = ',') %>%
        unlist() %>%
        unique()
    }
  }

  return(dat)
}
