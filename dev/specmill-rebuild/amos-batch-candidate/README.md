# Deferred AMOS XLSX candidates

The user explicitly deferred both migrations on 18 October 2026: "If they return xlsx then defer their migration until we can see if they need specialized behavior."

The current public chemi_amos_batch and chemi_amos_analytical_qc_batch implementations remain unchanged. Neither operation is counted as migrated. Successful source-example workbook results are archived separately in ../canonical-holds-audit/amos-batch-recheck. Those calls used direct read-only service requests, not these generated candidate wrappers.

This isolated exploratory candidate generates two operations on official Specmill0.1.42 with validationTRUE, freshness and ownership checks passing. Public names/order/defaults match. The separately named reviewed OAS3 source preserves selected operations verbatim and their component closure, explicitly selects production, and leaves the canonical Swagger2 snapshot unchanged. provenance.json records the exact hashes and proposed semantic repairs, including the private general-batch exclude_analytical_qc=false value. These repairs are proposals, not adopted decisions.

Behavior validation is incomplete. verify-incomplete.R reached the final configuration checks but failed because its expected condition class was wrong. Both failed logs are retained. There is no saved clean localhost result, no generated-wrapper deployed replay, and no completed behavior/adoption claim. The unexecuted live-replay script was removed after the deferral. Candidate generated code is archived as .txt, outside package runtime; no root manifest, helper, exports or API configuration changed.

Future work must first decide the public XLSX return/file-handling behavior, then finish its behavior tests and explicit contract repair. Do not promote this archive or raw-byte return proposal merely because generation passes. No specialized workbook dependency has been added.
