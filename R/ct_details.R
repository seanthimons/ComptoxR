#' Retrieve compound details by DTXSID
#'
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param projection A subset of date to be returned. By default returns a minimal set of common identifiers.
#'
#' @return a data frame
#' @export
#'
#' @examples
#' \dontrun{
#' ct_details(query = "DTXSID7020182")
#' }
ct_details <- function(
	query,
	projection = c("all", "standard", "id", "structure", "nta", 'compact')
) {
	if (missing(projection)) {
		projection <- 'compact'
	}

	proj <- case_when(
		projection == "all" ~ "chemicaldetailall",
		projection == "standard" ~ "chemicaldetailstandard",
		projection == "id" ~ "chemicalidentifier",
		projection == "structure" ~ "chemicalstructure",
		projection == "nta" ~ "ntatoolkit",

		projection == 'compact' ~ 'compact',
		TRUE ~ NA_character_
	)
  
  generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "POST",
    projection = proj
  )
}
