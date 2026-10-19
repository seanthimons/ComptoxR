# Review of the v50 client iteration

Comparison: `git diff 253c38a2...dbaafea2`. The originating contract is ComptoxR issue311, the migration request and AGENTS.md. Two independent agents reviewed standards and contract behavior. They did not rerun tests or make service calls.

## Standards

No documented AGENTS.md or CONTRIBUTING.md breach was found. Generated wrappers, reviewed sources, the locked toolkit and ownership records follow the migration rules.

One P2 test-isolation heuristic was found in test-pubchem_retained_http.R. A fixed httr2 throttle realm survived between test invocations; its nearly disabled refill meant a second invocation could start with fewer than100 tokens while expecting97 after three requests. The test now creates a unique realm with tempfile(). It still proves that calls within one invocation share the actual httr2 pool and that warm cache hits consume no tokens. This changes only the test.

The repeat proof runs the complete PubChem suite twice in one R process against the installed package. Results are recorded in pubchem-repeat-proof.json. No additional actionable Fowler smells were found.

## Spec

No contract findings were found. The changes satisfy issue311's requirement to preserve names, argument order/defaults, return objects/classes, authentication, errors, hooks, batching, pagination and lifecycle badges, with the explicitly approved native credential/configuration errors.

Descriptor mappings retain complete hook state. PubChem mappings retain cache keys, cached-before-fresh ordering, chunk boundaries, lazy synonym formatting and complete default/custom URL prefixes. Frozen-original comparisons cover actual localhost requests and returned objects.

Retaining Toxprints bulk, deferring AMOS workbooks and withdrawing shared safety response ownership are authorized holds, consistent with the requirement to record behavior repairs separately. Existing descriptor CSV/TSV failures remain preserved and documented.

Standards: one P2 heuristic, fixed. Spec: zero findings. No runtime code changed in response to review.
