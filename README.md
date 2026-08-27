# ComptoxR <img src="man/figures/logo.png" alt="ComptoxR logo" align="right" height="139"/>

<!-- badges: start -->

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) [![Test Coverage](https://img.shields.io/badge/coverage-3%25-red.svg)](https://github.com/seanthimons/ComptoxR/actions/workflows/test-coverage.yml) [![CodeFactor](https://www.codefactor.io/repository/github/seanthimons/comptoxr/badge)](https://www.codefactor.io/repository/github/seanthimons/comptoxr) [![CCD Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/seanthimons/ComptoxR/main/.github/badges/ccd-coverage.json)](https://github.com/seanthimons/ComptoxR/actions/workflows/schema-check.yml) [![Cheminformatics Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/seanthimons/ComptoxR/main/.github/badges/chemi-coverage.json)](https://github.com/seanthimons/ComptoxR/actions/workflows/schema-check.yml)

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

Most API functions accept one identifier or a vector of identifiers. For
example, a small batch search is:

```r
ct_chemical_detail_search(
  c("DTXSID7020182", "DTXSID7020183")
)
```

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
