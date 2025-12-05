#Adding new testing chemicals

build_testing_chemicals(chems = c(
	'DTXSID401337424'
))

#Load latest data 
#pt <- readRDS("C:\\Users\\STHIMONS\\Documents\\curation\\final\\pt.RDS")
#usethis::use_data(pt, overwrite = TRUE)

run_verbose(TRUE)

# PURPOSE: To be run on a release branch to prepare a package for a new versioned release.

# 1. Bump version for the new release
# This updates the DESCRIPTION file and creates a commit.
# Choose 'patch', 'minor', or 'major' as appropriate for the changes made.
usethis::use_version(which = 'minor')

# 2. Generate/Update NEWS.md from Conventional Commits
# This requires that you've been using conventional commits in your feature branches.

library(autonewsmd)
tryCatch({
    an <- autonewsmd$new(repo_name = "ComptoxR", repo_path = here::here())
    an$generate()
    an$write(force = TRUE)
    rm(an)
    
    # It's good practice to commit this change immediately.
    # You can do this from the terminal:
    # git add NEWS.md
    # git commit -m "docs: Update NEWS.md for release"
    
}, error = function(e) {
    warning("Could not automatically generate NEWS.md. Please update it manually.")
})


# 3. Regenerate Documentation
# This ensures all documentation is up-to-date with the latest code and version.

devtools::document()
# Commit these changes from the terminal:
# git add man/ NAMESPACE
# git commit -m "docs: Regenerate documentation"

# 4. CRITICAL: Run Comprehensive Checks
# This is the most important step. Do not proceed if this fails.
#message("Running comprehensive package checks...")
#devtools::check()

# 5. Build Package Tarball and Binary
# This ensures the package can be built successfully.
#devtools::build()
devtools::build(binary = TRUE) # For Windows


# 6. Final Local Install and Reload
# A final check to ensure the package can be installed and loaded.
devtools::install(pkg = ".", dependencies = TRUE, reload = TRUE)
