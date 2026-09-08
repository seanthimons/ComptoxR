# ComptoxR <img src="man/figures/logo.png" alt="ComptoxR logo" align="right" height="139"/>

<!-- badges: start -->

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) [![Test Coverage](https://codecov.io/gh/seanthimons/ComptoxR/branch/main/graph/badge.svg)](https://codecov.io/gh/seanthimons/ComptoxR) [![CodeFactor](https://www.codefactor.io/repository/github/seanthimons/comptoxr/badge)](https://www.codefactor.io/repository/github/seanthimons/comptoxr) [![CCD Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/seanthimons/ComptoxR/main/.github/badges/ccd-coverage.json)](https://github.com/seanthimons/ComptoxR/actions/workflows/schema-check.yml) [![Cheminformatics Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/seanthimons/ComptoxR/main/.github/badges/chemi-coverage.json)](https://github.com/seanthimons/ComptoxR/actions/workflows/schema-check.yml)

<!-- badges: end -->

## Access EPA chemical data from R

ComptoxR helps researchers query and analyze chemical data from the U.S. EPA
CompTox Chemical Dashboard and related products. It is intended for students,
scientists, and other users who want to work with EPA chemical data without
writing HTTP requests themselves.

Start with the [ComptoxR package site](https://seanthimons.github.io/ComptoxR/),
which includes a getting-started guide, tutorials, and function reference.

## What can ComptoxR do?

- Find chemicals by names, CAS numbers, DTXSIDs, SMILES, InChI, and other identifiers.
- Retrieve chemical properties, descriptors, structures, and synonyms.
- Explore hazard, cancer, genotoxicity, safety, and toxicity information.
- Query bioactivity, exposure, environmental fate, and QSAR data.
- Work with GenRA, ECOTOX, ToxValDB, EPI Suite, and cheminformatics services.
- Send batches of chemicals and receive results as data frames or tibbles.

## Installation

ComptoxR is currently installed from GitHub. Install `pak` once, then install
ComptoxR:

```r
install.packages("pak")
pak::pkg_install("seanthimons/ComptoxR")
```

Load the package in each R session in which you use it:

```r
library(ComptoxR)
```

## Service configuration

Public functions use approved production APIs. EPI Suite uses
`https://episuite.dev/api`. ECOTOX and ToxVal use local databases by default;
their shipped Plumber servers can provide localhost HTTP access.

For each service, `ComptoxR.<key>` options take precedence over the lowercase
environment variable, then the package default. The keys are `ctx_burl`,
`chemi_burl`, `epi_burl`, `eco_burl`, `toxval_burl`, `np_burl`, and `pubchem_burl`.
Loading the package does not change these environment variables.

```r
options(ComptoxR.chemi_burl = "https://api.example.org/api")
options(ComptoxR.chemi_burl = NULL) # Use environment or production default
eco_server(2) # Shipped localhost Plumber server
```

Selectors still set their environment variables. Call a selector with no
argument to clear that setting; an option still takes precedence. Use
`url_only = TRUE` to inspect a target without changing settings or connections.
Explicit HTTP(S) URLs remain supported. Removed development numeric choices
now give a configuration error. Public browser sites are not REST APIs.

Update ComptoxR and the local Plumber server together, then restart the server.
Keep existing local databases and mapping evidence. ECOTOX results contain
native lifestage codes and descriptions; apply experimental envharmonizer
mappings explicitly when needed.

## API key setup

Many CompTox services require an API key. Request a key by emailing
`ccte_api@epa.gov` with the subject `API Key Request`.

After you receive a key, store it in your user `.Renviron` file. This keeps the
key out of scripts and projects:

```r
file.edit("~/.Renviron")
```

Add this line to the file, replacing the placeholder with your key:

```text
ctx_api_key=YOUR_KEY_HERE
```

Save the file and restart R. Confirm that R can find the key without printing
the key in a script or report:

```r
ct_api_key()
```

If you only need the key for the current session, use:

```r
Sys.setenv(ctx_api_key = "YOUR_KEY_HERE")
```

## First steps

Use a chemical identifier to retrieve a compound record:

```r
library(ComptoxR)

ct_chemical_detail_search("DTXSID7020182")
```

For several identifiers, use the bulk function:

```r
result <- ct_chemical_detail_search_bulk(
  query = c("DTXSID7020182", "DTXSID7020192")
)
dplyr::glimpse(result)
```

Use `ct_chemical_detail_search()` for one chemical and
`ct_chemical_detail_search_bulk()` for a vector of identifiers.

The package site has examples for searching, hazard data, properties, batch
requests, and local database tools. API-dependent examples are marked so that
installing the package does not make unexpected network requests.

## Configuration and troubleshooting

- `run_setup()` checks the configured endpoints and available credentials.
- `run_verbose(TRUE)` prints request progress for the current session.
- `run_debug(TRUE)` creates dry-run requests without sending them.
- `ctx_server()`, `chemi_server()`, and the other `*_server()` functions show or change service endpoints.

For help, see the [package site](https://seanthimons.github.io/ComptoxR/),
[report an issue](https://github.com/seanthimons/ComptoxR/issues), or read the
documentation for the function you are using.

## Development status

ComptoxR is experimental. It combines information from several EPA services;
check the original source and its limitations before using results for
decisions or publications.
