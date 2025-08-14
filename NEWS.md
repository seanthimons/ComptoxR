<!-- NEWS.md is maintained by https://cynkra.github.io/fledge, do not edit -->

# ComptoxR 1.2.2.9008

- Added inclusive searching feature for ct_related


# ComptoxR 1.2.2.9007

- Enhanced the run_debug() and set_verbose() functions to display informative alerts when debug or verbose modes are toggled, providing clearer feedback to users.
- Introduces util_classyfire.R for ClassyFire API classification of SMILES strings.
- Refactors ct_synonym() for improved error handling, debugging, and response parsing.
- Updates chemi_classyfire() to use environment variable for verbosity.
- Adds support for natural products server in zzz.R.
- Updates ct_classify() to better handle mixtures and unknowns.
- Minor improvements and code cleanup in chemi_cluster.R.
- Adds 'webchem' to DESCRIPTION suggests.
- chemi_classyfire now returns proper order for taxonomy.
- Added extract_mol_formula function to assist in curation
- Updated NAMESPACE, build schedule, and Helpers for intial loading.
- Updated ct_search to handle suggestions.


# ComptoxR 1.2.2.9006

- Same as previous version.


# ComptoxR 1.2.2.9005

- Added ct_functional_use; pulls reported and predicted usage from CCD dashboard.
- Added utility function for CASRN strings
- Added function to extract out molecular formulas


# ComptoxR 1.2.2.9004

- Updated ct_list to be default extract out DTXSIDs
- Added ct_related to find related substances. Subject to depreciation.
- Minor update to data files and ct_details.
- Added chemi_classyfire function for classification
- Added hclust_method parameter for chemi_cluster
- Added informative error messages to all *_server functions to indicate valid server options.
- Added chemi_safety_sections; retrieves PubChem datasheets.
- Added epi_suite functions to pull and search data
- Added new logic for servers and API endpoints
- Updated ct_search to remove mass + formula searching, rewrote backend with new helper function.
- Updated docuemenation for ct_search
- Adjustment to searching functions
- Updated two functions to remove rjson dependency.
- Minor update to data files and ct_details.
- Added chemi_classyfire function for classification
- Added hclust_method parameter for chemi_cluster
- Added informative error messages to all *_server functions to indicate valid server options.
- Added chemi_safety_sections; retrieves PubChem datasheets.
- Added epi_suite functions to pull and search data
- Added new logic for servers and API endpoints
- Updated ct_search to remove mass + formula searching, rewrote backend with new helper function.
- Updated docuemenation for ct_search
- Adjustment to searching functions
- Updated two functions to remove rjson dependency.


# ComptoxR 1.2.2.9003

- Updated ct_search to return suggestions
- Fixed chemi_search
- Clean up of ct_descriptors
- Added chemi_predict for TEST and OPERA results. Currently just a table, without organization.
- Updated setup and ping requests for timeout.


- Same as previous version.


# ComptoxR 1.2.2.9002

- Same as previous version.


# ComptoxR 1.2.2.9001

- Same as previous version.


# ComptoxR 1.2.2.9000

- Same as previous version.


# ComptoxR 1.2.2

# ComptoxR 1.2.1

# ComptoxR 1.2.0

Install via:
`devtools::install_local(path = '[LOCALPATH HERE]/ComptoxR_1.2.0.tar.gz')`
Load via: `library(ComptoxR)` You should expect to see:

```         
✔ This is version 1.2.0 of ComptoxR
ℹ API endpoint selected:
https://api-ccte.epa.gov/
```

Changelog:

-   Added Cheminformatics access, no API token needed. Can be accessed
    with `chemi_` headers for functions.
    
-   Added webchem::as.cas() function for CASRN checking

-   Removed some bloat that was not supposed to be there

-    Also added in cli package for messaging rather than a home-grown
    function.

-   Batch mode road-mapped for other CompTox functions (available in ver
    1.3)

-   ChemExpo road-mapped for documentation (Available in ver 1.3 or 1.4)

-   Added PRODWATER and CWA311HS datasets.
