# PURPOSE: Helper script for local development and preparing for a release.
# Note: Official releases are now handled via GitHub Actions (release.yml).

# 1. Update testing chemicals if needed
# build_testing_chemicals(chems = c('DTXSID401337424'))

# 2. Local Documentation and Style check
devtools::document()
# styler::style_pkg() # Optional: if you use styler

# 3. Local Checks (Run these before pushing)
# devtools::check()

# 4. Local Install
# devtools::install(dependencies = TRUE, reload = TRUE)

# TO RELEASE A NEW VERSION:
# 1. Ensure all changes are committed and pushed to 'main'.
# 2. Go to GitHub Actions -> "Release" workflow.
# 3. Click "Run workflow" and choose the version bump type.
