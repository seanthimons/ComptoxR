# ComptoxR

# Wrappers and Functions for Accessing USEPA CompTox Chemical Dashboard APIs and Other Products

## Version 1.2.0

ComptoxR is designed to leverage the USEPA CCTE's APIs for accessing the underlying data that makes up the CompTox Chemical Dashboard. It includes functions to access or recreate data from the GenRA, TEST, and Cheminformatics products to inform rapid chemical risk screening. A method of weighing and prioritizing a group of chemicals is also included.

An API Key is needed to access some of these APIs. Each user will need a specific key for each application. Please send an email to request an API key.

------------------------------------------------------------------------

to: `ccte_api@epa.gov`

subject: API Key Request

------------------------------------------------------------------------

## Installation

``` r
library(devtools) 
```

``` r
install_github("seanthimons/ComptoxR")
```

## Initial Setup

### Setting API keys

Set API key in Sys Environment to the variable `ccte_api_key`.

``` r

Sys.setenv('ccte_api_key' = [TOKEN HERE])
```

Run the `ct_api_key()` function to test to see if the token is being detected. A restart of R may be required.

``` r

.rs.restartR()
```

### Setting API server paths

The function `comptox_server()` will need to be ran to set the root URL path for the servers. A production server and a staging server (only accessed through the EPA VPN) are provided. Setting the `server` argument to `1` will default the System Environment variable `burl` to the public root URL path. This should only need to be done once.

------------------------------------------------------------------------

## Workflow

------------------------------------------------------------------------

## Suggested applications

### Aggregated list searching

The `ct_list()` and `ct_compound_in_list()` functions are designed to allow a user to see all compounds on a given list using the list's short code (the column `name`) or see on which aggregate lists a compound may appear on. The full register of aggregate lists may be found using the `ct_list_all()` function.

As of version 1.2.0, this package ships with two example data sets: `prodwater` and `cwa311hs`. 

### Bulk data requests

The `ct_` family of functions are designed to either query a single compound (typically a DTXSID) or a list of compounds. For larger requests (200+) a bulk function is included where possible.

### Hazard Comparison Table

Using one wrapper function `chemi_hazard()`, we can create a comparison table for several compounds. This may take a few minutes given the rate of the API calls, but allows for the data to be cached and then recalled at a later time for further analysis. The rules and logic of the Hazard Comparison Table are clearly laid out in the source code and are adapted from [CITATION]. Numerical responses from *in-vivo* and *in-vitro* data from a number of databases are transformed and binned for human-readability. The underlying dataset can be exported or used for further examination (e.g.: leveraged for a ToxPi risk characterization).

### ToxPi Risk Characterization

The Toxicological Priority Index (ToxPi) prioritization algorithm exists to compare several different endpoints for compounds to yield a single, relative risk characterization. While the `toxpiR` package exists, the `hc_toxpi_table()` function allows for a singular experience to quickly iterate through characterization schemas. A meta-data reporting feature is also included to characterize the endpoints one is using to better determine weighing schemes (see vignettes and examples).

### Non-Targetted Analysis

------------------------------------------------------------------------

## Other useful functions

### Synonym searching

### `ct_details()`

------------------------------------------------------------------------

## Future work

-   Implementation of bio-activity *in-vitro* data
-   Wrap all functions that have a bulk request
-   

------------------------------------------------------------------------

Disclaimers

This resource is a proof-of-concept and is a compilation of information sourced from many databases and literature sources, including U.S. Federal and state sources and international bodies, which can save the user time by providing information in one location. The data are not fully reviewed by USEPA -- the user must apply judgment in use of the information. You should consult the original scientific paper or data source if possible. Reference herein to any specific commercial products, process, or service by trade name, trademark, manufacturer, or otherwise, does not necessarily constitute or imply its endorsement, recommendation, or favoring by the United States Government. The views and opinions of the developers of the site expressed herein do not necessarily state or reflect those of the United States Government, and shall not be used for advertising or product endorsement purposes With respect to documents available from this server, neither the United States Government nor any of their employees, makes any warranty, express or implied, including the warranties of merchantability and fitness for a particular purpose, or assumes any legal liability or responsibility for the accuracy, completeness, or usefulness of any information, apparatus, product, or process disclosed, or represents that its use would not infringe privately owned rights.
