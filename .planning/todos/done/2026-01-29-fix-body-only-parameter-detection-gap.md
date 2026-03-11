---
created: 2026-01-29T15:30
title: Fix body-only endpoint parameter detection gap
area: tooling
files:
  - dev/endpoint_eval/07_stub_generation.R:635
  - dev/endpoint_eval/07_stub_generation.R:32-106
---

## Problem

The v1.4 milestone implemented `is_empty_post_endpoint()` to detect and skip POST endpoints with truly empty body schemas (null, empty object, missing properties). However, there's a gap where endpoints pass detection but still fail during stub generation with:

```
Error: Body-only endpoint must have at least one parameter
```

This occurs when:
1. The endpoint IS a POST with `is_body_only = TRUE`
2. The body schema EXISTS (so not "empty" by detection logic)
3. But the schema yields ZERO extractable function parameters

Example problematic schemas:
- `{"type": "array", "items": {"type": "string"}}` - simple string array
- `{"type": "array", "items": {"type": "integer"}}` - simple integer array
- Complex nested schemas without named properties at root level

The detection at lines 59-73 checks for empty body but doesn't account for schemas that exist but can't produce named parameters for the function signature.

## Solution

Two possible approaches:

1. **Expand detection** (`is_empty_post_endpoint`): Add checks for body schemas that exist but have no extractable properties:
   - Array type with primitive items (no named params)
   - Objects with only `additionalProperties` and no `properties`

2. **Graceful handling** in `build_function_stub`: Instead of `stop()` at line 635, skip/warn and track these endpoints similar to empty POST handling.

Recommendation: Approach 1 is cleaner - detect earlier in pipeline rather than fail late.
