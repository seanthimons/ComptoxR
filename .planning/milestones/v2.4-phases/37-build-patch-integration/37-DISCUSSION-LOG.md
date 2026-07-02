# Phase 37: Build & Patch Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 37-build-patch-integration
**Areas discussed:** Build-script sync evidence, Patch refresh behavior, Windows retry validation, Patch metadata contract

---

## Build-Script Sync Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Literal diff test only | Keep the existing extracted section 16 character-identity test as the source of truth. | |
| Diff test plus dev validation output | Keep the test and add a Phase 37 validation script/report that prints the extracted diff result. | |
| Refactor to shared script/source file | Remove duplicated resolver/materialization logic from build scripts and have both call shared internal package behavior. | Yes |

**User's choice:** Shared internal package behavior, with both build scripts kept thin.
**Notes:** The user clarified that record edits must remain CSV-only. The shared R function is behavior/orchestration, not an end-user editing surface. The desired end state is a single internal function/path that patches the existing lifestage tables and can resolve new lifestages before repatching.

### Wrapper Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Thin section 16 wrapper | Both scripts extract lifestages, determine release, call shared internal materialization logic, and write dictionary/review tables. | Yes |
| Single helper owns all section 16 work | Both scripts call one helper that reads lifestages from the connection and writes both tables. | |
| Patch function reused directly | Build scripts persist first, then call `.eco_patch_lifestage()` on the DuckDB file. | |

**User's choice:** Option 1.
**Notes:** The wrapper keeps build-script context local but removes duplicated resolver/materialization behavior.

### Regression Protection

| Option | Description | Selected |
|--------|-------------|----------|
| Helper-call identity test | Verify both section 16 wrappers are still character-identical. | Yes |
| Behavioral build-path test | Simulate section 16 against a temp DB and assert dictionary/review tables are written. | |
| Both identity and behavioral tests | Strongest protection, with more test code. | |

**User's choice:** Option 1 after discussing likely regressions.
**Notes:** The main risk is drift between `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R`: different refresh mode, missing review write, different cache behavior, different release calculation, or stale inline logic in one path.

---

## Patch Refresh Behavior

### Auto Mode Baseline Fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Use baseline without live calls | If no matching cache exists but a matching committed baseline exists, seed from baseline and patch. | Yes |
| Try live first, then baseline | Freshest possible, but depends on provider availability. | |
| Abort and ask for explicit mode | Safest from surprise behavior, but less convenient. | |

**User's choice:** Option 1.
**Notes:** Cold-start installs should be deterministic.

### Live Resolution Trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Only explicit `refresh = "live"` | Never surprise-hit live APIs from patching. | Yes |
| Auto only if cache and baseline missing/incomplete | Best-effort fallback, but introduces network behavior into auto. | |
| Whenever `force = TRUE` | Force means bypass local artifacts and hit live APIs. | |

**User's choice:** Option 1.
**Notes:** Later force semantics were also locked as live lookup.

### Baseline Release Mismatch

| Option | Description | Selected |
|--------|-------------|----------|
| Abort with release mismatch | Refuse cross-release patching. | Yes |
| Warn and patch matching rows only | Permissive, but can leave ambiguous gaps. | |
| Fall back to live resolution | Helpful but violates explicit baseline mode. | |

**User's choice:** Option 1.
**Notes:** No silent cross-release baseline use.

### Force Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Relax strict local modes into auto-like fallback | Missing local artifacts fall through local sources, no live calls unless live mode. | |
| Force live lookup | Bypass cache/baseline and resolve through live providers. | Yes |
| Force table overwrite only | Ignore existing table state but not refresh-source errors. | |

**User's choice:** Option 2: "force is force."
**Notes:** Tests should mock provider calls for `force = TRUE`; messages/docs should make clear that force can use the network.

---

## Windows Retry Validation

### Retry Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Retry read-write connect only | Wrap only `DBI::dbConnect(... read_only = FALSE)` with retries. | |
| Retry all patch DB writes | Retry connection plus table writes and metadata writes. | |
| Retry close-then-connect sequence | Call `.eco_close_con()`, sleep, then connect across attempts. | Yes |

**User's choice:** Option 3 after asking for the most durable and defensible option.
**Notes:** The known Windows failure is stale/read connection contention before opening a write connection. Retrying later writes would hide real schema/data failures.

### Validation Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Mock `DBI::dbConnect()` to fail twice, then succeed | Deterministically proves the 3-attempt loop. | Yes |
| Real temp DuckDB contention test | Closer to Windows behavior, but can be flaky. | |
| Both, with real contention skipped unless on Windows | Broadest confidence, more complexity. | |

**User's choice:** Option 1.
**Notes:** No flaky real-lock test required for this phase.

### Exhausted Retries

| Option | Description | Selected |
|--------|-------------|----------|
| Abort with patch-specific message plus last DBI error | Explains the write-open failure while preserving the real cause. | Yes |
| Warn and skip patching | Avoids crash but leaves stale tables. | |
| Fall back to read-only inspection | Can diagnose but does not complete patch. | |

**User's choice:** Option 1.
**Notes:** Failed patch should not silently leave stale lifestage tables.

---

## Patch Metadata Contract

### Metadata Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Four key-value rows | `lifestage_patch_applied_at`, `lifestage_patch_release`, `lifestage_patch_method`, `lifestage_patch_version`. | Yes |
| Single JSON-like metadata row | Compact, but inconsistent with current key-value metadata. | |
| Separate patch history table | Preserves multiple patch events, but adds schema surface. | |

**User's choice:** Option 1.
**Notes:** This matches the existing ECOTOX `_metadata` table shape.

### Existing Patch Rows

| Option | Description | Selected |
|--------|-------------|----------|
| Replace current patch metadata rows | `_metadata` reflects latest patch only. | Yes |
| Append duplicate patch metadata rows | Keeps history but makes current value ambiguous. | |
| Abort if patch metadata already exists | Strict, but prevents normal repatching. | |

**User's choice:** Option 1.
**Notes:** Patch history table is out of scope.

### Validation Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Validate presence and values | Require all four keys, non-empty values, method equals actual refresh mode, release equals DB release, version is package version. | Yes |
| Validate presence only | Enough to prove metadata was written, less brittle. | |
| Validate timestamp format too | Strongest, but more fiddly. | |

**User's choice:** Option 1.
**Notes:** Timestamp must be non-empty, but strict timestamp-format validation was not selected.

---

## Agent's Discretion

- Exact helper names and extraction boundaries.
- Exact test organization, provided durable gates live in testthat.
- Exact CLI wording for patch messages.

## Deferred Ideas

- Exporting patch capability as a public API.
- Patch history table.
- Real DuckDB lock-contention integration tests.
