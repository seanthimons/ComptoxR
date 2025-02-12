% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/toxpi.R
\name{tp_combined_score}
\alias{tp_combined_score}
\title{ToxPi Combined Score Table}
\usage{
tp_combined_score(table, id = NULL, bias = NULL, zero_fill, na_fill)
}
\arguments{
\item{table}{A table that contains an id column and endpoints to weigh against.}

\item{id}{id column to ignore. Must be present to continue calculation.}

\item{bias}{A table generated by the user using the \code{\link[=tp_endpoint_coverage]{tp_endpoint_coverage()}} function. Required for calculation.}

\item{zero_fill}{TEMP}

\item{na_fill}{TEMP}
}
\value{
A tibble of results
}
\description{
Takes a user-supplied table (with a column that provides identification), and optionally a bias table from \code{\link[=hc_endpoint_coverage]{hc_endpoint_coverage()}} with user-supplied weights. The function will perform a min-max normalization per each endpoint (i.e.: every other column that is not an identifier), then sums up the scores on a per-row basis.
The suggested workflow is to create the bias table, then to run the function with the desired table to evaluate.
}
