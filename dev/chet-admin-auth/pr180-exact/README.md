# Exact PR180 isolated CheT replay

PASS at Specmill commit `d9c6f9600f075e941999fc4fafffd4ede3d90b73`.
The final independent replay exited 0 with **492 passing assertions**, zero
failures, errors, warnings or skips. It made 36 actual localhost HTTP requests,
proved 84 rejected calls sent zero HTTP requests, and exercised three actual
connection failures after stopping its own listener.

All three held operations passed: POST `/auth/login`, `/auth/register`, and
`/auth/report`, under canonical server prefix `/api/chet`. The canonical
`schema/chemi-chet-prod.json` was copied unchanged and passed full OpenAPI 3.0.3
validation using jsonvalidate 1.5.0 with ajv. Official plan/apply/check used
`validation = TRUE`; every generated file was fresh and all 11 private manifest
owner hashes were independently verified. Every generated wrapper matches its
existing held wrapper byte for byte, including public name and required `body`
formal. The fix is in candidate validation/runtime, not wrapper changes.

This checkout has no `dev/chet-admin-auth/held-generated/configs` directory.
The private service config was reconstructed from `held.json`, the existing
admin/auth service policy, and the held wrapper documentation titles. The full
wrapper equality checks verify that reconstruction preserves the held contract.
`held.yml` records the exact replay policy.

The localhost suite checked string, integer, fractional number, TRUE/FALSE,
empty string, UTF-8 and punctuation, including escaped field names and exact raw
URLencoded bytes. Empty objects and omitted optional fields sent no invented
fields or defaults. Missing required body, NULL, NA, NaN, infinities, empty and
multi-value vectors, lists, nested objects, raw bytes, dates and malformed bodies
were rejected before HTTP. There are no declared field defaults in these schemas.
Typed 400/404/500 conditions retain response status and JSON body. Hard 401 remains
`specmill_call_error`; real transport errors retain `httr2_failure` and their curl
parent. Runtime `preserve_errors = FALSE` overrides wrapper policy while retaining
hard 401. Invalid controls, endpoint and dry-run settings fail before HTTP; an
explicit localhost base URL takes precedence over the resolver.

The exact source's unchanged `tests/free-form-fields.R` also exited 0. That
separate upstream regression covers scalar multipart fields, URLencoded bytes,
empty forms, declared constraints, closed forms, rejected ambiguous values and
validated freshness. Actual CheT schemas declare URLencoded forms only; they were
not rewritten to claim multipart support. See `upstream-free-form.txt`.

The GitHub commit tarball is archived privately at
`~/.cache/comptoxr-pr180-exact-test/source.tar.gz`. Its SHA256 is
`9ac0233be83cef396e847906567d95a56c14061172f3a32ef3ae95cb22fc5f59`.
All 517 unpacked source files match the archive bytes. `provenance.json` records
that verification, a source inventory digest and all 43 private installed-file
hashes. The unmodified candidate DESCRIPTION says 0.1.41; the exact source SHA,
not that inherited version number, identifies this unreleased candidate.

Reproduce from the ComptoxR root with installed R dependencies, gh authentication,
Python 3 and Air 0.11.0:

```sh
bash dev/chet-admin-auth/pr180-exact/reproduce.sh
```

The script installs only into the private cache library, sets persistent TMPDIR
before R starts, verifies the exact archive/commit, creates a new private project,
and uses official scaffold/helpers and generation. `results.json` records all
assertions, portable wire captures, transport classes and validation reports;
`private-manifest.json` is evidence only. Do not copy it into the root manifest.

[PR180](https://github.com/seanthimons/specmill/pull/180) and the blocked
[ComptoxR PR345](https://github.com/seanthimons/ComptoxR/pull/345) were registered
with T3. No contract failure was found, so no upstream failure comment or duplicate
issue was filed. No upstream implementation was changed.

Root adoption remains held until the fix is released and the pin is reviewed and
updated. Released v0.1.42 is separate and does not release this fix. Full package
checks and full CI completion were not established by this scoped replay. At the
status read, only Commit Lint reported success for the exact PR180 SHA.
No deployed auth/session requests, deployed upload/mutation probes, root runtime,
config, pin, helper, manifest, progress or HANDOFF changes, or ComptoxR push.
