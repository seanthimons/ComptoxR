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

# ==============================================================================
# Section 3: 5-Column Dictionary Tribble
# ==============================================================================
#
# 139 rows: 137 from current ecotox_build.R tribble + 2 new DB terms
# (Not coded, Turion).
#
# Corrections applied:
#   - 6 misclassification fixes (Germinated seed, Spat, Seed, Sapling, Cocoon, Corm)
#   - Larva/Juvenile split into separate Larva and Juvenile categories
#   - Reproductive category eliminated (terms moved to Adult + reproductive_stage=TRUE)
#   - Spore: Other/Unknown -> Senescent/Dormant (dormant propagule)
#   - Tuber: Adult -> Senescent/Dormant (dormant storage organ)
#   - Dormant/Senescent renamed to Senescent/Dormant
#   - Subadult/Immature renamed to Subadult

#fmt: off
life_stage_new <- tibble::tribble(
  ~org_lifestage                                   , ~harmonized_life_stage , ~ontology_id     , ~reproductive_stage , ~classification_source ,
  "Unspecified"                                    , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Adult"                                          , "Adult"                , "UBERON:0000113" , FALSE               , "dictionary"           ,
  "Alevin"                                         , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Bud or Budding"                                 , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Blastula"                                       , "Egg/Embryo"           , "UBERON:0000108" , FALSE               , "dictionary"           ,
  "Bud blast stage"                                , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Boot"                                           , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Cocoon"                                         , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Corm"                                           , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Copepodid"                                      , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Copepodite"                                     , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Cleavage stage"                                 , "Egg/Embryo"           , NA_character_    , FALSE               , "dictionary"           ,
  "Cyst"                                           , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Egg"                                            , "Egg/Embryo"           , "UBERON:0000068" , FALSE               , "dictionary"           ,
  "Elver"                                          , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Embryo"                                         , "Egg/Embryo"           , "UBERON:0000068" , FALSE               , "dictionary"           ,
  "Exponential growth phase (log)"                 , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Eyed egg or stage, eyed embryo"                 , "Egg/Embryo"           , NA_character_    , FALSE               , "dictionary"           ,
  "F0 generation"                                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "F1 generation"                                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "F11 generation"                                 , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "F2 generation"                                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "F3 generation"                                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "F6 generation"                                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "F7 generation"                                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Mature (full-bloom stage) organism"             , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Female gametophyte"                             , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Fingerling"                                     , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Flower opening"                                 , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Froglet"                                        , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Fry"                                            , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Gastrula"                                       , "Egg/Embryo"           , "UBERON:0000109" , FALSE               , "dictionary"           ,
  "Gestation"                                      , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Glochidia"                                      , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Gamete"                                         , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Lag growth phase"                               , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Grain or seed formation stage"                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Germinated seed"                                , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Heading"                                        , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Incipient bud"                                  , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Internode elongation"                           , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Imago"                                          , "Adult"                , "UBERON:0000066" , FALSE               , "dictionary"           ,
  "Immature"                                       , "Subadult"             , NA_character_    , FALSE               , "dictionary"           ,
  "Instar"                                         , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Intermolt"                                      , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Jointing"                                       , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Juvenile"                                       , "Juvenile"             , "UBERON:0034919" , FALSE               , "dictionary"           ,
  "Lactational"                                    , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Egg laying"                                     , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Larva-pupa"                                     , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Prolarva"                                       , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Larva"                                          , "Larva"                , "UBERON:0000069" , FALSE               , "dictionary"           ,
  "Mature"                                         , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Mature dormant"                                 , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Megalopa"                                       , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Male gametophyte"                               , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Morula"                                         , "Egg/Embryo"           , "UBERON:0000085" , FALSE               , "dictionary"           ,
  "Mid-neurula"                                    , "Egg/Embryo"           , NA_character_    , FALSE               , "dictionary"           ,
  "Molt"                                           , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Multiple"                                       , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Mysis"                                          , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Newborn"                                        , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Naiad"                                          , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Neonate"                                        , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "New, newly or recent hatch"                     , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Neurala"                                        , "Egg/Embryo"           , NA_character_    , FALSE               , "dictionary"           ,
  "Not intact"                                     , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Not reported"                                   , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Nauplii"                                        , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Nymph"                                          , "Larva"                , "UBERON:0014405" , FALSE               , "dictionary"           ,
  "Oocyte, ova"                                    , "Egg/Embryo"           , NA_character_    , FALSE               , "dictionary"           ,
  "Parr"                                           , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Mature, post-bloom stage (fruit trees)"         , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Pre-hatch"                                      , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Pre-molt"                                       , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Post-emergence"                                 , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Post-spawning"                                  , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Mature, pit-hardening stage (fruit trees)"      , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Post-hatch"                                     , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Post-molt"                                      , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Pre-, sub-, semi-, near adult, or peripubertal" , "Subadult"             , NA_character_    , FALSE               , "dictionary"           ,
  "Post-smolt"                                     , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Pullet"                                         , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Post-nauplius"                                  , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Pollen, pollen grain"                           , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Postpartum"                                     , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Prepupal"                                       , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Pre-larva"                                      , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Prebloom"                                       , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Pre-smolt"                                      , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Protolarvae"                                    , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Pupa"                                           , "Larva"                , "UBERON:0003143" , FALSE               , "dictionary"           ,
  "Post-larva"                                     , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Pre-spawning"                                   , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Post-embryo"                                    , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Protozoea"                                      , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Rooted cuttings"                                , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Rhizome"                                        , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Mature reproductive"                            , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Rootstock"                                      , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Subadult"                                       , "Subadult"             , NA_character_    , FALSE               , "dictionary"           ,
  "Shoot"                                          , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Yolk sac larvae, sac larvae"                    , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Senescence"                                     , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Seed"                                           , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Scape elongation"                               , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Sac fry, yolk sac fry"                          , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Mature, side-green stage (fruit trees)"         , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Sexually immature"                              , "Subadult"             , NA_character_    , FALSE               , "dictionary"           ,
  "Seedling"                                       , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Sexually mature"                                , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Smolt"                                          , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Sapling"                                        , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Sporeling"                                      , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Sperm"                                          , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Spore"                                          , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Spat"                                           , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Swim-up"                                        , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Spawning"                                       , "Adult"                , NA_character_    , TRUE                , "dictionary"           ,
  "Stationary growth phase"                        , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Tadpole"                                        , "Larva"                , "UBERON:0002548" , FALSE               , "dictionary"           ,
  "Tissue culture callus"                          , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Tiller stage"                                   , "Adult"                , NA_character_    , FALSE               , "dictionary"           ,
  "Tuber"                                          , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"           ,
  "Trophozoite"                                    , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Underyearling"                                  , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Veliger"                                        , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Mature vegetative"                              , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Virgin"                                         , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Weanling"                                       , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Young adult"                                    , "Subadult"             , NA_character_    , FALSE               , "dictionary"           ,
  "Yearling"                                       , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Young"                                          , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Young of year"                                  , "Juvenile"             , NA_character_    , FALSE               , "dictionary"           ,
  "Zoea"                                           , "Larva"                , NA_character_    , FALSE               , "dictionary"           ,
  "Zygospore"                                      , "Egg/Embryo"           , NA_character_    , FALSE               , "dictionary"           ,
  "Zygote"                                         , "Egg/Embryo"           , "UBERON:0000106" , FALSE               , "dictionary"           ,
  "Not coded"                                      , "Other/Unknown"        , NA_character_    , FALSE               , "dictionary"           ,
  "Turion"                                         , "Senescent/Dormant"    , NA_character_    , FALSE               , "dictionary"
)
#fmt: on
