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

	# Isolate new chemicals to be added
	new_dtxsids <- candidates %>%
		dplyr::filter(!is.na(.data$dtxsid)) %>%
		dplyr::filter(.data$dtxsid %ni% ComptoxR::testing_chemicals$dtxsid) %>%
		dplyr::pull(.data$dtxsid) %>%
		unique()

	if (length(new_dtxsids) == 0) {
		cli::cli_alert_info("All chemicals found are already in the testing dataset.")
		return(invisible(NULL))
	}

	chems_to_add <- ct_details(query = new_dtxsids, projection = 'id')

	# Display the chemicals that will be added and ask for confirmation
	cli::cli_h2("New chemicals to be added")
	print(chems_to_add %>% dplyr::select(preferredName, casrn, dtxsid))

	# usethis::ui_yeah() will abort if the user answers 'no'.
	usethis::ui_yeah("Do you want to proceed and add these {length(new_dtxsids)} chemical{?s}?")

	# Combine new chemicals with existing data
	updated_chems <- dplyr::bind_rows(chems_to_add, ComptoxR::testing_chemicals) %>%
		dplyr::distinct() %>%
		dplyr::select(
			'preferredName',
			'casrn',
			'dtxsid',
			'dtxcid',
			'inchikey'
		)

	if (nrow(updated_chems) < nrow(ComptoxR::testing_chemicals)) {
		cli::cli_abort('Something failed with updating the testing chemicals.')
	} else {
		cli::cli_alert_info("Updating `testing_chemicals.rda` data file.")

		testing_chemicals <- updated_chems

		usethis::use_data(testing_chemicals, overwrite = TRUE)
		devtools::load_all()
	}
}