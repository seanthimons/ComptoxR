# CheT admin/auth native bindings

This isolated change adopts 14 of the 24 previously unbound `/admin/` and `/auth/`
operations in unchanged `schema/chemi-chet-prod.json`. All exported wrappers and
Rd files come from official Specmill v0.1.41 at
`05862bee1804806cea157ff1962300d741516301`, using its native `.ct_request` backend.
No legacy public wrapper is replaced. `scope.json` records the parent's current
service/config hashes at discovery. All 24 proposed names were checked against
all parent R source text for symbol collisions and direct callers; none existed.
The separate 35-route chemical/curator/reaction work and reviewed download GET
are excluded.

The 14 adopted routes include admin database GET; admin errorreport, login,
register and resolve POSTs; auth errorpage GET/POST, errorpage complete and
showhide GET/POST, logout GET, and testpage GET/POST. Every request in the
execution suite goes to an actual `127.0.0.1` HTTP server through real httr2.
Even logout and completion requests are localhost only.

Ten routes remain held in `held.json`:

- GET `/admin/errorreport`, `/admin/login`, `/admin/register`, `/admin/resolve`,
  `/auth/login`, `/auth/register`, `/auth/report` declare optional GET bodies.
  Canonical OAS 3.0.3 ignores these declarations, leaving their useful input
  contracts ambiguous. No reviewed correction, dialect upgrade or deployed probe
  was made. The read-only evidence behind Specmill #171 does not justify changing
  these contracts.
- POST `/auth/login`, `/auth/register`, `/auth/report` use required free-form
  `application/x-www-form-urlencoded` objects. Released generation rejects every
  undeclared form field despite `additionalProperties: true`. Filed
  [Specmill #178](https://github.com/seanthimons/specmill/issues/178), linked from
  [PR #345](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6253898755).
  Official candidate wrappers are retained only under `held-generated/`, outside
  package runtime and exports. `reproduce-held-form.R` checks the failure with an
  actual localhost listener and proves zero HTTP requests. No local workaround.

The source has no security declarations or required username/password properties.
The adopted admin JSON POSTs require a body object and permit arbitrary fields;
validation cannot require invented credential fields. Fixtures use invented
localhost username/password strings. No default identity, credentials, session
manager, authorization hook or token fixture is added. Deployment compatibility
and successful login are not established by these tests.

Reproduce from the repository root:

```sh
mkdir -p "$HOME/.cache/comptoxr-chet-admin-auth/tmp" "$HOME/.cache/comptoxr-chet-admin-auth/checkdir"
export TMPDIR="$HOME/.cache/comptoxr-chet-admin-auth/tmp"
Rscript dev/chet-admin-auth/build-fixture.R
Rscript dev/chet-admin-auth/generate.R
Rscript dev/chet-admin-auth/verify.R
Rscript dev/chet-admin-auth/reproduce-held-form.R
```

Generation uses a small complete isolated client under the persistent cache,
with schema validation enabled, official apply/check freshness, independent
normalized SHA256 verification of every ownership record, canonical source hashes
and exact released helper/validator comparisons. It copies only generated wrappers
and Rd files and appends exports. The fixture is independently derived from
canonical operation records, including the `/api/chet` server prefix and required
body/path inputs. Verification checks docs, namespace, bespoke registrations,
hooks, canonical ref closure and adopted hashes. The final suite passed 486
assertions with zero failures, errors, warnings or skips. The localhost suite exercises
exact methods, escaped paths, absent queries, JSON bodies, JSON/text/binary decoding,
received HTTP 400/404/500, hard 401, malformed and missing required inputs with
zero HTTP, and invalid runtime configuration. No selected operation declares
query parameters. Successful form encoding remains blocked by #178.

The parent owns root service registration, pin, helper, manifest, progress and
HANDOFF. They are unchanged here. Integrate this new service config through the
parent's official generation workflow and independently verify every root owned
hash. Never replace the root manifest with the child manifest or pre-copy new
bytes over an old owned record. No active library was modified, no package source
build copied dev artifacts, and no ComptoxR push was made. Full package checks and
live deployment checks are outside this isolated task.
