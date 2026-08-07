# Contributing to ComptoxR

Thanks for contributing. This is the quick reference; the full **development
lifecycle** (branch model, CI, and how releases bump the version) is in
[`vignettes/articles/development-lifecycle.Rmd`](vignettes/articles/development-lifecycle.Rmd),
and per-workflow detail is in
[`.github/workflows/README.md`](.github/workflows/README.md).

## Branching

Work flows **feature -> `integration` -> `main` -> Release**. Cut feature
branches from `integration`:

```bash
git switch integration
git switch -c feat/short-description
```

Branch and commit names follow Conventional Branch and Conventional Commits:

- Branches: `type/description`, lowercase, hyphenated
  (`feat/`, `fix/`, `chore/`, `docs/`, `refactor/`, ...).
- Commits: `type: description` or `type(scope): description`. Use `feat:` for
  features and `fix:` for bug fixes. The first line becomes the `NEWS.md`
  release note, so write it as the note you want.
- Do **not** put agent, model, or AI names in branch or commit names, and do
  **not** add `Co-authored-by` / attribution trailers.

## Before you open a PR

Run the targeted checks for what you changed:

```r
# Documentation after roxygen changes
devtools::document()

# Targeted tests
testthat::test_file("tests/testthat/test-generic_request.R")
devtools::test(filter = "generic_request")
```

For R code, format and lint:

```bash
air format <file>      # or: air format .
jarl check <file>      # or: jarl check .
```

For changes with broad package impact, run the CRAN-safe readiness lane
locally:

```bash
Rscript dev/cran_readiness.R
```

## Pull requests

Open PRs against `main` (directly, or via `integration` first for staged work).
The full check suite — including the blocking **CRAN Readiness** gate — runs on
PRs targeting `main`. A green PR means the package is CRAN-clean. Never commit
directly to `main`.

## Releases and versioning

**Do not edit the `Version:` field in `DESCRIPTION`.** Releases are handled by
the manual **Release** GitHub Actions workflow, which bumps the version, tags,
regenerates `NEWS.md`, and cuts the GitHub release. See the development
lifecycle article for the full sequence. Do not create git tags by hand.

## API keys and cassettes

Routine tests run without secrets. Live cassette recording is opt-in only
(the **Record VCR Cassettes** workflow or
`Rscript dev/rerecord_cassettes.R --record-live`) and needs a real
`ctx_api_key`. Always run the cassette safety checks before committing
fixtures:

```r
source("tests/testthat/helper-vcr.R")
check_cassette_safety()
```
