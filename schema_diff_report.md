### Endpoint Changes

**Summary:** 86 endpoints added, 16 removed, 9 modified across 17 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-amos-prod.json | GET /api/amos/analytical_qc_list/ | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/analytical_qc_pagination/{limit}/{offset} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/dtxsids_for_functional_use/{functional_use} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/fact_sheet_list | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/fact_sheet_pagination/{limit}/{offset} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/fact_sheets_for_substance/{dtxsid} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/get_image_for_dtxsid/{dtxsid} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/get_similar_structures/{dtxsid} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/method_list | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/method_pagination/{limit}/{offset} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | GET /api/amos/substance_similarity_search/{dtxsid} | Removed | Endpoint no longer exists |
| chemi-amos-prod.json | POST /api/amos/analytical_qc_batch_search | Modified | body params removed: [dtxsids] |
| chemi-amos-prod.json | POST /api/amos/batch_search | Modified | body params removed: [dtxsids] |
| chemi-safety-prod.json | GET /api/safety/classes | Removed | Endpoint no longer exists |
| chemi-safety-prod.json | GET /api/safety/hcodes | Removed | Endpoint no longer exists |
| chemi-safety-prod.json | GET /api/safety/pcodes | Removed | Endpoint no longer exists |
| chemi-safety-prod.json | GET /api/safety/statements | Removed | Endpoint no longer exists |
| chemi-search-prod.json | POST /api/search/lookup | Removed | Endpoint no longer exists |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-amos-prod.json | GET /api/amos/analytical_qc_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/analytical_qc_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/dtxsids/ | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/dtxsids_from_functional_use/{functional_use} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/fact_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/fact_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/functional_class_search/{functional_class} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/get_fact_sheet_editor_info/{internal_id} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/get_method_editor_info/{internal_id} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/get_nmr_spectrum_editor_info/{internal_id} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/get_product_declaration_editor_info/{internal_id} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/get_safety_data_sheet_editor_info/{internal_id} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/get_similar_structures/{identifier_type}/{identifier} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/list_fact_sheet_types/ | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/list_functional_classes | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/list_sources_by_record_type/{record_type} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/method_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/method_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/product_declaration_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/product_declaration_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/record_ids_for_substance/{dtxsid}/{record_type} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/release_notes | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/retrieve_fact_sheets/ | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/retrieve_product_declarations/ | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/retrieve_safety_data_sheets/ | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/safety_data_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/safety_data_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-prod.json | GET /api/amos/search_by_text/{substr} | Added | New endpoint |
| chemi-amos-prod.json | POST /api/amos/search_for_document_ids/{record_type} | Added | New endpoint |
| chemi-resolver-prod.json | GET /api/resolver/ghs-list | Added | New endpoint |
| chemi-resolver-prod.json | GET /api/resolver/ghs-list-count | Added | New endpoint |
| chemi-resolver-prod.json | POST /api/resolver/ghs-list-count | Added | New endpoint |
| chemi-resolver-prod.json | GET /api/resolver/ghs/classes | Added | New endpoint |
| chemi-resolver-prod.json | GET /api/resolver/ghs/hcodes | Added | New endpoint |
| chemi-resolver-prod.json | GET /api/resolver/ghs/pcodes | Added | New endpoint |
| chemi-resolver-prod.json | GET /api/resolver/hcodes | Added | New endpoint |
| chemi-resolver-prod.json | POST /api/resolver/safety-flags | Modified | body params added: [additionalProps, id] |
| chemi-safety-prod.json | POST /api/safety/rqcodes | Modified | body params added: [additionalProps, id] |
| chemi-search-prod.json | POST /api/search | Modified | body params added: [hazardNames, maxNumber, minNumber] |
| chemi-search-prod.json | GET /api/search/similar | Modified | params added: [dtxsid] |
| chemi-services-prod.json | GET /api/services/cim_component_info | Added | New endpoint |
| chemi-services-prod.json | POST /api/services/collated_report | Added | New endpoint |
| chemi-services-prod.json | GET /api/services/release_notes | Added | New endpoint |
| chemi-toxprints-prod.json | POST /api/toxprints/calculate | Modified | params added: [request.options.or, request.options.pv1, request.options.tp] |
| chemi-webtest-prod.json | POST /api/webtest | Modified | body params added: [chemIdType] |
| chemi-webtest-prod.json | POST /api/webtest/predict | Modified | body params added: [chemicals] |
| chemi-amnb_nate-prod.json | GET /api/amnb_nate | Added | New endpoint |
| chemi-amnb_nate-prod.json | POST /api/amnb_nate | Added | New endpoint |
| chemi-arn_cats-prod.json | GET /api/arn_cats | Added | New endpoint |
| chemi-arn_cats-prod.json | POST /api/arn_cats | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/{chemical_id}/image | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/alias | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/chemset | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/counts | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/database | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/database-old | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/database/stats | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/maps | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/singlechemical | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/suggest | Added | New endpoint |
| chemi-chet-prod.json | GET /chemicals/verify/{dtxsid} | Added | New endpoint |
| chemi-chet-prod.json | POST /reaction/batchsearch | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/database | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/database_old | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/database-old/{pagenum}/{searchterm} | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/database/stats | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/dbcounts | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/details | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/libraries | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/mapid | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/mappositions/{map_id} | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/maps | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/react_maps | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/reactionmap | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/search | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/searchcounts/{search_input}/{search_type} | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/singlereaction | Added | New endpoint |
| chemi-chet-prod.json | GET /reaction/table | Added | New endpoint |
| chemi-mordred-prod.json | GET /api/mordred | Added | New endpoint |
| chemi-mordred-prod.json | POST /api/mordred | Added | New endpoint |
| chemi-ncc_cats-prod.json | GET /api/ncc_cats | Added | New endpoint |
| chemi-ncc_cats-prod.json | POST /api/ncc_cats | Added | New endpoint |
| chemi-opera-prod.json | GET /api/opera | Added | New endpoint |
| chemi-opera-prod.json | POST /api/opera | Added | New endpoint |
| chemi-opera-prod.json | GET /api/opera/report | Added | New endpoint |
| chemi-pfas_atlas-prod.json | GET /api/pfas_atlas | Added | New endpoint |
| chemi-pfas_atlas-prod.json | POST /api/pfas_atlas | Added | New endpoint |
| chemi-pfas_cats-prod.json | GET /api/pfas_cats | Added | New endpoint |
| chemi-pfas_cats-prod.json | POST /api/pfas_cats | Added | New endpoint |
| chemi-predictor_models-prod.json | GET /api/predictor_models/predict | Added | New endpoint |
| chemi-predictor_models-prod.json | POST /api/predictor_models/predict | Added | New endpoint |
| chemi-rdkit-prod.json | GET /api/rdkit | Added | New endpoint |
| chemi-rdkit-prod.json | POST /api/rdkit | Added | New endpoint |
