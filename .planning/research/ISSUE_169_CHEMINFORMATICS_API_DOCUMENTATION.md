# Issue 169: Cheminformatics API documentation research

**Research date:** 2026-08-10  
**Scope:** GitHub issue [#169](https://github.com/seanthimons/ComptoxR/issues/169), with related issues [#165](https://github.com/seanthimons/ComptoxR/issues/165), [#166](https://github.com/seanthimons/ComptoxR/issues/166), and [#262](https://github.com/seanthimons/ComptoxR/issues/262)  
**Method:** Read-only requests without credentials. No cassette or fixture files were written.

## Result

Issue #169 can give the API developer more useful and current evidence.

The main change is to replace the stale May description with a paired control matrix. Production GET and POST both work for RDKit and Mordred when `headers=false`. The same requests fail when `headers=true`. A production PadEL control works in all four cases. Thus, the current defect is not a general POST defect and not a general aggregate-header defect. It is specific to header processing for the RDKit and Mordred engines.

The live production OpenAPI document also has a schema difference that is useful for diagnosis. It describes every value in `DescriptorsRequest.options` as an object. Staging permits values of any type. The real requests use boolean and integer values in `options`. This can cause validation or generated-client problems for POST. It does not explain the GET failure by itself, so the service must also inspect the shared engine-specific header path.

## Release-note crosswalk (2026-08-10)

The public release notes do not report the exact issue #169 failure. Neither page contains an entry for `headers=true`, the aggregate descriptor route, the joint RDKit and Mordred failure, header and descriptor count alignment, or the production 400 response.

Sources checked:

- [Server #2 / staging release notes](https://cim.sciencedataexperts.com/release_notes) and their [first-party JSON feed](https://cim.sciencedataexperts.com/api/services/release_notes)
- [Development release notes](https://cim-dev.sciencedataexperts.com/release_notes) and their [first-party JSON feed](https://cim-dev.sciencedataexperts.com/api/services/release_notes)

Both feeds returned 44,661 bytes and the same SHA-256 value, `980a0e0d693e48ec7e369484b0e17b189b3b44c1798e7bf617edb437271ac5f3`. The pages render the same 242 normalized entries. The page build banners differ: server #2 / staging shows July 7, 2026 at 10:40 AM, and development shows July 27, 2026 at 09:33 AM. These are page build times. They are not descriptor-service version identifiers.

The feeds contain only date, module, description, and type. They do not include ticket IDs, release versions, image identifiers, or stable entry links. Therefore, an entry cannot be mapped to a deployed descriptor-service build from these pages alone.

| Date | Release-note entry | Crosswalk to #169 |
|---|---|---|
| 2026-05-04 | The SEARCH module says that a descriptor GET-or-POST structure-use bug was fixed. | This is the closest entry. It predates issue #169, which was opened on May 28. It does not mention `headers`, RDKit, Mordred, the aggregate route, or a 400 response. The current `CCO` controls change only `headers`, so the entry does not establish that #169 was fixed. It can be an earlier related defect, an incomplete fix, or a later regression. |
| 2026-02-24 | The API notes say that the RDKit API was fixed. | This is too broad to identify the route or failure. It does not cover Mordred or header-bearing responses. |
| 2026-01-05 | The API notes say that HTTP 400 responses were changed to give chemists more useful messages. | This is related to diagnostics, not to the root defect. Issue #169 still receives only `400 BAD_REQUEST`, so that message improvement does not cover this route or has regressed. |
| 2025-12-04 | The API notes announce that Mordred descriptors became available. | This confirms the intended feature, but it does not document header support or a later failure. |
| 2025-09-14 | The API bug notes describe descriptor caching by InChIKey instead of QSAR SMILES. | This concerns cache identity and input structure. It is different from the header-return failure. |
| 2025-11-16 | The PREDICT 2.0 notes announce Swagger documentation. | This is not the aggregate descriptor OpenAPI document and does not cover its schema gaps. |

No descriptor-related release note appears after issue #169 was opened. The latest public note is dated June 9, 2026.

The affected HCD production host does not provide an equivalent public release-note source at the expected paths. On 2026-08-10, `https://hcd.rtpnc.epa.gov/release_notes` returned 502 and `https://hcd.rtpnc.epa.gov/api/services/release_notes` returned 404. Thus, the server #2 and development notes cannot prove which changes reached HCD production.

The release-note crosswalk supports keeping issue #169 open. The API developer should confirm whether the May 4 entry refers to `/api/descriptors`, identify the service image or commit that contained that fix, and confirm whether it was deployed to HCD production. The developer should also confirm whether the January 5 diagnostic-error change was intended to cover aggregate descriptor failures.

## Current direct control matrix

The probe used one unambiguous SMILES value, `CCO`, on 2026-08-10 at 14:15-14:19 UTC. This removes DTXSID resolution from the test.

GET shape:

```text
GET /api/descriptors?smiles=CCO&type=<engine>&headers=<true|false>&timeout=60
```

POST shape:

```json
{
  "type": "<engine>",
  "chemicals": ["CCO"],
  "chemIdType": "SMILES",
  "format": "JSON",
  "options": {
    "headers": true,
    "timeout": 60
  }
}
```

| Deployment | Engine | `headers` | GET | POST | Successful response |
|---|---|---:|---:|---:|---|
| Production | PadEL | `false` | 200 | 200 | 1,444 values; no headers |
| Production | PadEL | `true` | 200 | 200 | 1,444 values and 1,444 headers |
| Production | RDKit | `false` | 200 | 200 | 1,024 values; no headers |
| Production | RDKit | `true` | 400 | 400 | None |
| Production | Mordred | `false` | 200 | 200 | 1,613 values; no headers |
| Production | Mordred | `true` | 400 | 400 | None |
| Staging | RDKit | `false` | 200 | 200 | 1,024 values; no headers |
| Staging | RDKit | `true` | 200 | 200 | 1,024 values and 1,024 headers |
| Staging | Mordred | `false` | 200 | 200 | 1,613 values; no headers |
| Staging | Mordred | `true` | 200 | 200 | 1,613 values and 1,613 headers |

Sources: the official [production aggregate endpoint](https://hcd.rtpnc.epa.gov/api/descriptors), the official [staging aggregate endpoint](https://cim.sciencedataexperts.com/api/descriptors), and the dated [API compatibility run](https://github.com/seanthimons/ComptoxR/actions/runs/31387430057). The scheduled run independently found that production header-bearing RDKit GET and POST failed while the same staging and development checks passed.

All four production RDKit and Mordred failures returned `application/json` and the same fields:

```json
{
  "timestamp": "<request time>",
  "status": 400,
  "error": "Bad Request",
  "message": "400 BAD_REQUEST",
  "path": "/api/descriptors"
}
```

The response does not identify the engine, invalid field, failed dependency, or server validation rule. The issue should include this shape and ask for a diagnostic error or request correlation identifier.

## OpenAPI and discovery gaps

The official [production OpenAPI document](https://hcd.rtpnc.epa.gov/api/descriptors/api-docs) and [staging OpenAPI document](https://cim.sciencedataexperts.com/api/descriptors/api-docs) were reachable without credentials. The Swagger UIs are also public at the production [Swagger URL](https://hcd.rtpnc.epa.gov/api/descriptors/swagger) and staging [Swagger URL](https://cim.sciencedataexperts.com/api/descriptors/swagger). A schema check downloaded all three deployment schemas on 2026-08-10 and found no change from the repository copies ([workflow run](https://github.com/seanthimons/ComptoxR/actions/runs/31375144935)).

Both documents report OpenAPI 3.1.0, `Descriptors Module`, and API version 1.0.0. Both define GET and POST on `/api/descriptors`. The GET document defines `headers` as an optional boolean with default `false`. The POST document refers to `DescriptorsRequest`, but it does not mark any body property as required. The request fields are `type`, `chemicals`, `chemIdType`, `format`, and `options` ([production schema lines 38-78](https://github.com/seanthimons/ComptoxR/blob/0b9306aa43e264211f343234838da4dc297a1a45/schema/chemi-descriptors-prod.json#L38-L78), [operation lines 113-209](https://github.com/seanthimons/ComptoxR/blob/0b9306aa43e264211f343234838da4dc297a1a45/schema/chemi-descriptors-prod.json#L113-L209)).

The documents have these gaps:

- `type` is an unconstrained string. It does not list valid engine names.
- Production metadata lists only `padel` and `toxprints`. Staging metadata adds `webtest`. Neither lists `rdkit` or `mordred`, although both deployments accept those values when `headers=false`. This confirms the discovery gap in [#166](https://github.com/seanthimons/ComptoxR/issues/166).
- Production defines `options.additionalProperties` as `{ "type": "object" }`. Staging uses `{}`. Boolean `headers` and integer `timeout` values do not match the production description.
- The same production/staging difference exists for `DescriptorsMeta.options`, so metadata cannot define scalar engine options correctly.
- GET and POST document only a 200 response with an unconstrained object. They do not document the 400 response, `info`, `headers`, `chemicals`, or the rule that the header count must equal the descriptor count.
- The operations have no useful summary or description and have an empty tag.

The production and staging OpenAPI documents are otherwise byte-equivalent after normalization of the two `additionalProperties` fragments. This makes the fragment difference a small and specific production drift item.

## Deployment details that can help diagnosis

Production and staging both report the descriptors module as version 1.0.0. However, [production `/version`](https://hcd.rtpnc.epa.gov/api/descriptors/version) reports a compile time of `1970-01-01T00:00:00.000+00:00`. [Staging `/version`](https://cim.sciencedataexperts.com/api/descriptors/version) reports `2026-07-09T21:04:36.000+00:00`.

The epoch value does not prove that production uses an old binary. It does show that production build provenance is not set. The developer can compare the deployed image digest, build commit, and header-path configuration with staging.

Staging successful responses report RDKit 2025.09.1 and Mordred 1.2.0 in `info`. The issue should ask production to include the same engine version details when a request succeeds.

## Relationship to the other issues

- [#165](https://github.com/seanthimons/ComptoxR/issues/165) is a separate production deployment fault. The dedicated production Mordred version, metadata, GET, and POST checks still failed in the 2026-08-10 compatibility run. The aggregate service can still compute 1,613 Mordred values when `headers=false`. The API developer should check whether aggregate `headers=true` calls the unhealthy dedicated Mordred service or its metadata route. This is a hypothesis, not a confirmed cause.
- [#166](https://github.com/seanthimons/ComptoxR/issues/166) is the discovery and schema part of this report. The aggregate service accepts hidden `rdkit` and `mordred` engine values, but metadata and the OpenAPI `type` field do not list them.
- [#262](https://github.com/seanthimons/ComptoxR/issues/262) tracks the client repair and fallback rules. Current ComptoxR code routes production header-bearing aggregate Mordred requests to the staging dedicated Mordred service. It routes production header-bearing aggregate RDKit requests to the production dedicated RDKit service ([fallback code](https://github.com/seanthimons/ComptoxR/blob/0b9306aa43e264211f343234838da4dc297a1a45/R/hooks_descriptors.R#L541-L596)). These client fallbacks reduce user impact, but they do not resolve the production API defect.

## Recommended update to issue #169

Edit the issue body instead of adding only another narrowing comment. The current body still says POST generally fails and that production works only in a narrow GET mode. That statement is no longer correct.

Add these items:

1. Use `CCO` with `chemIdType=SMILES` in the minimum reproduction.
2. Add the paired production control matrix from this note.
3. Include PadEL as the working `headers=true` control.
4. Include the exact generic 400 response shape.
5. Link the live production and staging OpenAPI documents.
6. Call out the production `options.additionalProperties` schema difference.
7. Cross-link #165, #166, and #262 with the distinctions above.
8. Replace the `/home/.../inbox/` references. Those files and the `inbox/` directory do not exist and have no tracked history at current main commit [`0b9306a`](https://github.com/seanthimons/ComptoxR/tree/0b9306aa43e264211f343234838da4dc297a1a45). Put the compact evidence in the issue itself because action artifacts also expire.

Suggested upstream acceptance criteria:

- Production RDKit and Mordred GET and POST return 200 for the paired `headers=true` requests.
- Each successful response has one header for each descriptor value.
- `headers=false` behavior stays unchanged.
- `/descriptors/metadata` lists every accepted aggregate engine and its supported options.
- OpenAPI enumerates the supported `type` values and defines scalar option properties.
- OpenAPI defines successful JSON response fields and the 400 error response.
- A failed request identifies the failed engine and reason, or returns a correlation identifier that the developer can trace.

## Repository evidence

- The permanent probe sends the same header-bearing RDKit GET and POST controls and classifies direct upstream failures separately from wrapper failures ([probe source](https://github.com/seanthimons/ComptoxR/blob/0b9306aa43e264211f343234838da4dc297a1a45/dev/probe_api_compatibility.R#L225-L273)).
- Current wrapper tests lock the dedicated fallbacks and their provenance ([test source](https://github.com/seanthimons/ComptoxR/blob/0b9306aa43e264211f343234838da4dc297a1a45/tests/testthat/test-chemi_descriptor_contracts.R#L285-L329)).
- The production and staging schema snapshots differ only in the two `additionalProperties` definitions. The snapshots were last changed by the automated schema update commit [`15cd572`](https://github.com/seanthimons/ComptoxR/commit/15cd5723499763a1e6f1bd4d2a64189d289be588), and the 2026-08-10 schema check found no later upstream change.

## Validation

No package tests were needed because this task did not change package code. Validation used:

- direct unauthenticated GET and POST requests to production and staging;
- direct reads of metadata, version, Swagger, and OpenAPI endpoints;
- the 2026-08-10 schema-update run;
- the 2026-08-10 API compatibility artifact;
- local source, tests, issue history, and Git history at commit `0b9306a`.
