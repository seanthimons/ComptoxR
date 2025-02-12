% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ct_test.R
\name{ct_test}
\alias{ct_test}
\title{Retrieve results from TEST QSAR model.}
\usage{
ct_test(query, debug = F)
}
\arguments{
\item{query}{A list of DTXSIDs to be queried.}

\item{debug}{Flag to show API calls}
}
\value{
A tibble of results.
}
\description{
Returns queries from TEST QSAR models with the consensus model or the most likely model being returned.
Calls \code{ct_details()} and selects the QSAR-ready SMILES formula before requesting the results. Compounds without QSAR-ready SMILES will be dropped out. Compounds where the models are unable to make a predictions will be dropped as well.
}
\details{
Please refer to the TEST QSAR documentation for further details.
}
