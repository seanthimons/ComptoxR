# Local schema clients

Install the development toolkit from `dev/toolkit-lock.json`. Keep schema inputs
and generated clients outside every ComptoxR checkout. The local command retains
that boundary policy and delegates initialization and generation to apipak:

```text
Rscript dev/generate_local_client.R <ComptoxR_checkout> <schema_directory> <schema_filename> <new_output_directory> <base_url> <package_name> <metadata.json>
```

Supply your own package metadata, for example:

```json
{
  "title": "Local API Client",
  "author": {"given": "Test", "family": "Maintainer", "email": "maintainer@example.org"},
  "license": "MIT + file LICENSE"
}
```

The command requires a new or empty output directory and an explicit HTTP(S) URL
without credentials, query or fragment. Generation performs no HTTP requests.
The generated package owns its transport and runtime dependencies; it does not
load ComptoxR or apipak. Its `apipak.yml` and service YAML drive subsequent
`apipak::generate_client(root, config = 'apipak.yml', mode = 'plan')`, `apply`,
and `check` calls. Unsupported selected operations produce diagnostics and block
application; they do not disappear from the inventory.

For general initialization or adoption of an existing DESCRIPTION, use
`apipak::initialize_client()` directly. Initialization writes only absent files
and requires package metadata for a new package. Response decoding follows the
explicit transport contract documented in apipak, including JSON, text, binary,
and empty bodies. Natural Products remains schema stress testing only.

Historical local-alerts and standalone `client.R` evidence belongs to the
[pre-migration client revision](https://github.com/seanthimons/ComptoxR/tree/4fd720b97fb2f7f2abf131925e9270b0c11b057a/dev/migration-evidence).
Those scripts reproduce the old toolkit at that revision; they are not the
current maintenance commands.
