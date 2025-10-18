#' Data frame of DTXSIDs to test things with.
#'
#' A data frame of several DTXSIDs to test functions with.
'testing_chemicals'

#' Table of GenRA function endpoints.
#'
#' A tibble of possible choices for GenRA functions.
#'
'genra_engine'

#' Table of ToxPrint Chemotypes
#'
#'
'toxprint_ID_key'

#' Table of ToxPrint Enrichment table values to build against.
#'
#' A tibble of possible Chemotypers Toxprints that have been enriched against in-vitro assay results
#'
#' @format `toxprint_dict`
#'
'toxprint_dict'

#' Standard test species
#'
#' A table of standard test species
'std_spec'

#' Invasive species
#'
#' A table of invasive species
'inv_spec'

#' Threatened species
#'
#' A table of threatened species
'threat_spec'

#' ToxValDB Source Dictionary
#'
#' Used to rank data sources. From ToxValDB 9.4
'toxvaldb_sourcedict'

#' Periodic table
#'
#' List of elements with symbol and atomic number, oxidation state, and a list of isotopes and nuclides
#'
#' Ripped and curated from:
#'  https://en.wikipedia.org/wiki/Oxidation_state,
#'  https://en.wikipedia.org/wiki/List_of_chemical_elements#'
#'  https://en.wikipedia.org/wiki/List_of_radioactive_nuclides_by_half-life#
#'  https://en.wikipedia.org/wiki/List_of_nuclides#
#'
#'
'pt'

#' Property IDs for `ct_property` searching
#'
#' List of property IDs that can be searched for.
#'
'property_ids'

#' Custom list of color palettes
#'
#' Generated using https://medialab.github.io/iwanthue/; 25 soft (k-means), colorblind friendly (1-10)
#'
'cust_pal'

#' Cheminformatics hazard comparison palette
#' 
#' Five colors from website
#' 
'cheminformatics_hazard_pal'
