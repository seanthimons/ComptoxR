# Startup Message Suppression Implementation

## Overview
This document describes the implementation of the startup message suppression feature for ComptoxR, addressing the issue: "Investigate ways of totally suppressing package startup messages."

## Problem Statement
The package had startup messages that displayed API endpoint status, token checks, version information, and debug/verbose settings. Users needed a way to completely suppress these messages while preserving all initialization behavior (server URLs, global variables, etc.).

## Solution Design

### 1. Core Mechanism
A new internal helper function `.should_suppress_startup()` checks two sources:
- R option: `getOption("ComptoxR.quiet")`
- Environment variable: `Sys.getenv("COMPTOXR_STARTUP_QUIET")`

The function returns `TRUE` if either source indicates suppression is desired.

### 2. Public API
A new exported function `run_quiet(quiet = TRUE)` allows users to control the suppression:
```r
run_quiet(TRUE)   # Enable suppression
run_quiet(FALSE)  # Disable suppression
```

This function sets both the R option and environment variable for consistency.

### 3. Integration Points
The suppression check is integrated into:

#### a. `run_setup()` function
```r
run_setup <- function() {
  if (.should_suppress_startup()) {
    return(invisible(NULL))
  }
  # ... rest of function displays messages
}
```

#### b. `.header()` function
```r
.header <- function() {
  if (.should_suppress_startup()) {
    return(invisible(NULL))
  }
  # ... rest of function displays header
}
```

#### c. `run_verbose()` and `run_debug()` functions
These functions now wrap their message output in suppression checks:
```r
if (!.should_suppress_startup()) {
  cli::cli_alert_info(...)  # Only show if not suppressed
}
```

#### d. `.onAttach()` function
The package attachment checks quiet mode before displaying startup messages:
```r
if (!.should_suppress_startup() && 
    Sys.getenv("run_verbose") == "TRUE" && 
    !identical(Sys.getenv("R_DEVTOOLS_LOAD"), "true")) {
  packageStartupMessage(.header())
}
```

## Usage Methods

### Method 1: Set Before Loading (Recommended)
```r
options(ComptoxR.quiet = TRUE)
library(ComptoxR)  # No startup messages
```

This is the cleanest approach for completely silent loading.

### Method 2: Environment Variable
```r
Sys.setenv(COMPTOXR_STARTUP_QUIET = "true")
library(ComptoxR)  # No startup messages
```

Useful for system-wide configuration or CI/CD environments.

### Method 3: Function Call After Loading
```r
library(ComptoxR)  # Normal startup messages
run_quiet(TRUE)    # Suppress future messages
run_setup()        # No output
```

Useful for interactive sessions where you want to toggle suppression.

## Key Features

### 1. Override Behavior
The quiet mode **overrides** verbose and debug flags. Even if `run_verbose(TRUE)` is set, quiet mode will suppress all output.

### 2. Preserved Initialization
All initialization behavior is preserved:
- Server URL configuration
- Global variable assignment (`.ComptoxREnv$extractor`, `.ComptoxREnv$classifier`)
- Environment variable setup (batch_limit, run_debug, run_verbose)
- Package namespace loading

Only the **display of messages** is affected.

### 3. No Breaking Changes
The default behavior is unchanged. Quiet mode is opt-in.

## Testing

Comprehensive tests in `tests/testthat/test-quiet-mode.R` cover:
1. Setting and reading quiet mode options
2. Handling invalid input
3. Detection logic in `.should_suppress_startup()`
4. Integration with `run_setup()`, `run_verbose()`, and `run_debug()`
5. State restoration after tests

## Use Cases

### 1. Non-Interactive Scripts
```r
# script.R
options(ComptoxR.quiet = TRUE)
library(ComptoxR)
# Clean logs with no startup noise
```

### 2. Package Development
When developing packages that depend on ComptoxR:
```r
# In your package's .onLoad or tests
options(ComptoxR.quiet = TRUE)
library(ComptoxR)
```

### 3. CI/CD Pipelines
Set environment variable in CI configuration:
```yaml
env:
  COMPTOXR_STARTUP_QUIET: "true"
```

### 4. Knitr/RMarkdown Documents
```r
```{r setup, include=FALSE}
options(ComptoxR.quiet = TRUE)
library(ComptoxR)
```
```

## Implementation Notes

### Case Sensitivity
The environment variable check is case-insensitive:
```r
tolower(Sys.getenv("COMPTOXR_STARTUP_QUIET", "false")) == "true"
```

However, the values set by `run_quiet()` use uppercase for consistency:
```r
Sys.setenv("COMPTOXR_STARTUP_QUIET" = "TRUE")  # or "FALSE"
```

### Priority
If both the R option and environment variable are set, either one being TRUE will enable suppression (logical OR).

### Persistence
- R option: Persists for the current R session
- Environment variable: Persists for the current R session (or system-wide if set in shell profile)

## Future Enhancements

Potential improvements for future versions:
1. Fine-grained control (suppress only certain types of messages)
2. Logging to file when suppressed (for debugging)
3. Warning/error messages might still show even in quiet mode
4. Integration with R's `suppressPackageStartupMessages()`

## Backwards Compatibility

This implementation is fully backwards compatible:
- No existing function signatures changed
- No existing behavior modified (unless quiet mode is explicitly enabled)
- New function (`run_quiet()`) is purely additive
- Tests verify existing functionality is preserved
