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

Most wrappers are generated. Never hand-edit a generated `R/` file; change
`apis/*.yml`, `specmill.yml`, a hook or a callback and regenerate.
[Building ComptoxR from schemas](vignettes/articles/building-from-schemas.Rmd)
explains the whole pipeline. The short version, with the pinned toolkit
installed (`Rscript dev/install_specmill.R`) and Air 0.11.0 on the path:

```bash
export R_LIBS="$PWD/dev/specmill-pilot/artifacts/toolkit-library/$(Rscript -e 'cat(jsonlite::read_json("dev/specmill-lock.json")$version)')"
Rscript dev/generate_specmill.R --apply
Rscript -e 'devtools::document()'
Rscript dev/generate_specmill.R --apply
Rscript dev/generate_specmill.R --check
Rscript dev/generate_tests.R --check
Rscript dev/check_hook_config.R
Rscript dev/check_public_api.R
```

Any edit under `R/`, `schema/`, the hooks or the callbacks changes
`.specmill/manifest.json`; commit the refreshed manifest, or the
**Specmill Maintenance** check fails.

Run the targeted checks for what you changed:

```r
# Documentation after roxygen changes
devtools::document()

# Targeted tests
testthat::test_file("tests/testthat/test-ct_similar.R")
devtools::test(filter = "ct_similar")
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

Open PRs against `integration`. **Specmill Maintenance** runs on every PR,
and **CRAN Readiness** on every ready-for-review PR that touches code; both
must be green. `integration` reaches `main`
through its own PR, which runs the full check suite. Never commit directly to
`main` or `integration`.

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
