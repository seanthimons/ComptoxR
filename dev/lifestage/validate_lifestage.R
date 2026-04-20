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
    ~priority , ~pattern                                                                                                                                                                                                                                                               , ~harmonized_life_stage ,
     1L       , "(?i)egg(?!.?laying)|embryo|blastula|gastrula|morula|zygot|oocyte|cleavage|neurula|neurala|zygospore"                                                                                                                                                                  , "Egg/Embryo"           ,
     2L       , "(?i)larva|fry|naupli|nymph|tadpole|veliger|zoea|instar|pupa|prepupal|protozoea|mysis|glochidia|trochophore|caterpillar|maggot|megalopa|newborn|naiad|neonate|hatch|trophozoite"                                                                                       , "Larva"                ,
     3L       , "(?i)fingerling|froglet|smolt|parr|seedling|elver|alevin|juvenile|weanling|yearling|pullet|young(?!.*adult)|post-larva|post-smolt|copepodid|copepodite|swim-up|underyearling|spat|sapling|sporeling"                                                                   , "Juvenile"             ,
     4L       , "(?i)subadult|immature|peripubertal|sexually immature|pre-.*adult|young adult"                                                                                                                                                                                         , "Subadult"             ,
     5L       , "(?i)adult|mature(?!.*dormant)|bloom|boot|heading|tiller|jointing|internode|shoot|imago|post-emergence|sexually mature|spawn|reproduct|gestat|lactat|gamete|gametophyte|pollen|partum|F\\d+\\s*gen|flower|prebloom|laying|\\bbud\\b|rhizome|cutting|scape|\\bsperm\\b" , "Adult"                ,
     6L       , "(?i)dormant|senescen|cyst|stationary.*phase|\\bseed\\b|\\bspore\\b|\\bcorm\\b|\\bcocoon\\b|\\btuber\\b|turion"                                                                                                                                                        , "Senescent/Dormant"    ,
    99L       , ".*"                                                                                                                                                                                                                                                                   , "Other/Unknown"
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

# ==============================================================================
# 4. Database Connection
# ==============================================================================

cli::cli_h1("Lifestage Standalone Validation")

db_path <- file.path(tools::R_user_dir("ComptoxR", "data"), "ecotox.duckdb")
if (!file.exists(db_path)) {
  cli::cli_abort(c(
    "ECOTOX DuckDB not found at expected path.",
    "i" = "Path: {db_path}",
    "i" = "Run the ECOTOX build first to create the database."
  ))
}
cli::cli_alert_info("DB path: {db_path}")

eco_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(eco_con, shutdown = TRUE), add = TRUE)

db_lifestages <- DBI::dbGetQuery(
  eco_con,
  "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
)$description
cli::cli_alert_info("lifestage_codes descriptions: {length(db_lifestages)}")

current_dict <- DBI::dbReadTable(eco_con, "lifestage_dictionary")
cli::cli_alert_info("Current dictionary rows: {nrow(current_dict)}")

# ==============================================================================
# 5. Assertion Battery
# ==============================================================================

results <- list()

assert <- function(label, condition, detail = "") {
  if (isTRUE(condition)) {
    cli::cli_alert_success("PASS: {label}")
    results[[length(results) + 1]] <<- list(label = label, pass = TRUE)
  } else {
    cli::cli_alert_danger(
      "FAIL: {label}{if (nzchar(detail)) paste0(' \\u2014 ', detail) else ''}"
    )
    results[[length(results) + 1]] <<- list(
      label = label,
      pass = FALSE,
      detail = detail
    )
  }
}

# -- Group 1: Two-Axis Classifier Assertions (A1-A10) -------------------------

cli::cli_h2("Group 1: Two-Axis Classifier Assertions (A1-A10)")

a1 <- .classify_lifestage_keywords("Spawning adult")
assert(
  "A1: 'Spawning adult' -> Adult",
  a1$harmonized_life_stage == "Adult",
  paste0("got: ", a1$harmonized_life_stage)
)
assert(
  "A1: 'Spawning adult' -> reproductive",
  a1$reproductive_stage,
  paste0("got: ", a1$reproductive_stage)
)

a2 <- .classify_lifestage_keywords("Mature female")
assert(
  "A2: 'Mature female' -> Adult",
  a2$harmonized_life_stage == "Adult",
  paste0("got: ", a2$harmonized_life_stage)
)
assert(
  "A2: 'Mature female' -> not reproductive",
  !a2$reproductive_stage,
  paste0("got: ", a2$reproductive_stage)
)

a3 <- .classify_lifestage_keywords("Reproductive adult")
assert(
  "A3: 'Reproductive adult' -> Adult",
  a3$harmonized_life_stage == "Adult",
  paste0("got: ", a3$harmonized_life_stage)
)
assert(
  "A3: 'Reproductive adult' -> reproductive",
  a3$reproductive_stage,
  paste0("got: ", a3$reproductive_stage)
)

a4 <- .classify_lifestage_keywords("Post-spawning adult")
assert(
  "A4: 'Post-spawning adult' -> Adult",
  a4$harmonized_life_stage == "Adult",
  paste0("got: ", a4$harmonized_life_stage)
)
assert(
  "A4: 'Post-spawning adult' -> reproductive",
  a4$reproductive_stage,
  paste0("got: ", a4$reproductive_stage)
)

a5 <- .classify_lifestage_keywords("Gestating juvenile")
assert(
  "A5: 'Gestating juvenile' -> Juvenile",
  a5$harmonized_life_stage == "Juvenile",
  paste0("got: ", a5$harmonized_life_stage)
)
assert(
  "A5: 'Gestating juvenile' -> reproductive",
  a5$reproductive_stage,
  paste0("got: ", a5$reproductive_stage)
)

a6 <- .classify_lifestage_keywords("Flowering seedling")
assert(
  "A6: 'Flowering seedling' -> Juvenile",
  a6$harmonized_life_stage == "Juvenile",
  paste0("got: ", a6$harmonized_life_stage)
)
assert(
  "A6: 'Flowering seedling' -> reproductive",
  a6$reproductive_stage,
  paste0("got: ", a6$reproductive_stage)
)

a7 <- .classify_lifestage_keywords("Larva")
assert(
  "A7: 'Larva' -> Larva",
  a7$harmonized_life_stage == "Larva",
  paste0("got: ", a7$harmonized_life_stage)
)
assert(
  "A7: 'Larva' -> not reproductive",
  !a7$reproductive_stage,
  paste0("got: ", a7$reproductive_stage)
)

a8 <- .classify_lifestage_keywords("Egg-laying female")
assert(
  "A8: 'Egg-laying female' -> Adult",
  a8$harmonized_life_stage == "Adult",
  paste0("got: ", a8$harmonized_life_stage)
)
assert(
  "A8: 'Egg-laying female' -> reproductive",
  a8$reproductive_stage,
  paste0("got: ", a8$reproductive_stage)
)

a9 <- .classify_lifestage_keywords("Dormant seed")
assert(
  "A9: 'Dormant seed' -> Senescent/Dormant",
  a9$harmonized_life_stage == "Senescent/Dormant",
  paste0("got: ", a9$harmonized_life_stage)
)
assert(
  "A9: 'Dormant seed' -> not reproductive",
  !a9$reproductive_stage,
  paste0("got: ", a9$reproductive_stage)
)

a10 <- .classify_lifestage_keywords("Pollen")
assert(
  "A10: 'Pollen' -> Adult",
  a10$harmonized_life_stage == "Adult",
  paste0("got: ", a10$harmonized_life_stage)
)
assert(
  "A10: 'Pollen' -> reproductive",
  a10$reproductive_stage,
  paste0("got: ", a10$reproductive_stage)
)

# -- Group 2: Dictionary Structure (A11-A15, A18) -----------------------------

cli::cli_h2("Group 2: Dictionary Structure (A11-A15, A18)")

missing_terms <- setdiff(db_lifestages, life_stage_new$org_lifestage)
assert(
  "A11: All DB lifestage_codes present in dictionary",
  length(missing_terms) == 0,
  paste0(
    length(missing_terms),
    " missing: ",
    paste(missing_terms, collapse = ", ")
  )
)

assert(
  "A12: No 'Reproductive' category in dictionary",
  !"Reproductive" %in% life_stage_new$harmonized_life_stage
)

assert(
  "A13: No 'Larva/Juvenile' category in dictionary",
  !"Larva/Juvenile" %in% life_stage_new$harmonized_life_stage
)

assert(
  "A14: Column completeness (exactly 5 columns)",
  identical(
    names(life_stage_new),
    c(
      "org_lifestage",
      "harmonized_life_stage",
      "ontology_id",
      "reproductive_stage",
      "classification_source"
    )
  ),
  paste0("got: ", paste(names(life_stage_new), collapse = ", "))
)

assert(
  "A15: classification_source uniformity (all 'dictionary')",
  all(life_stage_new$classification_source == "dictionary"),
  paste0(
    "non-dictionary: ",
    sum(life_stage_new$classification_source != "dictionary")
  )
)

na_org <- sum(is.na(life_stage_new$org_lifestage))
na_hls <- sum(is.na(life_stage_new$harmonized_life_stage))
na_cs <- sum(is.na(life_stage_new$classification_source))
na_rs <- sum(is.na(life_stage_new$reproductive_stage))
assert(
  "A18: No NAs in required columns",
  na_org == 0 && na_hls == 0 && na_cs == 0 && na_rs == 0,
  paste0(
    "NA counts: org_lifestage=",
    na_org,
    ", harmonized_life_stage=",
    na_hls,
    ", classification_source=",
    na_cs,
    ", reproductive_stage=",
    na_rs
  )
)

# -- Group 3: Misclassification Fixes (A16) -----------------------------------

cli::cli_h2("Group 3: Misclassification Fixes (A16)")

lookup <- function(term) {
  life_stage_new$harmonized_life_stage[life_stage_new$org_lifestage == term]
}

assert(
  "A16a: 'Germinated seed' -> Juvenile",
  lookup("Germinated seed") == "Juvenile",
  paste0("got: ", lookup("Germinated seed"))
)
assert(
  "A16b: 'Spat' -> Juvenile",
  lookup("Spat") == "Juvenile",
  paste0("got: ", lookup("Spat"))
)
assert(
  "A16c: 'Seed' -> Senescent/Dormant",
  lookup("Seed") == "Senescent/Dormant",
  paste0("got: ", lookup("Seed"))
)
assert(
  "A16d: 'Sapling' -> Juvenile",
  lookup("Sapling") == "Juvenile",
  paste0("got: ", lookup("Sapling"))
)
assert(
  "A16e: 'Cocoon' -> Senescent/Dormant",
  lookup("Cocoon") == "Senescent/Dormant",
  paste0("got: ", lookup("Cocoon"))
)
assert(
  "A16f: 'Corm' -> Senescent/Dormant",
  lookup("Corm") == "Senescent/Dormant",
  paste0("got: ", lookup("Corm"))
)

# -- Group 4: Keyword Classifier Coverage (A17) -------------------------------

cli::cli_h2("Group 4: Keyword Classifier Coverage (A17)")

kw_results <- .classify_lifestage_keywords(life_stage_new$org_lifestage)
kw_non_other <- sum(kw_results$harmonized_life_stage != "Other/Unknown")
assert(
  "A17: Keyword classifier coverage >= 125/139 non-Other/Unknown",
  kw_non_other >= 125,
  paste0("got: ", kw_non_other, "/", nrow(life_stage_new))
)

# ==============================================================================
# 6. Classification Diff (current 2-col vs proposed 5-col)
# ==============================================================================

cli::cli_h2("Classification Changes")

diff_rows <- dplyr::left_join(
  life_stage_new,
  current_dict,
  by = "org_lifestage",
  suffix = c(".new", ".old")
) |>
  dplyr::filter(harmonized_life_stage.new != harmonized_life_stage.old) |>
  dplyr::select(
    org_lifestage,
    old_category = harmonized_life_stage.old,
    new_category = harmonized_life_stage.new,
    reproductive_stage
  )

if (nrow(diff_rows) > 0) {
  cli::cli_alert_info("{nrow(diff_rows)} term(s) changed classification:")
  print(diff_rows, n = Inf)
} else {
  cli::cli_alert_info("No classification changes detected.")
}

new_terms <- dplyr::anti_join(life_stage_new, current_dict, by = "org_lifestage")
if (nrow(new_terms) > 0) {
  cli::cli_alert_info("{nrow(new_terms)} new term(s) added to dictionary:")
  print(
    dplyr::select(
      new_terms,
      org_lifestage,
      harmonized_life_stage,
      reproductive_stage
    ),
    n = Inf
  )
}

# ==============================================================================
# 7. Summary
# ==============================================================================

cli::cli_h2("Summary")

n_pass <- sum(vapply(results, `[[`, logical(1), "pass"))
n_fail <- length(results) - n_pass

cli::cli_alert_info("Total assertions: {length(results)}")
cli::cli_alert_info("Passed: {n_pass}")
cli::cli_alert_info("Failed: {n_fail}")
cli::cli_alert_info("Dictionary rows: {nrow(life_stage_new)}")
cli::cli_alert_info("DB lifestage_codes: {length(db_lifestages)}")

if (n_fail > 0) {
  cli::cli_alert_danger(
    "{n_fail} assertion(s) FAILED \u2014 review output above"
  )
  quit(status = 1)
} else {
  cli::cli_alert_success("All assertions passed.")
  quit(status = 0)
}
