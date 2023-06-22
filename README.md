# ComptoxR

# Wrappers and Functions for Accessing USEPA CompTox Chemical Dashboard and Other Products

## Version 0.0.0.1

ComptoxR is designed to leverage the USEPA CCTE's APIs for accessing the underlying data that makes up the CompTox Chemical Dashboard. It includes functions to access or recreate data from the GenRA, TEST, and Cheminformatics products to inform rapid chemical risk screening. A method of weighing and prioritizing a group of chemical is also included.

An API Key is needed to access these APIs. Each user will need a specific key for each application. Please send an email to request an API key.

to:`ccte_api@epa.gov`

subject: API Key Request

------------------------------------------------------------------------

## Initial Setup

Set API key in Sys Environment to the variable `ccte_api_key`

Run the `ct_api_key()` function to test to see if the token is being detected.

------------------------------------------------------------------------

## Suggested applications

### Hazard Comparison Table

Using one wrapper function `hcd_table()` (wraps around several helper functions [`ct_hazard()`, `ct_env_fate()`, `ct_details()` ,`ct_ghs()`]), we can create a comparison table for several compounds. This may take a few minutes given the rate of the API calls (the PubChem API is rate limited), but allows for the data to be cached and then recalled at a later time for further analysis. The rules and logic of the Hazard Comparison Table are clearly laid out in the source code and are adapted from []. Numerical responses from *in-vivo* and *in-vitro* data from a number of databases are transformed and binned for human-readability. The underlying dataset can be exported or used for further examination (e.g.: leveraged for a ToxPi risk characterization).

### ToxPi Risk Characterization

The Toxicological Priority Index (ToxPi) prioritization algorithm exists to compare several different endpoints for compounds to yield a single, relative risk characterization. While the `toxpiR` package exists, the `hcd_toxpi_table()` function allows for a singular experience to quickly iterate through characterization schemas. A meta-data reporting feature is also included to 

------------------------------------------------------------------------

## Other useful functions

------------------------------------------------------------------------

## Future work

-   Implementation of bio-activity *in-vitro* data
