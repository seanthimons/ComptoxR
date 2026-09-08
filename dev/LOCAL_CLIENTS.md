# Local schema clients

Install the pinned development toolkit recorded in `dev/toolkit-lock.json`.
Keep local schema snapshots and clients outside every ComptoxR checkout.
The command takes six explicit positional arguments:

```text
Rscript dev/generate_local_client.R <ComptoxR_checkout> <schema_directory> <schema_filename> <new_output_directory> <base_url> <local_package_name>
```

For example, use the frozen external schema directory and an explicit local
service URL. Choose the URL prefix to which the paths in that schema must be
appended. A schema path that starts with `/api` already includes that segment;
do not repeat it in the base URL. Schema `servers` never select or change the
configured host. URLs can be production, development, staging or localhost
when explicitly supplied. The URL must not contain credentials, query or
fragment components. The command does not send HTTP requests during generation.

The output directory must be new or empty. The command rejects output inside
the public repository, its worktrees or another ComptoxR checkout. It also
rejects schema input inside the public repository and paths outside the given
input root. Each output is a separate local package with `DESCRIPTION`,
`NAMESPACE`, `R/` and a license file, plus convenient `client.R` and
`manifest.json` files. Use a distinct package name such as `localalerts`.
The manifest
records the toolkit version, schema file hash, explicit URL, supported
operation names and unsupported-operation reasons. It does not copy schemas
into the public repository. Unsupported operations are not generated.

Install the package into a separate local library:

```r
dir.create('/absolute/local/library', recursive = TRUE, showWarnings = FALSE)
install.packages('/absolute/local/output', repos = NULL, type = 'source',
                 lib = '/absolute/local/library')
library(localalerts, lib.loc = '/absolute/local/library')
```

Alternatively, load the sourceable client into its own environment:

```r
client <- new.env(parent = baseenv())
sys.source('/absolute/local/output/client.R', envir = client)
# Call a supported function listed in manifest.json:
# response <- client$operationName(...)
# httr2::resp_body_json(response)
```

The generated package declares httr2 and jsonlite at runtime. The latter is
required by httr2's optional JSON functions. It returns an httr2 response and
propagates HTTP errors. It does not load ComptoxR or wrapmaint. It has no
automatic authentication, pagination or chemical resolution. Those behaviors
need separately reviewed local helper code. Keep generated clients local;
public operations must be regenerated from approved production schemas.

Verification: `Rscript dev/migration-evidence/verify-local-client.R` generates
the four-operation catalogue twice, compares both output hashes, rejects public
output and replacement of existing files, reports an unsupported header, and
starts a fresh R process. It also installs the generated package in a separate
library that contains only its runtime dependencies, with wrapmaint and
ComptoxR unavailable. Both forms check three mocked HTTP requests,
path/query encoding, JSON placement and HTTP error propagation without loading
the toolkit or ComptoxR. Mocking uses the httr2
[documented mock interface](https://httr2.r-lib.org/reference/with_mocked_responses.html).

The frozen `chemi-alerts-dev.json` snapshot generated 9 supported operations and
8 diagnostics: 4 unsupported parameter types, 3 unsupported body properties and
1 unsupported body media type. This is partial local generation, not support
for the whole service schema. The local artifact was written outside the public
repository under `ComptoxR-local-clients/migration-516dfd4/clients/localalerts`.
The explicit `https://local.invalid` demonstration URL is not a live service
configuration. Use an actual reviewed base URL prefix when generating a client
for use.

The frozen alerts output also passed a fresh-process mocked GET for
`groupGet('a/b')`, with the fixed expected URL
`https://local.invalid/api/alerts/groups/a%2Fb` and a parsed JSON response.
Repeat that check with
`Rscript --vanilla dev/migration-evidence/verify-local-client.R --alerts <absolute_client.R>`.
The actual alerts package also passed installation and the same mocked GET in
the separate `migration-516dfd4/library-localalerts-json` library, with wrapmaint
and ComptoxR absent. Repeat with
`Rscript dev/migration-evidence/verify-local-client.R --install-alerts <package_root> <new_local_library>`.
Install output reports no man pages: these are minimal local packages, not
packages prepared for public release.
All verification commands passed with no skips. Air and Jarl passed for the
command and verification script. No live network request was made.
