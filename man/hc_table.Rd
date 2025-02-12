% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hc_table.R
\name{hc_table}
\alias{hc_table}
\title{Create the Hazard Comparison matrix.}
\usage{
hc_table(
  query,
  archive = FALSE,
  save = TRUE,
  archive_string = NA,
  save_string = NA
)
}
\arguments{
\item{query}{Takes a list of compounds using DTXSIDs}

\item{archive}{Boolean value to use archived data from a previous run to recreate table. Defaults to \code{FALSE}. File will be prefixed with \code{search_data_} and a date-time suffix.}

\item{save}{Boolean value to save searched data. Highly recommended to be enabled. File will be prefixed with \code{search_data_} and a date-time suffix.}

\item{archive_string}{A string to search for}

\item{save_string}{A string to save by}
}
\value{
A tibble of results
}
\description{
This involves calling several functions
other \code{ComptoxR} functions and processes the results. Large queries may take
some time to request. Returns a table with the available endpoints in a
binned format ('VH', 'H', 'M', 'L', 'NA') as well as a numerical response. Some of
the endpoints have been transformed to better allow for a relative risk
characterization. Where responses are not available, a 'NA' response will be
present.
}
