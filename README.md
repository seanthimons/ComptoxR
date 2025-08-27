# ComptoxR
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->


# Wrappers and Functions for Accessing USEPA CompTox Chemical Dashboard APIs and Other Products

ComptoxR is designed to leverage the USEPA ORD-CCTE's APIs for accessing the underlying data that makes up the CompTox Chemical Dashboard. It includes functions to access or recreate data from the GenRA, TEST, and Cheminformatics products to inform rapid chemical risk screening. A method of weighing and prioritizing a group of chemicals is also included.

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

### Setting API keys

Set API key in System Environment to the variable `ccte_api_key`.

``` r
Sys.setenv('ccte_api_key' = [TOKEN HERE])
```

Restart R to ensure that the token is detected properly.

### Initial Setup

On attaching the package, the API server paths will automatically be set to public endpoints, but can be adjusted or reset via the `*_server()` functions. The attaching function will also assess API endpoint status, debugging / verbosity flags, and token status.

To control certain verbosity outputs, use the `run_verbose(verbose = *BOOLEAN*)` function. This also hides the initial header output if `verbose = FALSE`.

## Disclaimers

This resource is a proof-of-concept and is a compilation of information sourced from many databases and literature sources, including U.S. Federal and state sources and international bodies, which can save the user time by providing information in one location. The data are not fully reviewed by USEPA -- the user must apply judgment in use of the information. You should consult the original scientific paper or data source if possible. Reference herein to any specific commercial products, process, or service by trade name, trademark, manufacturer, or otherwise, does not necessarily constitute or imply its endorsement, recommendation, or favoring by the United States Government. The views and opinions of the developers of the site expressed herein do not necessarily state or reflect those of the United States Government, and shall not be used for advertising or product endorsement purposes With respect to documents available from this server, neither the United States Government nor any of their employees, makes any warranty, express or implied, including the warranties of merchantability and fitness for a particular purpose, or assumes any legal liability or responsibility for the accuracy, completeness, or usefulness of any information, apparatus, product, or process disclosed, or represents that its use would not infringe privately owned rights.
