---
created: "2026-03-03T16:13:54.553Z"
title: Check on .baseline folder showing up
area: general
files: []
---

## Problem

A `.baseline` folder has been observed appearing in the project. Need to investigate what's creating it, whether it's from a tool, script, or workflow artifact. Determine if it should be gitignored, cleaned up, or if it serves a purpose.

## Solution

1. Check git history for when `.baseline` was first committed or appeared
2. Search scripts/workflows for references to `.baseline`
3. If artifact — add to `.gitignore` and remove
4. If intentional — document its purpose
