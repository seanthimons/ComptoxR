---
created: "2026-03-03T16:15:00.000Z"
title: Check if stub generation captures API schema descriptions
area: tooling
files:
  - dev/endpoint_eval/07_stub_generation.R
  - dev/generate_stubs.R
---

## Problem

The stub generation pipeline may not be extracting description text, parameter descriptions, and other human-readable documentation from the OpenAPI/Swagger schemas. If these are available in the schemas, they should be pulled into the generated roxygen documentation automatically — reducing the amount of manual documentation work needed when promoting stubs to stable.

## Solution

1. Audit what text fields exist in the API schemas (summary, description, parameter descriptions, response descriptions)
2. Check what `openapi_to_spec()` currently extracts vs. what's available
3. Check what `build_function_stub()` / roxygen templates currently use
4. If gaps exist — enhance the pipeline to pull descriptions into `@param`, `@description`, `@details`, and `@return` roxygen tags
5. Goal: minimize manual documentation effort when promoting experimental stubs to stable
