#!/usr/bin/env Rscript
# ==============================================================================
# Lifestage Standalone Validation
# ==============================================================================
#
# Defines the 5-column lifestage dictionary tribble, .classify_lifestage_keywords(),
# and 18 assertions. Reads ecotox.duckdb read-only. Does NOT modify any
# production files. Validated code gets lifted into ecotox_build.R in Phase 32.
#
# Usage:
#   Rscript dev/lifestage/validate_lifestage.R
#
# Exit codes:
#   0 -- all assertions pass
#   1 -- one or more assertions failed
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(tibble)
  library(dplyr)
  library(cli)
  library(here)
})

# ==============================================================================
# Section 2: Keyword Classifier Function
# ==============================================================================

.classify_lifestage_keywords <- function(descriptions) {
  # Developmental stage rules -- no "Reproductive" category.
  # Reproductive status is captured independently via the reproductive_stage flag.
  #fmt: off
  rules <- tibble::tribble(
    ~priority , ~pattern                                                                                                                                                                                                                   , ~harmonized_life_stage ,
     1L       , "(?i)egg|embryo|blastula|gastrula|morula|zygot|oocyte|cleavage|neurula"                                                                                                                                                    , "Egg/Embryo"           ,
     2L       , "(?i)larva|fry|naupli|nymph|tadpole|veliger|zoea|instar|pupa|prepupal|protozoea|mysis|glochidia|trochophore|caterpillar|maggot"                                                                                            , "Larva"                ,
     3L       , "(?i)fingerling|froglet|smolt|parr|seedling|elver|alevin|juvenile|weanling|yearling|pullet|young(?!.*adult)|post-larva|post-smolt|copepodid|copepodite|swim-up|underyearling|spat|sapling"                                 , "Juvenile"             ,
     4L       , "(?i)subadult|immature|peripubertal|sexually immature|pre-.*adult|young adult"                                                                                                                                             , "Subadult"             ,
     5L       , "(?i)adult|mature(?!.*dormant)|bloom|boot|heading|tiller|jointing|internode|shoot|imago|post-emergence|sexually mature|spawn|reproduct|gestat|lactat|gamete|gametophyte|pollen|partum|F\\d+\\s*gen|flower|prebloom|laying" , "Adult"                ,
     6L       , "(?i)dormant|senescen|cyst|stationary.*phase|\\bseed\\b|\\bspore\\b|\\bcorm\\b|\\bcocoon\\b|\\btuber\\b"                                                                                                                   , "Senescent/Dormant"    ,
    99L       , ".*"                                                                                                                                                                                                                       , "Other/Unknown"
  )
  #fmt: on

  # Reproductive flag -- set independently of developmental classification
  repro_pattern <- "(?i)spawn|reproduct|gestat|lactat|gamete|gametophyte|pollen|partum|F\\d+\\s*gen|flower|prebloom|laying"

  tibble::tibble(
    org_lifestage = descriptions,
    harmonized_life_stage = vapply(
      descriptions,
      function(desc) {
        for (i in seq_len(nrow(rules))) {
          if (grepl(rules$pattern[i], desc, perl = TRUE)) {
            return(rules$harmonized_life_stage[i])
          }
        }
        "Other/Unknown"
      },
      character(1)
    ),
    ontology_id = NA_character_,
    reproductive_stage = grepl(repro_pattern, descriptions, perl = TRUE),
    classification_source = "keyword_fallback"
  )
}

# Section 3: Dictionary tribble -- see Task 2
