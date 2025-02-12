<!-- NEWS.md is maintained by https://cynkra.github.io/fledge, do not edit -->

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
