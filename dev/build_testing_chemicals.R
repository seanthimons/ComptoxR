# Developer helper for updating data/testing_chemicals.rda.
#
# This file lives in dev/ so devtools/usethis remain maintainer-only
# dependencies and are not required by installed package code.

build_testing_chemicals <- function(chems = character(0)) {
  if (length(chems) == 0) {
    cli::cli_abort(c("No chemicals provided for integration."))
  }

  candidates <- ct_search(chems)

  failed_chems <- character(0)
  if ("dtxsid" %in% colnames(candidates)) {
    failed_chems <- candidates$raw_search[is.na(candidates$dtxsid)]
  } else if ("suggestions" %in% colnames(candidates)) {
    failed_chems <- candidates$raw_search
  }

  if (length(failed_chems) > 0) {
    cli::cli_alert_warning("No results found for the following chemicals:")
    cli::cli_bullets(c("*" = unique(failed_chems)))
  }

  new_dtxsids <- candidates %>%
    dplyr::filter(!is.na(.data$dtxsid)) %>%
    dplyr::filter(.data$dtxsid %ni% ComptoxR::testing_chemicals$dtxsid) %>%
    dplyr::pull(.data$dtxsid) %>%
    unique()

  if (length(new_dtxsids) == 0) {
    cli::cli_alert_info("All chemicals found are already in the testing dataset.")
    return(invisible(NULL))
  }

  chems_to_add <- ct_details(query = new_dtxsids, projection = "id")

  cli::cli_h2("New chemicals to be added")
  print(chems_to_add %>% dplyr::select(preferredName, casrn, dtxsid))

  usethis::ui_yeah("Do you want to proceed and add these {length(new_dtxsids)} chemical{?s}?")

  updated_chems <- dplyr::bind_rows(chems_to_add, ComptoxR::testing_chemicals) %>%
    dplyr::distinct() %>%
    dplyr::select(
      "preferredName",
      "casrn",
      "dtxsid",
      "dtxcid",
      "inchikey"
    )

  if (nrow(updated_chems) < nrow(ComptoxR::testing_chemicals)) {
    cli::cli_abort("Something failed with updating the testing chemicals.")
  }

  cli::cli_alert_info("Updating `testing_chemicals.rda` data file.")
  testing_chemicals <- updated_chems

  usethis::use_data(testing_chemicals, overwrite = TRUE)
  devtools::load_all()
}
