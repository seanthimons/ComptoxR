# Missing ComptoxR Functions Analysis

This document compares API endpoints from the ctx_*.json schema files with existing R functions to identify gaps in coverage.

## Summary

- **Total Schema Endpoints Analyzed**: ~100+
- **Existing Functions**: 24 ct_* functions
- **Missing Function Categories**: 4 major areas

---

## 1. BIOACTIVITY - Missing Functions

### Implemented ✅

- `ct_bioactivity()` - Bioactivity data search by DTXSID/AEID/SPID/M4ID
- `ct_bio_assay_all()` - Get all assays

### Missing ❌

#### ct_bio_assay_search()

- `/bioactivity/search/start-with/{value}` - Search assays by starting value
- `/bioactivity/search/equal/{value}` - Search assays by exact value
- `/bioactivity/search/contain/{value}` - Search assays by substring

#### ct_bio_summary()

- `/bioactivity/data/summary/search/by-dtxsid/{dtxsid}` - Get summary by DTXSID
- `/bioactivity/data/summary/search/by-aeid/{aeid}` - Get summary by AEID
- `/bioactivity/data/summary/search/by-tissue/` - Get summary by tissue and DTXSID

#### ct_bio_aed()

- `/bioactivity/data/aed/search/by-dtxsid/{dtxsid}` - Get AED data by DTXSID
- `/bioactivity/data/aed/search/by-dtxsid/` (POST) - Batch get AED data

#### ct_bio_assay_by_gene()

- `/bioactivity/assay/search/by-gene/{geneSymbol}` - Get assay endpoints by gene

#### ct_bio_assay_single_conc()

- `/bioactivity/assay/single-conc/search/by-aeid/{aeid}` - Get single concentration data

#### ct_bio_assay_chemicals()

- `/bioactivity/assay/chemicals/search/by-aeid/{aeid}` - Get list of DTXSIDs by AEID

#### ct_bio_assay_count()

- `/bioactivity/assay/count` - Get count of all available assays

#### ct_bio_aop()

- `/bioactivity/aop/search/by-toxcast-aeid/{toxcastAeid}` - Get AOP by ToxCast AEID
- `/bioactivity/aop/search/by-event-number/{eventNumber}` - Get AOP by event number
- `/bioactivity/aop/search/by-entrez-gene-id/{entrezGeneId}` - Get AOP by Entrez gene ID

#### ct_analytical_qc()

- `/bioactivity/analyticalqc/search/by-dtxsid/{dtxsid}` - Get analytical QC data

---

## 2. CHEMICAL - Missing Functions

### Implemented ✅

- `ct_search()` - Chemical search (equal, starts, contains)
- `ct_details()` - Chemical details by DTXSID/DTXCID
- `ct_synonym()` - Synonym search
- `ct_properties()` - Chemical properties
- `ct_env_fate()` - Chemical fate data
- `ct_lists_all()` - Get all public lists
- `ct_compound_in_list()` - Find lists containing compound
- `ct_file()` - Get MOL file
- `ct_descriptors()` - Indigo conversion services

### Missing ❌

#### ct_wikipedia()

- `/chemical/wikipedia/by-dtxsid/{dtxsid}` - Get Wikipedia data
- `/chemical/wikipedia/by-dtxsid/` (POST) - Batch get Wikipedia data

#### ct_msready()

- `/chemical/msready/search/by-mass/{start}/{end}` - Search MS-ready by mass range
- `/chemical/msready/search/by-mass/` (POST) - Batch search MS-ready by mass
- `/chemical/msready/search/by-formula/{formula}` - Search MS-ready by formula
- `/chemical/msready/search/by-dtxcid/{dtxcid}` - Search MS-ready by DTXCID

#### ct_formula_search()

- `/chemical/search/by-msready-formula/{formula}` - Search by MS-ready formula
- `/chemical/search/by-exact-formula/{formula}` - Search by exact formula
- `/chemical/count/by-msready-formula/{formula}` - Count by MS-ready formula
- `/chemical/count/by-exact-formula/{formula}` - Count by exact formula

#### ct_property_summary()

- `/chemical/property/summary/search/by-dtxsid/{dtxsid}` - Get property summary
- `/chemical/property/summary/search/` (GET with params) - Get property summary with filters

#### ct_property_range_search()

- `/chemical/property/predicted/search/by-range/{propertyId}/{start}/{end}` - Search by predicted property range
- `/chemical/property/experimental/search/by-range/{propertyName}/{start}/{end}` - Search by experimental property range

#### ct_property_names()

- Already have `.prop_ids()` but could be exported as `ct_property_names()`
- `/chemical/property/predicted/name` - Get predicted property names
- `/chemical/property/experimental/name` - Get experimental property names

#### ct_opsin()

- `/chemical/opsin/to-smiles/{name}` - Convert name to SMILES using OPSIN
- `/chemical/opsin/to-inchikey/{name}` - Convert name to InChIKey using OPSIN
- `/chemical/opsin/to-inchi/{name}` - Convert name to InChI using OPSIN

#### ct_ghs_link()

- `/chemical/ghslink/to-dtxsid/{dtxsid}` - Get GHS link by DTXSID
- `/chemical/ghslink/to-dtxsid/` (POST) - Batch get GHS links

#### ct_image_generate()

- `/chemical/file/image/generate` - Generate chemical structure image
- `/chemical/file/image/search/by-gsid/{gsid}` - Get image by GSID

#### ct_file_mrv()

- `/chemical/file/mrv/search/by-dtxsid/{dtxsid}` - Get MRV file by DTXSID
- `/chemical/file/mrv/search/by-dtxcid/{dtxcid}` - Get MRV file by DTXCID

#### ct_extra_data()

- `/chemical/extra-data/search/by-dtxsid/{dtxsid}` - Get extra data by DTXSID
- `/chemical/extra-data/search/by-dtxsid/` (POST) - Batch get extra data

#### ct_fate_summary()

- `/chemical/fate/summary/search/by-dtxsid/{dtxsid}` - Get fate summary by DTXSID
- `/chemical/fate/summary/search/` (GET with params) - Get fate summary with filters

#### ct_list_type()

- `/chemical/list/type` - Get list types
- `/chemical/list/search/by-type/{type}` - Search lists by type
- `/chemical/list/search/by-name/{listName}` - Search list by name

#### ct_list_search_chemicals()

- `/chemical/list/chemicals/search/start-with/{list}/{word}` - Search chemicals in list (starts with)
- `/chemical/list/chemicals/search/equal/{list}/{word}` - Search chemicals in list (exact)
- `/chemical/list/chemicals/search/contain/{list}/{word}` - Search chemicals in list (contains)
- `/chemical/list/chemicals/search/by-listname/{list}` - Get all chemicals in list

#### ct_chemical_all()

- `/chemical/all` - Get all chemicals (paginated)

---

## 3. EXPOSURE - Missing Functions

### Implemented ✅

- `ct_functional_use()` - Functional use data (partial coverage)

### Missing ❌

#### ct_expo_seem_general()

- `/exposure/seem/general/search/by-dtxsid/{dtxsid}` - Get general exposure prediction
- `/exposure/seem/general/search/by-dtxsid/` (POST) - Batch get general predictions

#### ct_expo_seem_demographic()

- `/exposure/seem/demographic/search/by-dtxsid/{dtxsid}` - Get demographic exposure prediction
- `/exposure/seem/demographic/search/by-dtxsid/` (POST) - Batch get demographic predictions

#### ct_expo_product_data()

- `/exposure/product-data/search/by-dtxsid/{dtxsid}` - Get product data
- `/exposure/product-data/search/by-dtxsid/` (POST) - Batch get product data
- `/exposure/product-data/puc` - Get all PUC (Product Use Category) data

#### ct_expo_list_presence()

- `/exposure/list-presence/search/by-dtxsid/{dtxsid}` - Get list presence data
- `/exposure/list-presence/search/by-dtxsid/` (POST) - Batch get list presence
- `/exposure/list-presence/tags` - Get list presence tags

#### ct_expo_httk()

- `/exposure/httk/search/by-dtxsid/{dtxsid}` - Get HTTK data
- `/exposure/httk/search/by-dtxsid/` (POST) - Batch get HTTK data

#### ct_expo_functional_use_probability()

- `/exposure/functional-use/probability/search/by-dtxsid/{dtxsid}` - Get functional use probability

#### ct_expo_functional_use_category()

- `/exposure/functional-use/category` - Get functional use categories

#### ct_expo_mmdb_single_sample()

- `/exposure/mmdb/single-sample/by-dtxsid/{dtxsid}` - Get MMDB single-sample by DTXSID
- `/exposure/mmdb/single-sample/by-medium` - Get MMDB single-sample by medium

#### ct_expo_mmdb_aggregate()

- `/exposure/mmdb/aggregate/by-dtxsid/{dtxsid}` - Get MMDB aggregate by DTXSID
- `/exposure/mmdb/aggregate/by-medium` - Get MMDB aggregate by medium

#### ct_expo_mmdb_mediums()

- `/exposure/mmdb/mediums` - Get all harmonized media categories

#### ct_expo_ccd_puc()

- `/exposure/ccd/puc/search/by-dtxsid/{dtxsid}` - Get Product Use Category

#### ct_expo_ccd_production_volume()

- `/exposure/ccd/production-volume/search/by-dtxsid/{dtxsid}` - Get production volume

#### ct_expo_ccd_monitoring()

- `/exposure/ccd/monitoring-data/search/by-dtxsid/{dtxsid}` - Get biomonitoring data

#### ct_expo_ccd_keywords()

- `/exposure/ccd/keywords/search/by-dtxsid/{dtxsid}` - Get general use keywords

#### ct_expo_ccd_functional_use()

- `/exposure/ccd/functional-use/search/by-dtxsid/{dtxsid}` - Get reported functional use

#### ct_expo_ccd_weight_fractions()

- `/exposure/ccd/chem-weight-fractions/search/by-dtxsid/{dtxsid}` - Get chemical weight fractions

---

## 4. HAZARD - Missing Functions

### Implemented ✅

- `ct_hazard()` - Hazard/ToxVal data
- `ct_cancer()` - Cancer summary data
- `ct_genotox()` - Genotoxicity details
- `ct_skin_eye()` - Skin and eye hazard data

### Missing ❌

#### ct_genotox_summary()

- `/hazard/genetox/summary/search/by-dtxsid/{dtxsid}` - Get genotox summary
- `/hazard/genetox/summary/search/by-dtxsid/` (POST) - Batch get genotox summary
- Note: Currently have `ct_genotox()` which gets details, not summary

#### ct_toxref()

- `/hazard/toxref/search/by-dtxsid/` (POST) - Batch get ToxRef data
- `/hazard/toxref/summary/search/by-dtxsid/{dtxsid}` - Get ToxRef summary
- `/hazard/toxref/summary/search/by-study-type/{studyType}` - Get ToxRef summary by study type
- `/hazard/toxref/summary/search/by-study-id/{studyId}` - Get ToxRef summary by study ID

#### ct_toxref_observations()

- `/hazard/toxref/observations/search/by-dtxsid/{dtxsid}` - Get ToxRef observations
- `/hazard/toxref/observations/search/by-study-type/{studyType}` - Get observations by study type
- `/hazard/toxref/observations/search/by-study-id/{studyId}` - Get observations by study ID

#### ct_toxref_effects()

- `/hazard/toxref/effects/search/by-dtxsid/{dtxsid}` - Get ToxRef effects
- `/hazard/toxref/effects/search/by-study-type/{studyType}` - Get effects by study type
- `/hazard/toxref/effects/search/by-study-id/{studyId}` - Get effects by study ID

#### ct_toxref_data()

- `/hazard/toxref/data/search/by-dtxsid/{dtxsid}` - Get ToxRef data
- `/hazard/toxref/data/search/by-study-type/{studyType}` - Get data by study type
- `/hazard/toxref/data/search/by-study-id/{studyId}` - Get data by study ID

#### ct_pprtv()

- `/hazard/pprtv/search/by-dtxsid/{dtxsid}` - Get PPRTV (Provisional Peer Reviewed Toxicity Values)

#### ct_iris()

- `/hazard/iris/search/by-dtxsid/{dtxsid}` - Get IRIS (Integrated Risk Information System) data

#### ct_hawc()

- `/hazard/hawc/search/by-dtxsid/{dtxsid}` - Get HAWC (Health Assessment Workspace Collaborative) data

#### ct_adme_ivive()

- `/hazard/adme-ivive/search/by-dtxsid/{dtxsid}` - Get ADME-IVIVE data

---

## Priority Recommendations

### Immediate Additions

1. ct_lists_all.R - Uses GET(), add_headers(), content(), fromJSON()
2. ct_file.R - Uses GET(), add_headers(), content()
3. ct_descriptors.R - Uses POST(), add_headers(), content()
4. ct_compound_in_list.R - Uses GET(), add_headers(), content()
5. ct_test.R - Uses VERB(), content(), fromJSON() (contains both ct_test() and ct_opera() functions)

### High Priority (Most Useful)

1. **ct_expo_seem_general()** / **ct_expo_seem_demographic()** - Exposure predictions
2. **ct_expo_httk()** - High-throughput toxicokinetics data
3. **ct_toxref()** family - ToxRef database access
4. **ct_bio_summary()** - Bioactivity summaries
5. **ct_iris()** / **ct_pprtv()** - Important hazard assessment data

### Medium Priority (Useful for specific analyses)

6. **ct_expo_mmdb_*()** - Environmental monitoring data
7. **ct_bio_aed()** - Activity-exposure dose relationships
8. **ct_expo_ccd_*()** - Dashboard-specific exposure data
9. **ct_property_summary()** - Comprehensive property summaries
10. **ct_list_search_chemicals()** - Advanced list searching

### Low Priority (Specialized/Less Common)

11. **ct_opsin()** - Name-to-structure conversion (specialized use)
12. **ct_msready()** - Mass spec ready structures (specialized use)
13. **ct_ghs_link()** - GHS classification links
14. **ct_wikipedia()** - Wikipedia integration
15. **ct_image_generate()** - Image generation (may be better handled client-side)

---

## Implementation Notes

- All missing functions should follow the httr2 migration pattern
- Add batch processing support where POST endpoints exist
- Include `run_debug` and `run_verbose` environment variable controls
- Follow consistent naming conventions: `ct_<domain>_<resource>()`
- Include proper error handling and input validation
- Document each function with roxygen2 comments
