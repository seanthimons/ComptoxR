# Tests for ECOTOX lifestage gate (Phase 33)
# =====================================================
# Validates two gate behaviors:
#   1. Truly unknown term ("Xylophage") -> cli_abort (VALD-03)
#   2. Keyword-classifiable unmapped term ("Proto-larva") -> warn + quarantine (VALD-04)
#
# Requires local ecotox.duckdb -- all tests guarded by skip_if_not.

# -- Inline helper definitions (before test_that blocks) ----------------------

#fmt: off
.classify_lifestage_keywords <- function(descriptions) {
  rules <- tibble::tribble(
    ~priority , ~pattern                                                                                                                                                                                                                                                                                                    , ~harmonized_life_stage ,
     1L       , "(?i)egg(?!.?laying)|(?<!post-)embryo|blastula|gastrula|morula|zygot|oocyte|cleavage|neurula|neurala|zygospore"                                                                                                                                                                                             , "Egg/Embryo"           ,
     2L       , "(?i)larva|fry|naupli|nymph|tadpole|veliger|zoea|instar|pupa|prepupal|protozoea|mysis|glochidia|trochophore|caterpillar|maggot|megalopa|newborn|naiad|neonate|(?<!pre-)(?<!post-)hatch|alevin"                                                                                                              , "Larva"                ,
     3L       , "(?i)fingerling|froglet|smolt|parr|seedling|elver|juvenile|weanling|yearling|pullet|young(?!.*adult)|post-larva|post-smolt|copepodid|copepodite|swim-up|underyearling|spat|sapling|sporeling"                                                                                                               , "Juvenile"             ,
     4L       , "(?i)subadult|immature|peripubertal|sexually immature|pre-.*adult|young adult"                                                                                                                                                                                                                              , "Subadult"             ,
     5L       , "(?i)adult|mature(?!.*dormant)(?!.*vegetative)|bloom|boot|heading|tiller|jointing|internode|shoot|imago|post-emergence|sexually mature|spawn|reproduct|gestat|lactat|gamete|gametophyte|pollen|partum|F\\d+\\s*gen|flower|prebloom|laying|\\bbud\\b(?!\\s+or\\s+budding)|rhizome|cutting|scape|\\bsperm\\b" , "Adult"                ,
     6L       , "(?i)dormant|senescen|cyst|stationary.*phase|\\bseed\\b|\\bspore\\b|\\bcorm\\b|\\bcocoon\\b|\\btuber\\b|turion"                                                                                                                                                                                             , "Senescent/Dormant"    ,
    99L       , ".*"                                                                                                                                                                                                                                                                                                        , "Other/Unknown"
  )

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

life_stage <- tibble::tribble(
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

run_gate_logic <- function(con) {
  db_lifestages <- DBI::dbGetQuery(
    con,
    "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
  )$description

  unmapped <- setdiff(db_lifestages, life_stage$org_lifestage)
  if (length(unmapped) > 0) {
    keyword_mapped <- .classify_lifestage_keywords(unmapped)
    truly_unknown <- unmapped[keyword_mapped$harmonized_life_stage == "Other/Unknown"]
    if (length(truly_unknown) > 0) {
      cli::cli_abort(c(
        "ECOTOX lifestage dictionary is incomplete.",
        "i" = "{length(truly_unknown)} lifestage(s) could not be classified:",
        "*" = "{truly_unknown}",
        "i" = "Add these to the lifestage dictionary in ecotox_build.R section 16."
      ))
    }
    cli::cli_alert_warning(
      "{length(unmapped)} new lifestage(s) classified via keyword fallback. Written to lifestage_review table for manual promotion."
    )
    DBI::dbWriteTable(con, "lifestage_review", keyword_mapped, overwrite = TRUE)
  }
}

# -- Test blocks ---------------------------------------------------------------

test_that("gate aborts for truly unknown term (Xylophage)", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")

  .eco_close_con()

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eco_path())
  withr::defer({
    DBI::dbExecute(con, "DELETE FROM lifestage_codes WHERE description = 'Xylophage'")
    DBI::dbExecute(con, "DROP TABLE IF EXISTS lifestage_review")
    DBI::dbDisconnect(con, shutdown = TRUE)
  })

  DBI::dbExecute(con, "INSERT INTO lifestage_codes (code, description) VALUES ('XT', 'Xylophage')")

  expect_error(
    run_gate_logic(con),
    class = "rlang_error"
  )
})

test_that("gate warns and quarantines keyword-classifiable term (Proto-larva)", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")

  .eco_close_con()

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = eco_path())
  withr::defer({
    DBI::dbExecute(con, "DELETE FROM lifestage_codes WHERE description = 'Proto-larva'")
    DBI::dbExecute(con, "DROP TABLE IF EXISTS lifestage_review")
    DBI::dbDisconnect(con, shutdown = TRUE)
  })

  DBI::dbExecute(con, "INSERT INTO lifestage_codes (code, description) VALUES ('PL', 'Proto-larva')")

  # Gate must NOT abort -- keyword-classifiable
  expect_no_error(run_gate_logic(con))

  # Review table must exist with correct classification
  expect_true(DBI::dbExistsTable(con, "lifestage_review"))

  review <- DBI::dbReadTable(con, "lifestage_review")
  expect_true("Proto-larva" %in% review$org_lifestage)
  expect_equal(
    review$harmonized_life_stage[review$org_lifestage == "Proto-larva"],
    "Larva"
  )
  expect_equal(
    review$classification_source[review$org_lifestage == "Proto-larva"],
    "keyword_fallback"
  )
})
