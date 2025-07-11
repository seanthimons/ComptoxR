#' @title Add new chemicals to testing dataset
#' @param chems A character vector.
#'
#' @description A developer-facing function to add new chemicals to the internal
#' `testing_chemicals` dataset. It searches for the chemicals, retrieves their
#' details, and updates the package's internal data file.
#' @returns This function is called for its side effect of updating the
#' `data/testing_chemicals.rda` file and does not return a value.

build_testing_chemicals <- function(chems = character(0)) {
	if (length(chems) == 0) {
		cli::cli_abort(c("No chemicals provided for integration."))
	}

	candidates <- ct_search(chems)

	# Identify chemicals that were not found by ct_search
	failed_chems <- character(0)
	if ("dtxsid" %in% colnames(candidates)) {
		failed_chems <- candidates$raw_search[is.na(candidates$dtxsid)]
	} else if ("suggestions" %in% colnames(candidates)) {
		# Handles case where ct_search returns only suggestions
		failed_chems <- candidates$raw_search
	}

	if (length(failed_chems) > 0) {
		cli::cli_alert_warning("No results found for the following chemicals:")
		cli::cli_bullets(c("*" = unique(failed_chems)))
	}

	new_chems <- candidates %>%
		dplyr::filter(!is.na(.data$dtxsid)) %>%
		dplyr::filter(.data$dtxsid %ni% ComptoxR::testing_chemicals$dtxsid) %>%
		pull(dtxsid) %>%
		ct_details(query = ., projection = 'id') %>%
		bind_rows(., ComptoxR::testing_chemicals) %>%
		distinct() %>%
		select(
			'preferredName',
			'casrn',
			'dtxsid',
			'dtxcid',
			'inchikey'
		)

	if (nrow(new_chems) < nrow(ComptoxR::testing_chemicals)) {
		cli::cli_abort('Something failed with updating the testing chemicals.')
	} else {
		cli::cli_alert_info("Updating `testing_chemicals.rda` data file.")

		testing_chemicals <- new_chems

		usethis::use_data(testing_chemicals, overwrite = TRUE)
	}
}