# ComptoxR
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Test Coverage](https://img.shields.io/badge/coverage-3%25-red.svg)](https://github.com/seanthimons/ComptoxR/actions/workflows/test-coverage.yml)
[![CodeFactor](https://www.codefactor.io/repository/github/seanthimons/comptoxr/badge)](https://www.codefactor.io/repository/github/seanthimons/comptoxr)
[![CCD Coverage](https://img.shields.io/badge/CCD_coverage-79.3%25-green.svg)](https://github.com/seanthimons/ComptoxR/actions/workflows/update-coverage-badges.yml)
[![Cheminformatic Coverage](https://img.shields.io/badge/Cheminformatic_coverage-75.5%25-green.svg)](https://github.com/seanthimons/ComptoxR/actions/workflows/update-coverage-badges.yml)
<!-- badges: end -->


# Wrappers and Functions for Accessing USEPA CompTox Chemical Dashboard APIs and Other Products

ComptoxR provides access to the US EPA's CompTox Chemical Dashboard APIs and related products for chemical risk screening and prioritization. The package integrates data from multiple EPA databases including CompTox Chemistry Dashboard, GenRA Engine, Toxicity Estimation Software Tool (TEST), ECOTOX, and EPI Suite to enable comprehensive chemical hazard assessment and toxicity screening.

## Main Purpose

ComptoxR enables researchers to query and analyze chemical hazard, toxicity, and environmental data from EPA databases for:
- Rapid chemical risk screening and prioritization
- Regulatory compliance assessment
- Chemical hazard prioritization studies
- Environmental fate and exposure modeling
- Toxicity prediction and bioactivity screening
- Chemical structure and property analysis

## Key Capabilities

### Chemical Identification & Search
- Resolve chemical identifiers (DTXSID, DTXCID, CAS, SMILES, InChI, InChIKey, chemical names) with fuzzy or exact matching
- Search chemicals by string matching (exact, starts-with, or contains)
- Retrieve detailed compound information with various projection options
- Classify compounds as organic, inorganic, isotope, or Markush structures

### Hazard & Safety Assessment
- Generate hazard comparison data with multiple coercion methods
- Retrieve GHS codes and NFPA 704 safety diamond information
- Access Toxprint molecular fingerprint analysis
- Query cancer endpoints, genotoxicity data, skin/eye irritation information
- Get GHS classifications and regulatory hazard data

### Bioactivity & Toxicity Data
- Query bioactivity and toxicity screening models
- Access environmental degradation and fate data
- Retrieve exposure information from multiple sources
- Get QSAR model predictions

### Chemical Properties & Descriptors
- Access molecular descriptors and chemical properties
- Retrieve EPI Suite environmental partition predictions
- Get molecular classifications using ClassyFire chemical taxonomy
- Find similar or related compounds
- Perform chemical clustering and similarity analysis

### Risk Screening & Prioritization
- Chemical risk prioritization queries
- Regulatory list associations
- Functional use information
- Analog searches for hazard comparison

### Batch Processing
- Automatic batch processing for large queries (default 200 compounds per batch)
- Support for multiple server environments (Production, Staging, Development)

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

Set API key in System Environment to the variable `ctx_api_key`.

``` r
Sys.setenv('ctx_api_key' = [TOKEN HERE])
```

Restart R to ensure that the token is detected properly.

### Initial Setup

On attaching the package, the API server paths will automatically be set to public endpoints, but can be adjusted or reset via the `*_server()` functions. The attaching function will also assess API endpoint status, debugging / verbosity flags, and token status.

To control certain verbosity outputs, use the `run_verbose(verbose = *BOOLEAN*)` function. This also hides the initial header output if `verbose = FALSE`.

## Disclaimers

This resource is a proof-of-concept and is a compilation of information sourced from many databases and literature sources, including U.S. Federal and state sources and international bodies, which can save the user time by providing information in one location. The data are not fully reviewed by USEPA -- the user must apply judgment in use of the information. You should consult the original scientific paper or data source if possible. Reference herein to any specific commercial products, process, or service by trade name, trademark, manufacturer, or otherwise, does not necessarily constitute or imply its endorsement, recommendation, or favoring by the United States Government. The views and opinions of the developers of the site expressed herein do not necessarily state or reflect those of the United States Government, and shall not be used for advertising or product endorsement purposes With respect to documents available from this server, neither the United States Government nor any of their employees, makes any warranty, express or implied, including the warranties of merchantability and fitness for a particular purpose, or assumes any legal liability or responsibility for the accuracy, completeness, or usefulness of any information, apparatus, product, or process disclosed, or represents that its use would not infringe privately owned rights.
