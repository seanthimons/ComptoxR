# API maintenance

The public schema and `specmill.yml` control generated wrappers. Service policy is
in `apis/*.yml`; request construction, authentication and runtime hooks stay in
ComptoxR. An operation absent from the public schema must not be added.

The previous endpoint-evaluation implementation is archived at
[the production baseline](https://github.com/seanthimons/ComptoxR/tree/4fd720b97fb2f7f2abf131925e9270b0c11b057a/dev).
Its renderer, metadata-derived tests and lifecycle-only remover have been
replaced by the installed specmill engine and fixed offline contracts.

## Setup and commands

Install the checksum-verified development toolkit and Air 0.9.0:

```r
source('dev/install_toolkit.R')
install_toolkit()
```

The pin downloads immutable `specmill` 0.1.4 from
`https://github.com/seanthimons/specmill/releases/tag/v0.1.4`.
`dev/toolkit-lock.json` records the reviewed source commit and SHA-256.
The installer resolves its lockfile relative to its own script and verifies the
download before invoking R CMD INSTALL. It works when sourced from another
working directory and has no dependency on the toolkit being installed.

For rollback, restore a coherent pre-migration checkout at
`4fd720b97fb2f7f2abf131925e9270b0c11b057a` in a separate worktree and install
that checkout's reviewed legacy pin into a separate library. Do not point the
legacy generator at the new ownership manifest or restore only the pin while
keeping the new commands. The original runtime, development scripts and lockfile
remain reproducible at that revision. This migration does not release ComptoxR.

Run these commands from the checkout, or use absolute script paths from another
working directory:

```sh
Rscript dev/generate_stubs.R --plan
Rscript dev/generate_stubs.R
Rscript dev/generate_tests.R --generate
Rscript dev/generate_stubs.R --check --rebuild=ct --rebuild=chemi --rebuild=epi
Rscript dev/generate_tests.R --check
Rscript dev/check_hook_config.R
Rscript dev/check_public_api.R
```

Generation commands default to apply. `--check` and `--plan` (`--dry-run` for
tests) preserve client files. `--rebuild` remains accepted; it does not bypass
ownership. `--force` never overwrites an edited or manually maintained test.
Wrapper and test commands reconcile their respective outputs through the same
configuration. Wrapper generation also renders documentation with roxygen.

## Schema changes and contracts

Keep schema acquisition restricted to the approved public sources. Download or
parse failures block the schema workflow before generation. Schema comparison
uses original method/path identities, including newly discovered public domains.
Changed contracts enter the review lane conservatively; the report does not
prove wire compatibility or service availability.

Service YAML declares selection, public names/formals, documentation and any
request mappings. Unsupported shapes remain visible. Explicitly retained
implementations preserve existing behavior until their schema can be handled;
they are not counted as native support. Required-input presence and nullable
values are separate. `missing_as_null` is reserved for an existing hook that
must receive omission as NULL while keeping a required R formal.

`dev/specmill_callbacks.R` contains the necessary development callbacks. They are
loaded explicitly by the thin commands; YAML is data and cannot execute code.
Do not move request helpers or chemistry processing into the generator.

Fixed successful helper-call sequences and results live in
`tests/testthat/fixtures/specmill/*.rds`, referenced by each service. Review these
expectations independently of generated wrapper text. Preserve typed results,
all request arguments and auxiliary calls. New selected operations need an
explicit fixed contract; a helper call followed by an error is not a passing
test. Existing manually maintained suites remain in place.

## Ownership and recovery

`.specmill/manifest.json` records reviewed ownership and generation inputs. A
header or experimental lifecycle badge alone does not authorize replacement.
Modified files, mixed implementations and protected lifecycle states block
conflicting writes. Exclusions can retire only verified owned output.

Review a pending recovery before restoring it:

```r
specmill::recover_client('.')
specmill::recover_client('.', 'apply')
```

Do not delete journals or backups to make a failed generation appear to pass.
For a lock left by a terminated process, confirm that the process exited and
stop other writers, then follow specmill's documented empty-lock recovery procedure.
Resolve the recorded failure and verify a fresh check and unchanged
second apply. Initial adoption is a one-time reviewed hash operation; routine
maintenance does not re-adopt files.

## Reports and tests

`dev/specmill-coverage.yml`, `dev/specmill-testing.yml`,
`dev/specmill-public.yml` and `dev/specmill-readiness.yml` contain client report policy.
These sourceable commands provide a read-only plan:

```r
source('dev/calculate_coverage.R')
calculate_coverage(mode = 'plan')
source('dev/detect_test_gaps.R')
detect_gaps(mode = 'plan')
source('dev/unit_test_readiness_audit.R')
build_unit_test_readiness_audit('.')
```

Their command-line entrypoints preserve the existing report paths and GitHub
output fields. Coverage counts selected operations, with GET and POST counted
separately; manual exports stay outside that denominator. Gap reports include
manual request wrappers, and file coverage never substitutes for executing tests.

Run the offline maintenance lane with `COMPTOXR_CRAN_SAFE_TESTS=true`,
`NOT_CRAN=false`, no `ctx_api_key`, and existing fixtures. The toolkit is needed
only for development commands; installed ComptoxR runtime and generated contracts
do not depend on specmill. Recording scripts retain their separate `--record-live`
gate and token preflight. Routine verification must not re-record cassettes.
