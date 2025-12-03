# TODO Migrate to generic requests + promote to stable after testing

#' Retrieves Chemical Fate and Transport parameters
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_env_fate(query = "DTXSID7020182")
#' }
ct_env_fate <- function(query) {

	# Use generic_request with tidy=FALSE to get list output

	result <- generic_request(
    query = query,
    endpoint = "chemical/fate/search/by-dtxsid/",
		batch_limit = 1,
    tidy = FALSE,
    method = "POST"
  )
	# Additional post-processing can be added here
	# Query names
	query_names <- result %>%
		map(., ~ pluck(., 'dtxsid')) %>%
		list_c()

	# data
	cleaned_body <- result %>%
		set_names(query_names) %>%
		map(., ~ pluck(., 'properties')) %>%
		# Target sublists and replace NULL or empty elements with NA.
		# Using .default = NA in pluck handles cases where the list is empty or the element is NULL.
		map_depth(., 3, ~ pluck(.x, 1, .default = NA)) %>%
		# At depth 3, replace any NULL elements within sublists with NA.
		map_depth(., 3, ~ purrr::modify_if(.x, is.null, ~NA))

	# # Sublist data names
	# sublist_names <- cleaned_body %>%
	# 	# Grabs sublist names
	# 	map_depth(., 2, ~ pluck(.x, 'propName')) %>%
	# 	unname(.) %>%
	# 	# Coerces to a list of vectors per DTXSID
	# 	map(., ~ list_c(.x)) %>%
	# 	set_names(query_names)

	# Final data merging
	result <- map2(cleaned_body, sublist_names, ~ set_names(.x, .y)) %>%
		map_depth(., 2, ~ discard_at(., 'propName')) %>%
		map_depth(., 3,	~ as_tibble(.x)) %>%
		map_depth(., 2,	~ list_rbind(.x, names_to = 'type')) %>%
		map(., ~ list_rbind(., names_to = 'propName')) %>%
		list_rbind(., names_to = 'dtxsid')

	return(result)
}
