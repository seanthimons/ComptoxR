# Next Steps - Testing Implementation

**Date:** 2026-01-04
**Current Status:** Test framework complete, tests failing due to parameter mismatches
**Coverage:** Still ~7% (tests need fixes before cassettes can be recorded)

---

## 📋 What Was Accomplished Today

### ✅ Infrastructure Complete
1. **Test Generation Framework**
   - `generate_tests.R` - Automated test file generator
   - `helper-test-generator.R` - Reusable test utilities
   - `check_cassettes.R` - VCR cassette management

2. **Test Files Created**
   - 28 new test files generated
   - 4 existing test files enhanced
   - **Total: 34 test files**

3. **CI/CD Workflows**
   - `test-coverage.yml` - Multi-platform comprehensive testing
   - `coverage-check.yml` - Coverage threshold enforcement (70% minimum)
   - `test-quick.yml` - Fast feedback for PRs

4. **Documentation**
   - `TESTING_STRATEGY.md` - Complete roadmap to 90%+ coverage
   - `TESTING_QUICKSTART.md` - 30-minute quick start guide
   - `TESTING_SUMMARY.md` - Implementation summary
   - `.github/workflows/README.md` - CI/CD setup guide
   - **Total: 1,619 lines of documentation**

5. **Cleanup**
   - Removed 6 orphaned VCR cassettes
   - Kept 15 valid cassettes
   - Clean cassette directory ready for recording

---

## ⚠️ Current Issue: Test Failures

### Test Run Results
```
✓ Passed:   ~33 tests (template tests, existing tests)
✗ Failed:   ~97 tests (generated tests with parameter issues)
📊 Total:    ~130 test cases
🎬 Cassettes: 15 (no new ones recorded due to failures)
```

### Root Cause Analysis

#### **Problem 1: Parameter Name Mismatches** (60% of failures)
The test generator assumed all wrapper functions use `dtxsid` as the parameter name, but many functions use different parameter names.

**Examples:**
```r
# Generated test (WRONG):
chemi_hazard(dtxsid = "DTXSID7020182")
chemi_safety(dtxsid = "DTXSID7020182")
ct_cancer(dtxsid = "DTXSID7020182")

# Actual function signature (CORRECT):
chemi_hazard(query = "DTXSID7020182")
chemi_safety(query = "DTXSID7020182")
ct_cancer(dtxsid = "DTXSID7020182")  # This one is correct
```

**Why it happened:**
- Test generator used a default mapping assuming consistent parameter names
- Actual functions have varying signatures (some use `query`, some use `dtxsid`, some use `chemicals`, etc.)
- Need function-specific parameter mapping

#### **Problem 2: Missing Required Parameters** (20% of failures)
Some functions require additional parameters that weren't included in generated tests.

**Examples:**
```r
# chemi_search requires searchType
chemi_search(query, searchType = "similarity")  # searchType is required

# chemi_safety_section requires section
chemi_safety_section(query, section = "ghs")  # section is required

# chemi_classyfire uses 'structure' not 'smiles'
chemi_classyfire(structure = "C=O")  # uses 'structure'
```

#### **Problem 3: Function-Specific Edge Cases** (10% of failures)
Some functions have special requirements or edge cases.

**Examples:**
```r
# chemi_cluster can't cluster single item
chemi_cluster("benzene")  # Error: need n >= 2 for clustering

# chemi_cluster_sim_list expects output from chemi_cluster
chemi_cluster_sim_list(cluster_data)  # Not a dtxsid parameter

# chemi_resolver returns complex list, not character vector
result <- chemi_resolver("benzene")  # Returns list, not character
```

#### **Problem 4: API Response Structure Issues** (10% of failures)
Some functions have response parsing issues.

**Examples:**
```r
# chemi_toxprint - unnamed columns in response
# Need to handle in generic_chemi_request or fix API parsing
```

---

## 🎯 Immediate Next Steps

### **Step 1: Create Function Signature Reference** (30 minutes)
Create a comprehensive mapping of all function signatures to know the correct parameter names.

**Action:** Create `FUNCTION_SIGNATURES.md` with:
```markdown
# Function Signatures Reference

## chemi_* Functions
- chemi_hazard(query, ...)
- chemi_safety(query, ...)
- chemi_rq(query, ...)
- chemi_classyfire(structure, ...)
- chemi_search(query, searchType, ...)
- chemi_cluster(chemicals, sort = TRUE, ...)
- chemi_cluster_sim_list(chemi_cluster_data)
- chemi_resolver(chemicals, id_type = "DTXSID", mol = FALSE)

## ct_* Functions
- ct_hazard(dtxsid, ...)
- ct_cancer(dtxsid, ...)
- ct_genotox(dtxsid, ...)
[etc.]
```

**How to do it:**
```r
# For each function, check its signature
library(ComptoxR)

# Method 1: Use args()
args(chemi_hazard)

# Method 2: Read the source
??chemi_hazard

# Method 3: Read the R file directly
# Look in R/chemi_*.R and R/ct_*.R
```

### **Step 2: Fix Critical Test Files** (1-2 hours)
Fix tests for the most important ~10 functions to get coverage baseline.

**Priority Functions to Fix:**
1. `ct_hazard` - Most used function
2. `ct_cancer` - Core functionality
3. `ct_genotox` - Core functionality
4. `chemi_hazard` - Chemi integration
5. `chemi_safety` - Chemi integration
6. `chemi_toxprint` - Already has some tests passing
7. `ct_lists_all` - Special case, no query param
8. `ct_compound_in_list` - Special case, returns named list
9. `chemi_cluster` - Complex function
10. `chemi_resolver` - Complex function

**How to fix:**
```r
# Example fix for chemi_hazard
# In test-chemi_hazard.R, change:
chemi_hazard(dtxsid = "DTXSID7020182")
# To:
chemi_hazard(query = "DTXSID7020182")

# Example fix for chemi_search
# In test-chemi_search.R, change:
chemi_search(dtxsid = "DTXSID7020182")
# To:
chemi_search(query = "DTXSID7020182", searchType = "dtxsid")
```

### **Step 3: Update Test Generator** (1-2 hours)
Update `generate_tests.R` with correct function signature mappings.

**Update the function_signatures mapping:**
```r
function_signatures <- list(
  # Functions that use 'query' parameter
  chemi_hazard = list(
    param = "query",
    type = "dtxsid_single"
  ),
  chemi_safety = list(
    param = "query",
    type = "dtxsid_single"
  ),

  # Functions with special signatures
  chemi_search = list(
    param = "query",
    type = "search_with_type",
    additional = list(searchType = "dtxsid")
  ),

  chemi_cluster = list(
    param = "chemicals",
    type = "chemical_names",
    additional = list(sort = TRUE)
  ),

  # Standard dtxsid functions
  ct_hazard = list(
    param = "dtxsid",
    type = "dtxsid_single"
  )
)
```

### **Step 4: Re-run Tests** (10 minutes)
After fixing critical tests, re-run to record cassettes.

```r
# Run tests for fixed functions only
devtools::test(filter = "ct_hazard|chemi_hazard|ct_cancer")

# Check coverage improvement
cov <- covr::package_coverage()
print(cov)
```

### **Step 5: Regenerate Remaining Tests** (30 minutes)
Once generator is updated, regenerate all tests with correct signatures.

```r
source("generate_tests.R")
generate_tests(overwrite = TRUE)
```

### **Step 6: Full Test Run** (15 minutes)
Run complete test suite to record all cassettes.

```r
Sys.setenv(ctx_api_key = "YOUR_KEY_HERE")
devtools::test()

# Check coverage
cov <- covr::package_coverage()
print(cov)
covr::report(cov)
```

---

## 📊 Expected Timeline

| Task | Time | Status | Coverage After |
|------|------|--------|----------------|
| **Current** | - | Complete | ~7% |
| Function signature reference | 30 min | To Do | - |
| Fix 10 critical test files | 1-2 hours | To Do | ~15-20% |
| Update test generator | 1-2 hours | To Do | - |
| Regenerate all tests | 30 min | To Do | - |
| Run full test suite | 15 min | To Do | ~40-50% |
| **Total** | **3.5-5 hours** | | **40-50%** |

---

## 🔧 Quick Reference Commands

### Check Function Signatures
```r
# Load package
library(ComptoxR)

# Check specific function
args(chemi_hazard)
?chemi_hazard

# List all functions
ls("package:ComptoxR", pattern = "^ct_")
ls("package:ComptoxR", pattern = "^chemi_")
```

### Fix Test Files
```r
# Open test file
file.edit("tests/testthat/test-chemi_hazard.R")

# Search and replace parameter names
# Old: dtxsid =
# New: query =
```

### Run Specific Tests
```r
# Single test file
testthat::test_file("tests/testthat/test-ct_hazard.R")

# Multiple test files by pattern
devtools::test(filter = "ct_hazard|chemi_hazard")

# All tests
devtools::test()
```

### Check Cassettes
```r
# List cassettes
source("tests/testthat/helper-vcr.R")
list_cassettes()

# Check for orphaned cassettes
source("check_cassettes.R")
```

### Check Coverage
```r
# Calculate coverage
cov <- covr::package_coverage()

# Print summary
print(cov)

# Open interactive report
covr::report(cov)
```

---

## 📁 Files to Review

### Test Infrastructure
```
tests/testthat/
├── helper-test-generator.R    # Test generation utilities
├── test-*.R                    # 34 test files (need param fixes)
├── setup.R                     # Test setup (fixed)
└── fixtures/                   # 15 VCR cassettes (valid)
```

### Test Generation
```
generate_tests.R                # Main generator (needs signature update)
check_cassettes.R              # Cassette management
```

### Documentation
```
TESTING_STRATEGY.md            # Complete testing roadmap
TESTING_QUICKSTART.md          # 30-minute quick start
TESTING_SUMMARY.md             # What was accomplished
NEXT_STEPS.md                  # This file
```

### CI/CD
```
.github/workflows/
├── test-coverage.yml          # Multi-platform testing
├── coverage-check.yml         # Coverage enforcement
├── test-quick.yml             # Fast feedback
└── README.md                  # CI/CD setup guide
```

---

## ✅ What's Working

### Successfully Passing Tests (33 tests)
- ✅ `generic_request` - Core template (15 tests passing)
- ✅ `generic_chemi_request` - Chemi template (10 tests passing)
- ✅ `clean_unicode` - Utility function (14 tests passing)
- ✅ `chemi_cluster` - Clustering function (18 tests passing)
- ✅ `chemi_resolver` - Some tests passing (1 test passing)
- ✅ `chemi_toxprint` - Partial success

### Working Infrastructure
- ✅ Test generation framework
- ✅ VCR cassette management
- ✅ CI/CD workflows configured
- ✅ Documentation complete
- ✅ 15 valid cassettes recorded

---

## ⚠️ What Needs Fixing

### Test Files (97 failing tests)
Most generated test files have parameter name mismatches:
- `test-chemi_classyfire.R` - Parameter: `structure` not `smiles`
- `test-chemi_cluster_sim_list.R` - Parameter: `chemi_cluster_data` not `dtxsid`
- `test-chemi_hazard.R` - Parameter: `query` not `dtxsid`
- `test-chemi_predict.R` - Parameter: `query` not `dtxsid`
- `test-chemi_rq.R` - Parameter: `query` not `dtxsid`
- `test-chemi_safety.R` - Parameter: `query` not `dtxsid`
- `test-chemi_safety_section.R` - Parameters: `query`, `section` not just `dtxsid`
- `test-chemi_search.R` - Missing `searchType` parameter
- All `ct_*` test files - Need verification of parameter names

### Test Generator
- Needs function signature mapping
- Needs special case handling
- Needs parameter name mapping per function

---

## 💡 Tips for Success

### When Fixing Tests
1. **Check function signature first** - Use `args(function_name)` or `?function_name`
2. **Look at function source** - Read the R file in `R/` directory
3. **Test one function at a time** - Don't try to fix everything at once
4. **Run tests after each fix** - Verify it works before moving on
5. **Record cassettes** - Make sure API key is set when running fixed tests

### When Updating Generator
1. **Document assumptions** - Write down what you learn about each function
2. **Test the generator** - Regenerate one file and verify it's correct
3. **Keep old tests as reference** - Don't delete until new ones work

### When Recording Cassettes
1. **API key must be set** - `Sys.setenv(ctx_api_key = "YOUR_KEY")`
2. **Check cassette safety** - Use `check_cassette_safety()` before committing
3. **Review cassettes** - Make sure they contain expected data
4. **Commit cassettes with tests** - Keep them in sync

---

## 🎓 Lessons Learned

### What Worked Well
- ✅ Test generation framework approach
- ✅ VCR cassette strategy
- ✅ CI/CD workflow setup
- ✅ Documentation structure
- ✅ Template-based testing for core functions

### What Needs Improvement
- ⚠️ Function signature discovery before generation
- ⚠️ Better error handling in test generator
- ⚠️ Function-specific test templates
- ⚠️ Validation of generated tests before full run

### Key Insights
1. **Not all wrapper functions have consistent signatures** - Need per-function mapping
2. **Some functions require special handling** - Edge cases need custom tests
3. **Test generation is powerful but needs accurate metadata** - GIGO principle applies
4. **VCR cassettes won't record if tests fail** - Need passing tests first

---

## 📞 Getting Help

### If Tests Still Fail After Fixes
1. Check function signature: `args(function_name)`
2. Check function documentation: `?function_name`
3. Read function source: `View(function_name)` or open R file
4. Run test in isolation: `testthat::test_file("tests/testthat/test-function.R")`
5. Check error message carefully - it usually tells you what's wrong

### If Cassettes Won't Record
1. Verify API key is set: `Sys.getenv("ctx_api_key")`
2. Check test passes without VCR: Comment out `use_cassette()` temporarily
3. Check network connectivity: Can you access the API directly?
4. Check API is working: Visit dashboard website

### If Coverage Doesn't Improve
1. Make sure tests are passing: `devtools::test()`
2. Check which files are covered: `covr::report(cov)`
3. Look for uncovered lines: Red highlighted lines in coverage report
4. Add tests for uncovered branches: Focus on if/else statements

---

## 🚀 After Everything Works

### Commit and Push
```bash
git add tests/testthat/ .github/workflows/ *.md generate_tests.R check_cassettes.R
git commit -m "feat: Add comprehensive test suite (40-50% coverage)

- 34 test files with corrected function signatures
- VCR cassettes for reliable testing
- CI/CD workflows with coverage enforcement
- Complete testing documentation

Coverage improved from 7% to 40-50%"

git push
```

### Set Up GitHub Secrets
1. Go to: `https://github.com/YOUR_USERNAME/ComptoxR/settings/secrets/actions`
2. Add `CTX_API_KEY` secret
3. (Optional) Add `CODECOV_TOKEN` for coverage reporting

### Add Badges to README
```markdown
[![R-CMD-check](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/test-coverage.yml/badge.svg)](https://github.com/YOUR_USERNAME/ComptoxR/actions/workflows/test-coverage.yml)
[![codecov](https://codecov.io/gh/YOUR_USERNAME/ComptoxR/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USERNAME/ComptoxR)
```

### Continue to Higher Coverage
Follow `TESTING_STRATEGY.md` for path to 90%+ coverage:
- Phase 2: Add utility function tests (60-70%)
- Phase 3: Add integration tests (75-85%)
- Phase 4: Add edge cases (85-95%)
- Phase 5: Fill remaining gaps (>90%)

---

## 📝 Summary

### What You Have Now
- ✅ Complete test infrastructure
- ✅ 34 test files (need parameter fixes)
- ✅ Test generation framework
- ✅ CI/CD workflows configured
- ✅ Comprehensive documentation
- ✅ VCR cassette management

### What Needs to Be Done
1. Create function signature reference (30 min)
2. Fix 10 critical test files (1-2 hours)
3. Update test generator (1-2 hours)
4. Regenerate all tests (30 min)
5. Run full test suite (15 min)

### Expected Outcome
- 🎯 40-50% test coverage
- ✅ ~150-200 passing tests
- ✅ ~100 VCR cassettes
- ✅ CI/CD running on every PR
- ✅ Coverage enforcement in place

### Time Investment
- **Immediate fixes:** 3.5-5 hours
- **Path to 90%+:** 11-19 hours total (per original plan)

---

**Next Action:** Create function signature reference and start fixing critical test files.

**Files to Start With:**
1. Create `FUNCTION_SIGNATURES.md`
2. Fix `test-ct_hazard.R`
3. Fix `test-chemi_hazard.R`
4. Verify both work, then continue with remaining functions

Good luck! 🚀
