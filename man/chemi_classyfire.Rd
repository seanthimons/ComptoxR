% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/chemi_classyfire.R
\name{chemi_classyfire}
\alias{chemi_classyfire}
\title{Get Classyfire classificaton for DTXSID}
\usage{
chemi_classyfire(query)
}
\arguments{
\item{query}{A character vector of DTXSIDs to query.}
}
\value{
A list of Classyfire classificatons corresponding to the input DTXSIDs.
Returns NA if the request fails for a given DTXSID.
}
\description{
This function retrieves Classyfire classificatons for a given DTXSID using the EPA's cheminformatics API.
}
