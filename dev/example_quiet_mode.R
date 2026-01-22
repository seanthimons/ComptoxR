#!/usr/bin/env Rscript
# Example: Suppressing Package Startup Messages
# This script demonstrates how to use the run_quiet() function and related
# mechanisms to suppress ComptoxR package startup messages.

# Method 1: Set the option before loading the package
# This is the recommended approach for completely suppressing startup messages
cat("Method 1: Setting option before loading package\n")
cat("================================================\n\n")
cat("options(ComptoxR.quiet = TRUE)\n")
cat("library(ComptoxR)\n\n")
cat("Result: No startup messages will be displayed\n\n")

# Method 2: Set environment variable before loading the package
cat("Method 2: Setting environment variable before loading package\n")
cat("=============================================================\n\n")
cat("Sys.setenv(COMPTOXR_STARTUP_QUIET = 'true')\n")
cat("library(ComptoxR)\n\n")
cat("Result: No startup messages will be displayed\n\n")

# Method 3: Use run_quiet() after loading the package
cat("Method 3: Using run_quiet() after package is loaded\n")
cat("===================================================\n\n")
cat("library(ComptoxR)  # Normal startup messages displayed\n")
cat("run_quiet(TRUE)    # Future calls to run_setup() will be suppressed\n\n")
cat("Result: Startup messages shown initially, but subsequent\n")
cat("        calls to run_setup() will be suppressed\n\n")

# Method 4: Temporarily suppress for a specific operation
cat("Method 4: Temporarily suppressing for specific operations\n")
cat("=========================================================\n\n")
cat("# Save current state\n")
cat("old_quiet <- getOption('ComptoxR.quiet', FALSE)\n\n")
cat("# Suppress messages\n")
cat("options(ComptoxR.quiet = TRUE)\n")
cat("run_setup()  # No output\n\n")
cat("# Restore original state\n")
cat("options(ComptoxR.quiet = old_quiet)\n\n")

# Notes
cat("Important Notes:\n")
cat("================\n\n")
cat("1. The quiet mode ONLY suppresses message display.\n")
cat("   All initialization behavior (setting server URLs,\n")
cat("   initializing global variables, etc.) is preserved.\n\n")
cat("2. The quiet mode overrides verbose and debug flags.\n")
cat("   Even with verbose=TRUE or debug=TRUE, if quiet mode\n")
cat("   is enabled, no startup messages will be shown.\n\n")
cat("3. You can check the current quiet mode status:\n")
cat("   getOption('ComptoxR.quiet')\n")
cat("   Sys.getenv('COMPTOXR_STARTUP_QUIET')\n\n")
cat("4. To re-enable messages:\n")
cat("   run_quiet(FALSE)\n")
cat("   # or\n")
cat("   options(ComptoxR.quiet = FALSE)\n\n")

# Example use cases
cat("Common Use Cases:\n")
cat("=================\n\n")
cat("1. Non-interactive scripts:\n")
cat("   When running automated scripts, you may want to suppress\n")
cat("   startup messages to keep logs clean.\n\n")
cat("2. Package development:\n")
cat("   When testing your own packages that depend on ComptoxR,\n")
cat("   you can suppress ComptoxR's startup messages.\n\n")
cat("3. Integration with other tools:\n")
cat("   When integrating ComptoxR into larger workflows or\n")
cat("   pipelines where startup messages may interfere.\n\n")
