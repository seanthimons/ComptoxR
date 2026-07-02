---
status: complete
---

# Quick Task 260417-hm9: Move environment setup from .onAttach to .onLoad

## Summary
Fixed bug where environment variables (`ctx_burl`, `chemi_burl`, etc.) were not set when using namespace access (`ComptoxR::ct_hazard(...)`) without calling `library(ComptoxR)` first.

## Changes Made
- **R/zzz.R**: Moved server URL setup, verbose/debug defaults, and batch_limit initialization from `.onAttach()` to `.onLoad()`
- `.onAttach()` now only handles startup message display
- `.onLoad()` now sets up all environment variables so they're available regardless of how the package is accessed

## Root Cause
- `.onAttach()` only runs when using `library(ComptoxR)`
- `.onLoad()` runs for both `library()` AND namespace access (`ComptoxR::function()`)
- Environment setup was in the wrong hook

## Verification
Tested that `asNamespace("ComptoxR")` now correctly sets `ctx_burl` and `chemi_burl`:
```
SUCCESS: ctx_burl is set to: https://comptox.epa.gov/ctx-api/
SUCCESS: chemi_burl is set to: https://hcd.rtpnc.epa.gov/api
```
