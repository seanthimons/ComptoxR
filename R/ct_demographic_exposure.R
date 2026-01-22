#' Get SEEM3 Demographic Exposure Prediction
#' 
#' @details These are estimates of the average (geometric mean) exposure rate (mg/kg bodyweight/day) for the U.S. population. We are 50% confident that the exposure for the chemical is below the median estimate, and we are 95% confident that the average exposure rate is below the upper 95th percent estimate. Total population predictions are based upon consensus exposure model predictions and the similarity of the compound to those chemicals monitored by NHANES. The method for the demographic-specific predictions are based upon a simpler, heuristic model described in the 2014 publication "High Throughput Heuristics for Prioritizing Human Exposure to Environmental Chemicals".
#' 
#' @param query A single DTXSID (in quotes) or a list to be queried
#' 
#' @return tibble
#' @export
#' 
#' @examples
#' \dontrun{
#' ct_demographic_exposure(query = "DTXSID7020182")
#' }

ct_demographic_exposure <- function(query) {

	generic_request(
		query = query, 
		endpoint = 'exposure/seem/demographic/search/by-dtxsid/',
		method = 'POST'
	)

}

#' Get SEEM General Exposure Prediction
#' 
#' @details These are estimates of the average (geometric mean) exposure rate (mg/kg bodyweight/day) for the U.S. population. We are 50% confident that the exposure for the chemical is below the median estimate, and we are 95% confident that the average exposure rate is below the upper 95th percent estimate. Total population predictions are based upon consensus exposure model predictions and the similarity of the compound to those chemicals monitored by NHANES. The method for the total U.S. population was described in a 2018 publication, "Consensus Modeling of Median Chemical Intake for the U.S. Population Based on Predictions of Exposure Pathways".
#' 
#' @param query A single DTXSID (in quotes) or a list to be queried
#' 
#' @return tibble
#' @export
#' 
#' @examples
#' \dontrun{
#' ct_general_exposure(query = "DTXSID7020182")
#' }

ct_general_exposure <- function(query) {

	generic_request(
		query = query, 
		endpoint = 'exposure/seem/general/search/by-dtxsid/',
		method = 'POST'
	)

}