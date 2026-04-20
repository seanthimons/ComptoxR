# ECOTOX Build Pipeline
# --------------------
# Downloads EPA ECOTOX ASCII data from FTP, processes into a DuckDB database
# with enrichment tables (unit conversion, lifestage, risk binning, etc.).
#
# Usage:
#   eco_install()  # locates and sources this script automatically
#   — or, from a development checkout —
#   source("data-raw/ecotox.R")
#
# Requires Suggests: arrow, janitor, lubridate, readr, readxl, rvest

.build_ecotox_db <- function() {
  # 0. Dependency check --------------------------------------------------------

  rlang::check_installed(
    c("arrow", "janitor", "lubridate", "readr", "readxl", "rvest"),
    reason = "to build the ECOTOX database from source."
  )

  # 1. Configuration -----------------------------------------------------------

  output_dir <- tools::R_user_dir("ComptoxR", "data")
  output_path <- file.path(output_dir, "ecotox.duckdb")

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 2. Staleness check ---------------------------------------------------------
  # Rebuild if DB is missing or older than 180 days.

  rebuild_is_needed <- if (!file.exists(output_path)) {
    cli::cli_alert_info("ECOTOX database not found. Building from source.")
    TRUE
  } else {
    age_days <- as.numeric(
      difftime(Sys.time(), file.info(output_path)$mtime, units = "days")
    )
    if (age_days > 180) {
      cli::cli_alert_warning(
        "ECOTOX database is {round(age_days)} days old. Rebuilding."
      )
      TRUE
    } else {
      cli::cli_alert_success(
        "ECOTOX database is up-to-date ({round(age_days)} days old). Skipping."
      )
      FALSE
    }
  }

  if (!rebuild_is_needed) {
    return(invisible(output_path))
  }

  # 3. FTP discovery + download ------------------------------------------------

  ftp_url <- "https://gaftp.epa.gov/ecotox/"

  cli::cli_alert_info("Scraping EPA ECOTOX FTP listing...")

  ftp_resp <- httr2::request(ftp_url) |>
    httr2::req_perform()

  ftp_html <- httr2::resp_body_string(ftp_resp) |>
    rvest::read_html()

  ftp_links <- ftp_html |>
    rvest::html_elements("a") |>
    rvest::html_attr("href")

  # Identify the latest ASCII zip
  zip_files <- ftp_links[grepl("zip", ftp_links, ignore.case = TRUE)]
  if (length(zip_files) == 0) {
    cli::cli_abort("No zip files found on EPA ECOTOX FTP.")
  }

  zip_df <- data.frame(file = zip_files, stringsAsFactors = FALSE)
  zip_df$date <- stringr::str_remove_all(zip_df$file, "ecotox_ascii_")
  zip_df$date <- stringr::str_remove_all(zip_df$date, "\\.zip")
  zip_df$date <- lubridate::as_date(zip_df$date, format = "%m_%d_%Y")
  zip_df <- zip_df[order(zip_df$date, decreasing = TRUE), ]

  latest_zip <- zip_df$file[1]
  latest_date <- zip_df$date[1]
  cli::cli_alert_info("Latest release: {latest_zip} ({latest_date})")

  # Temp directory for raw data
  raw_dir <- tempfile("ecotox_raw_")
  dir.create(raw_dir, recursive = TRUE)
  on.exit(unlink(raw_dir, recursive = TRUE), add = TRUE)

  zip_dest <- file.path(raw_dir, "ecotox.zip")
  cli::cli_alert_info("Downloading ECOTOX data (~500 MB)...")
  download.file(
    paste0(ftp_url, latest_zip),
    destfile = zip_dest,
    mode = "wb",
    quiet = FALSE
  )

  cli::cli_alert_info("Extracting archive...")
  utils::unzip(zip_dest, exdir = raw_dir)

  # Find the extracted folder (ecotox_ascii_MM_DD_YYYY)
  eco_folders <- list.files(raw_dir, pattern = "ecotox_ascii", full.names = TRUE)
  if (length(eco_folders) == 0) {
    cli::cli_abort("Extraction failed: no ecotox_ascii folder found.")
  }
  eco_files_dir <- eco_folders[1]

  # 4. Terms appendix download -------------------------------------------------

  xlsx_files <- ftp_links[grepl("xlsx", ftp_links, ignore.case = TRUE)]
  if (length(xlsx_files) == 0) {
    cli::cli_abort("No XLSX terms appendix found on EPA ECOTOX FTP.")
  }
  appendix_dest <- file.path(raw_dir, "ecotox_terms_appendix.xlsx")

  cli::cli_alert_info("Downloading terms appendix...")
  download.file(
    paste0(ftp_url, xlsx_files[1]),
    destfile = appendix_dest,
    mode = "wb",
    quiet = TRUE
  )

  # 5. DuckDB in-memory setup --------------------------------------------------

  eco_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:", read_only = FALSE)
  on.exit(DBI::dbDisconnect(eco_con, shutdown = TRUE), add = TRUE)

  # 6. Main file processing ----------------------------------------------------
  # Pipe-delimited .txt → Parquet → DuckDB

  cli::cli_alert_info("Removing release/readme files...")
  release_files <- list.files(eco_files_dir, pattern = "release|ASCII|Ascii", full.names = TRUE)
  if (length(release_files) > 0) {
    file.remove(release_files)
  }

  main_txts <- list.files(eco_files_dir, pattern = "\\.txt$", full.names = TRUE)
  # Exclude any remaining release files
  main_txts <- main_txts[!grepl("release", basename(main_txts), ignore.case = TRUE)]

  na_strings <- c("", "NA", "NR", "NC", "-", "--", "NONE", "UKN", "UKS")

  cli::cli_alert_info("Converting {length(main_txts)} base files...")
  purrr::walk(
    main_txts,
    function(txt_path) {
      tbl_name <- tools::file_path_sans_ext(basename(txt_path))
      cli::cli_text("  {tbl_name}")

      df <- readr::read_delim(
        file = txt_path,
        delim = "|",
        col_types = readr::cols(.default = readr::col_character()),
        na = na_strings,
        locale = readr::locale(encoding = "latin1"),
        show_col_types = FALSE
      )
      df <- janitor::remove_empty(df, which = "cols")

      pq_path <- file.path(eco_files_dir, paste0(tbl_name, ".parquet"))
      arrow::write_parquet(df, pq_path)

      DBI::dbWriteTable(eco_con, tbl_name, arrow::read_parquet(pq_path), overwrite = TRUE)
    },
    .progress = TRUE
  )

  # 7. Validation files --------------------------------------------------------

  val_dir <- file.path(eco_files_dir, "validation")
  if (dir.exists(val_dir)) {
    val_txts <- list.files(val_dir, pattern = "\\.txt$", full.names = TRUE)

    cli::cli_alert_info("Converting {length(val_txts)} validation files...")
    purrr::walk(val_txts, function(txt_path) {
      tbl_name <- tools::file_path_sans_ext(basename(txt_path))
      cli::cli_text("  {tbl_name}")

      df <- readr::read_delim(
        file = txt_path,
        delim = "|",
        col_types = readr::cols(.default = readr::col_character()),
        na = na_strings,
        locale = readr::locale(encoding = "latin1"),
        show_col_types = FALSE
      )
      df <- janitor::remove_empty(df, which = "cols")

      pq_path <- file.path(val_dir, paste0(tbl_name, ".parquet"))
      arrow::write_parquet(df, pq_path)

      DBI::dbWriteTable(eco_con, tbl_name, arrow::read_parquet(pq_path), overwrite = TRUE)
    })
  }

  # 8. Terms appendix processing -----------------------------------------------

  cli::cli_alert_info("Processing terms appendix...")

  sheet_names <- readxl::excel_sheets(appendix_dest)

  # First sheet is the table of contents
  toc_df <- readxl::read_excel(appendix_dest, sheet = sheet_names[1], skip = 2)
  eco_toc <- janitor::make_clean_names(toc_df$Title)
  eco_toc <- paste0("app_", eco_toc)

  # Process each subsequent sheet
  data_sheets <- sheet_names[-1]
  for (i in seq_along(data_sheets)) {
    tbl_name <- eco_toc[i]
    cli::cli_text("  {tbl_name}")

    sheet_df <- readxl::read_excel(appendix_dest, sheet = data_sheets[i], skip = 2)
    sheet_df <- janitor::clean_names(sheet_df)

    DBI::dbWriteTable(eco_con, tbl_name, sheet_df, overwrite = TRUE)
  }

  # 9. Eco group enrichment ----------------------------------------------------

  cli::cli_alert_info("Enriching species table with eco_group...")

  species_query <- dplyr::tbl(eco_con, "species") |>
    dplyr::mutate(
      eco_group = dplyr::case_when(
        stringr::str_detect(family, "Megachilidae|Apidae") ~ "Bees",
        stringr::str_detect(ecotox_group, "Insects/Spiders") ~ "Insects/Spiders",
        stringr::str_detect(
          ecotox_group,
          "Flowers, Trees, Shrubs, Ferns"
        ) ~ "Flowers/Trees/Shrubs/Ferns",
        stringr::str_detect(ecotox_group, "Fungi") ~ "Fungi",
        stringr::str_detect(ecotox_group, "Algae") ~ "Algae",
        stringr::str_detect(ecotox_group, "Fish") ~ "Fish",
        stringr::str_detect(ecotox_group, "Crustaceans") ~ "Crustaceans",
        stringr::str_detect(ecotox_group, "Invertebrates") ~ "Invertebrates",
        stringr::str_detect(ecotox_group, "Worms") ~ "Worms",
        stringr::str_detect(ecotox_group, "Molluscs") ~ "Molluscs",
        stringr::str_detect(ecotox_group, "Birds") ~ "Birds",
        stringr::str_detect(ecotox_group, "Mammals") ~ "Mammals",
        stringr::str_detect(ecotox_group, "Amphibians") ~ "Amphibians",
        stringr::str_detect(ecotox_group, "Reptiles") ~ "Reptiles",
        stringr::str_detect(ecotox_group, "Moss, Hornworts") ~ "Moss/Hornworts",
        .default = ecotox_group
      ),
      standard_test_species = dplyr::case_when(
        stringr::str_detect(ecotox_group, "Standard") ~ TRUE,
        .default = FALSE
      ),
      invasive_species = dplyr::case_when(
        stringr::str_detect(ecotox_group, "Invasive") ~ TRUE,
        .default = FALSE
      ),
      endangered_threatened_species = dplyr::case_when(
        stringr::str_detect(ecotox_group, "Endangered") ~ TRUE,
        .default = FALSE
      )
    )

  select_sql <- dbplyr::sql_render(species_query)
  overwrite_sql <- paste0("CREATE OR REPLACE TABLE species AS ", select_sql)
  DBI::dbExecute(eco_con, overwrite_sql)

  # 10. Unit conversion dictionary ---------------------------------------------

  cli::cli_alert_info("Writing unit conversion dictionary...")
  #fmt: table
  unit_result <- tibble::tribble(
    ~unit          , ~multiplier       , ~unit_conv          , ~type           ,
    "ag"           ,   1e-18           , "g"                 , "mass"          ,
    "fg"           ,   1e-15           , "g"                 , "mass"          ,
    "pg"           ,   1e-12           , "g"                 , "mass"          ,
    "ng"           ,   1e-09           , "g"                 , "mass"          ,
    "ug"           ,   1e-06           , "g"                 , "mass"          ,
    "mg"           ,       0.001       , "g"                 , "mass"          ,
    "g"            ,       1           , "g"                 , "mass"          ,
    "kg"           ,    1000           , "g"                 , "mass"          ,
    "kg N"         ,       1           , "kg N"              , "mass"          ,
    "t"            ,   1e+06           , "g"                 , "mass"          ,
    "ton"          ,   1e+06           , "g"                 , "mass"          ,
    "tons"         ,   1e+06           , "g"                 , "mass"          ,
    "quintal"      ,   1e+05           , "g"                 , "mass"          ,
    "q"            ,   1e+05           , "g"                 , "mass"          ,
    "pl"           ,   1e-12           , "l"                 , "volume"        ,
    "nl"           ,   1e-09           , "l"                 , "volume"        ,
    "ul"           ,   1e-06           , "l"                 , "volume"        ,
    "ml"           ,       0.001       , "l"                 , "volume"        ,
    "dl"           ,       0.1         , "l"                 , "volume"        ,
    "l"            ,       1           , "l"                 , "volume"        ,
    "lit"          ,       1           , "l"                 , "volume"        ,
    "hl"           ,     100           , "l"                 , "volume"        ,
    "pL"           ,   1e-12           , "l"                 , "volume"        ,
    "nL"           ,   1e-09           , "l"                 , "volume"        ,
    "uL"           ,   1e-06           , "l"                 , "volume"        ,
    "mL"           ,       0.001       , "l"                 , "volume"        ,
    "dL"           ,       0.1         , "l"                 , "volume"        ,
    "L"            ,       1           , "l"                 , "volume"        ,
    "hL"           ,     100           , "l"                 , "volume"        ,
    "bu"           ,      36.36872     , "l"                 , "volume"        ,
    "bushel"       ,      36.36872     , "l"                 , "volume"        ,
    "ppq"          ,   1e-06           , "ppb"               , "fraction"      ,
    "ppt"          ,       0.001       , "ppb"               , "fraction"      ,
    "ppb"          ,       1           , "ppb"               , "fraction"      ,
    "ppm"          ,    1000           , "ppb"               , "fraction"      ,
    "ppm-hour"     ,    1000           , "ppb/h"             , "fraction"      ,
    "ppm for 36hr" ,      27.77777778  , "ppb/h"             , "fraction"      ,
    "ppmv"         ,    1000           , "ppb"               , "fraction"      ,
    "ppmw"         ,    1000           , "ppb"               , "fraction"      ,
    "0/00"         ,   1e+06           , "ppb"               , "fraction"      ,
    "ptm"          ,       1           , "ppb"               , "fraction"      ,
    "no"           , NA                , NA                  , "amount"        ,
    "amol"         ,   1e-18           , "mol"               , "mol"           ,
    "fmol"         ,   1e-15           , "mol"               , "mol"           ,
    "pmol"         ,   1e-12           , "mol"               , "mol"           ,
    "nmol"         ,   1e-09           , "mol"               , "mol"           ,
    "umol"         ,   1e-06           , "mol"               , "mol"           ,
    "umoles"       ,   1e-06           , "mol"               , "mol"           ,
    "mumol"        ,   1e-09           , "mol"               , "mol"           ,
    "mmol"         ,       0.001       , "mol"               , "mol"           ,
    "cmol"         ,       0.01        , "mol"               , "mol"           ,
    "mol"          ,       1           , "mol"               , "mol"           ,
    "kmol"         ,    1000           , "mol"               , "mol"           ,
    "pM"           ,   1e-12           , "mol/l"             , "mol/volume"    ,
    "nM"           ,   1e-09           , "mol/l"             , "mol/volume"    ,
    "uM"           ,   1e-06           , "mol/l"             , "mol/volume"    ,
    "mM"           ,       0.001       , "mol/l"             , "mol/volume"    ,
    "M"            ,       1           , "mol/l"             , "mol/volume"    ,
    "molal"        ,       0.001       , "mol/g"             , "mol/mass"      ,
    "mOsm"         ,       0.001       , "Osm/l"             , "osmolarity"    ,
    "in"           ,       0.0254      , "m"                 , "length"        ,
    "yd"           ,       0.9144      , "m"                 , "length"        ,
    "ft"           ,       0.3048      , "m"                 , "length"        ,
    "linear ft"    ,       0.3048      , "m"                 , "length"        ,
    "rod"          ,       5.0292      , "m"                 , "length"        ,
    "um"           ,   1e-06           , "m"                 , "length"        ,
    "mm"           ,       0.001       , "m"                 , "length"        ,
    "cm"           ,       0.01        , "m"                 , "length"        ,
    "dm"           ,       0.1         , "m"                 , "length"        ,
    "m"            ,       1           , "m"                 , "length"        ,
    "km"           ,    1000           , "m"                 , "length"        ,
    "neq"          ,   1e-09           , "eq"                , "noscience"     ,
    "meq"          ,       0.001       , "eq"                , "noscience"     ,
    "ueq"          ,   1e-06           , "eq"                , "noscience"     ,
    "mm2"          ,   1e-06           , "m2"                , "area"          ,
    "cm2"          ,   1e-04           , "m2"                , "area"          ,
    "dm2"          ,       0.01        , "m2"                , "area"          ,
    "hm2"          ,   10000           , "m2"                , "area"          ,
    "m2"           ,       1           , "m2"                , "area"          ,
    "yd2"          ,       0.836127    , "m2"                , "area"          ,
    "ha"           ,   10000           , "m2"                , "area"          ,
    "hectare"      ,   10000           , "m2"                , "area"          ,
    "acre"         ,    4046.873       , "m2"                , "area"          ,
    "acres"        ,    4046.873       , "m2"                , "area"          ,
    "ac"           ,    4046.873       , "m2"                , "area"          ,
    "rod2"         ,      25.2929      , "m2"                , "area"          ,
    "mi2"          , 2589988.11        , "m2"                , "area"          ,
    "km2"          ,   1e+06           , "m2"                , "area"          ,
    "ft2"          ,       0.0929      , "m2"                , "area"          ,
    "sqft"         ,       0.0929      , "m2"                , "area"          ,
    "k sqft"       ,      92.9         , "m2"                , "area"          ,
    "feddan"       ,    4200           , "m2"                , "area"          ,
    "dn(Cyprus)"   ,    1338           , "m2"                , "area"          ,
    "dn(Std)"      ,    1000           , "m2"                , "area"          ,
    "%"            ,   1e+07           , "ppb"               , "fraction"      ,
    "\u2030"       ,   1e+06           , "ppb"               , "fraction"      ,
    "d"            ,      24           , "h"                 , "time"          ,
    "day"          ,      24           , "h"                 , "time"          ,
    "h"            ,       1           , "h"                 , "time"          ,
    "hr"           ,       1           , "h"                 , "time"          ,
    "hour"         ,       1           , "h"                 , "time"          ,
    "mi"           ,       0.0166667   , "h"                 , "time"          ,
    "min"          ,       0.0166667   , "h"                 , "time"          ,
    "wk"           ,     168           , "h"                 , "time"          ,
    "mo"           ,     730           , "h"                 , "time"          ,
    "yr"           ,    8760           , "h"                 , "time"          ,
    "ft3"          ,       0.02831658  , "m3"                , "volume"        ,
    "mm3"          ,   1e-09           , "m3"                , "volume"        ,
    "cm3"          ,   1e-06           , "m3"                , "volume"        ,
    "dm3"          ,       0.001       , "m3"                , "volume"        ,
    "m3"           ,       1           , "m3"                , "volume"        ,
    "fl_oz"        ,       0.02957353  , "l"                 , "volume"        ,
    "pt"           ,       0.473176473 , "l"                 , "volume"        ,
    "oz"           ,      28.34952313  , "g"                 , "mass"          ,
    "gal"          ,       3.785411784 , "l"                 , "volume"        ,
    "ga"           ,       3.785411784 , "l"                 , "volume"        ,
    "qt"           ,       0.946352946 , "l"                 , "volume"        ,
    "lb"           ,     453.592       , "g"                 , "mass"          ,
    "lbs"          ,     453.592       , "g"                 , "mass"          ,
    "PSU"          ,       1           , "PSU"               , "noscience"     ,
    "--"           , NA                , NA                  , "nodata"        ,
    "NR"           , NA                , NA                  , "nodata"        ,
    "eu"           ,       1           , "eu"                , "noscience"     ,
    "EU"           ,       1           , "eu"                , "noscience"     ,
    "MBq"          ,   1e+06           , "Bq"                , "radioactivity" ,
    "kBq"          ,    1000           , "Bq"                , "radioactivity" ,
    "Bq"           ,       1           , "Bq"                , "radioactivity" ,
    "mBq"          ,       0.001       , "Bq"                , "radioactivity" ,
    "uBq"          ,   1e-06           , "Bq"                , "radioactivity" ,
    "Ci"           ,       3.7e+10     , "Bq"                , "radioactivity" ,
    "mCI"          ,       3.7e+07     , "Bq"                , "radioactivity" ,
    "mCi"          ,       3.7e+07     , "Bq"                , "radioactivity" ,
    "mCi mg"       , NA                , NA                  , "noscience"     ,
    "uCI"          ,   37000           , "Bq"                , "radioactivity" ,
    "uCi"          ,   37000           , "Bq"                , "radioactivity" ,
    "nCI"          ,      37           , "Bq"                , "radioactivity" ,
    "nCi"          ,      37           , "Bq"                , "radioactivity" ,
    "pCI"          ,       0.037       , "Bq"                , "radioactivity" ,
    "pCi"          ,       0.037       , "Bq"                , "radioactivity" ,
    "ICU"          ,       1           , "ICU"               , "noscience"     ,
    "USP"          ,       1           , "USP"               , "noscience"     ,
    "iu"           ,       1           , "iunit"             , "noscience"     ,
    "IU"           ,       1           , "iunit"             , "noscience"     ,
    "mIU"          , NA                , NA                  , NA              ,
    "fibers"       ,       1           , "fibers"            , "noscience"     ,
    "kJ"           ,    1000           , "J"                 , "energy"        ,
    "mS"           ,       0.001       , "S"                 , "electricity"   ,
    "dS"           ,       0.1         , "S"                 , "electricity"   ,
    "org"          ,       1           , "organism"          , "noscience"     ,
    "organi"       ,       1           , "organism"          , "noscience"     ,
    "v"            , NA                , NA                  , "volume"        ,
    "% v/v"        ,   1e+07           , "ppb"               , "fraction"      ,
    "cwt"          ,   45360           , "g"                 , "mass"          ,
    "w"            , NA                , NA                  , "noscience"     ,
    "% w/v"        ,   1e+07           , "ppb"               , "fraction"      ,
    "in dia"       , NA                , NA                  , "noscience"     ,
    "egg"          ,       1           , "egg"               , "noscience"     ,
    "pellets"      ,       1           , "pellets"           , "noscience"     ,
    "bee"          ,       1           , "bee"               , "noscience"     ,
    "fish"         ,       1           , "fish"              , "noscience"     ,
    "dpm"          ,       0.01666667  , "Bq"                , "radioactivity" ,
    "sd"           ,       1           , "seed"              , "noscience"     ,
    "seed"         ,       1           , "seed"              , "noscience"     ,
    "seeds"        ,       1           , "seed"              , "noscience"     ,
    "cntr"         ,       1           , "container"         , "noscience"     ,
    "plot"         ,       1           , "plot"              , "noscience"     ,
    "cpm"          ,       1           , "cpm"               , "noscience"     ,
    "mound"        ,       1           , "mound"             , "noscience"     ,
    "mouse unit"   ,       1           , "mouse unit"        , "noscience"     ,
    "disk"         ,       1           , "disk"              , "noscience"     ,
    "cc"           ,       1           , "cocoon"            , "noscience"     ,
    "cell"         ,       1           , "cell"              , "noscience"     ,
    "dose"         ,       1           , "dose"              , "noscience"     ,
    "em"           ,       1           , "embryo"            , "noscience"     ,
    "granules"     ,       1           , "granule"           , "noscience"     ,
    "lf"           ,       1           , "leaf"              , "noscience"     ,
    "tank"         ,       1           , "tank"              , "noscience"     ,
    "tbsp"         ,       1           , "tablespoon"        , "noscience"     ,
    "Tbsp"         ,       1           , "tablespoon"        , "noscience"     ,
    "tsp"          ,       1           , "teaspoon"          , "noscience"     ,
    "u"            ,       1           , "unit"              , "noscience"     ,
    "U"            ,       1           , "unit"              , "noscience"     ,
    "unit"         ,       1           , "unit"              , "noscience"     ,
    "units"        ,       1           , "unit"              , "noscience"     ,
    "U of fl"      ,       1           , "unit fluorescence" , "noscience"     ,
    "ML"           ,       1           , "male"              , "noscience"     ,
    "N"            ,       1           , "Normal"            , "noscience"     ,
    "RA"           ,       1           , "ratio"             , "noscience"     ,
    "ug-atoms"     ,       1           , "ug-atoms"          , "noscience"     ,
    "u-atoms"      ,       1           , "u-atoms"           , "noscience"     ,
    "PIg"          ,       1           , "PIg"               , "noscience"     ,
    "g d"          ,       1           , NA                  , "noscience"     ,
    "ng eq"        ,       1           , NA                  , "noscience"     ,
    "6 in pots"    ,       1           , "6_in pot"          , "noscience"
  )

  DBI::dbWriteTable(eco_con, "app_unit_conversion", unit_result, overwrite = TRUE)

  # 11. Unit symbols dictionary ------------------------------------------------

  cli::cli_alert_info("Writing unit symbols dictionary...")

  unit_symbols <- tibble::tribble(
    ~symbol    , ~name                                  ,
    "CEC"      , "soil.cation.exchange"                 ,
    "DT"       , "digestivetract"                       ,
    "100% O2"  , "100%O2"                               ,
    "H2O"      , "water"                                ,
    "TI"       , "tissue"                               ,
    "ae"       , "acidequivalents"                      ,
    "agar"     , "agar"                                 ,
    "ai"       , "activeingredient"                     ,
    "bdwt"     , "bodyweight"                           ,
    "blood"    , "blood"                                ,
    "bt"       , "bait"                                 ,
    "body wt"  , "bodyweight"                           ,
    "bw"       , "bodyweight"                           ,
    "bwt"      , "bodyweight"                           ,
    "caliper"  , "caliper"                              ,
    "circ"     , "circular"                             ,
    "canopy"   , "canopy"                               ,
    "dbh"      , "diameterbreastheight"                 ,
    "dia"      , "diameter"                             ,
    "diet"     , "diet"                                 ,
    "disk"     , "disk"                                 ,
    "dry wght" , "dryweight"                            ,
    "dw"       , "dry weight"                           ,
    "dry"      , "dry"                                  ,
    "dry_diet" , "drydiet"                              ,
    "eu"       , "experimentalunit"                     ,
    "fd"       , "food"                                 ,
    "food"     , "food"                                 ,
    "humus"    , "humus"                                ,
    "ht"       , "plant height"                         ,
    "ld"       , "lipid"                                ,
    "lipid"    , "lipid"                                ,
    "litter"   , "litter"                               ,
    "linear"   , "linear"                               ,
    "mat"      , "material"                             ,
    "media"    , "media"                                ,
    "om"       , "organicmatter"                        ,
    "org"      , "organism"                             ,
    "pair"     , "pair"                                 ,
    "pellet"   , "pellet"                               ,
    "plt"      , "pellet"                               ,
    "pro"      , "protein"                              ,
    "protein"  , "protein"                              ,
    "soil"     , "soil"                                 ,
    "solv"     , "solvent"                              ,
    "solvent"  , "solvent"                              ,
    "soln"     , "solution"                             ,
    "tubers"   , "tubers"                               ,
    "tkdi"     , "trunk diameter at 1.5 m above ground" ,
    "wet wght" , "wetweight"                            ,
    "wet_bdwt" , "wetbodyweight"                        ,
    "wet"      , "wet"                                  ,
    "wet wt"   , "wetweight"                            ,
    "wt"       , "wet"                                  ,
    "wght"     , "weight"
  )

  unit_symbols <- dplyr::bind_rows(
    unit_symbols,
    dplyr::mutate(unit_symbols, symbol = toupper(symbol))
  )

  DBI::dbWriteTable(eco_con, "dict_unit_symbols", unit_symbols, overwrite = TRUE)

  # 12. Duration conversion ----------------------------------------------------

  cli::cli_alert_info("Building duration conversion table...")

  duration_conversion <- dplyr::tbl(eco_con, "duration_unit_codes") |>
    dplyr::mutate(
      base_unit = dplyr::case_when(
        stringr::str_detect(tolower(description), "minute") ~ "minutes",
        stringr::str_detect(tolower(description), "second") ~ "seconds",
        stringr::str_detect(tolower(description), "hour") ~ "hours",
        stringr::str_detect(tolower(description), "day") ~ "days",
        stringr::str_detect(tolower(description), "week") ~ "weeks",
        stringr::str_detect(tolower(description), "month") ~ "months",
        stringr::str_detect(tolower(description), "year") ~ "years",
        .default = NA
      ),
      conversion_factor_duration = dplyr::case_when(
        stringr::str_detect(tolower(description), "minute") ~ 1 / 60,
        stringr::str_detect(tolower(description), "second") ~ 1 / 3600,
        stringr::str_detect(tolower(description), "hour") ~ 1,
        stringr::str_detect(tolower(description), "day") ~ 24,
        stringr::str_detect(tolower(description), "week") ~ 24 * 7,
        stringr::str_detect(tolower(description), "month") ~ 24 * 30.43685,
        .default = 1
      ),
      cur_unit_duration = dplyr::case_when(
        !is.na(base_unit) ~ "h",
        .default = code
      )
    ) |>
    dplyr::collect()

  DBI::dbWriteTable(eco_con, "duration_conversion", duration_conversion, overwrite = TRUE)

  # 13. Test-result duration dictionary ----------------------------------------

  cli::cli_alert_info("Writing test-result duration dictionary...")
  #fmt: table
  test_result_duration_dictionary <- tibble::tribble(
    ~eco_group                            , ~final_test_type , ~effect               , ~exposure_group , ~unit           , ~endpoint                    , ~duration                            ,
    # Mammals
    "Mammals"                             , "acute"          , "MOR"                 , c("ORAL", NA)   , "g/g"           , "LD50"                       , NULL                                 ,
    "Mammals"                             , "chronic"        , "MOR"                 , c("ORAL", NA)   , "g/g/d"         , c("NOEL", "NR-ZERO")         , NULL                                 ,
    # Birds, Amphibians, Reptiles
    c("Birds", "Amphibians", "Reptiles")  , "acute"          , "MOR"                 , c("ORAL", NA)   , "g/g"           , "LD50"                       , NULL                                 ,
    c("Birds", "Amphibians", "Reptiles")  , "chronic"        , "MOR"                 , c("ORAL", NA)   , "g/g/d"         , c("NOEL", "NR-ZERO")         , NULL                                 ,
    # Fish
    "Fish"                                , "acute"          , "MOR"                 , NULL            , "g/L"           , c("LD50", "EC50", "LC50")    , expr(new_dur == 96)                  ,
    "Fish"                                , "chronic"        , "MOR"                 , NULL            , "g/L"           , c("LD50", "EC50", "LC50")    , expr(new_dur >= 144)                 ,
    "Fish"                                , "chronic"        , "MOR"                 , NULL            , "g/L"           , c("NOEC", "NOEL", "NR-ZERO") , expr(new_dur == 504)                 ,
    # Bees
    "Bees"                                , "acute"          , "MOR"                 , NULL            , "g/bee"         , c("LD50", "LC50")            , expr(new_dur %in% c(24, 28, 72))     ,
    "Bees"                                , "chronic"        , "MOR"                 , NULL            , "g/bee"         , c("LD50", "LC50")            , expr(new_dur == 240)                 ,
    # Insects/Spiders
    "Insects/Spiders"                     , "acute"          , "MOR"                 , NULL            , c("g/L", "g/g") , c("LD50", "LC50", "EC50")    , expr(new_dur %in% c(24, 48, 72))     ,
    "Insects/Spiders"                     , "chronic"        , "MOR"                 , NULL            , c("g/L", "g/g") , c("NOEL", "NOEC", "NR-ZERO") , expr(new_dur %in% c(504, 672))       ,
    # Invertebrates, Molluscs
    c("Invertebrates", "Molluscs")        , "acute"          , "MOR"                 , NULL            , c("g/L", "g/g") , c("LD50", "LC50", "EC50")    , expr(new_dur %in% c(24, 48, 72, 96)) ,
    c("Invertebrates", "Molluscs")        , "chronic"        , "MOR"                 , NULL            , c("g/L", "g/g") , c("LD50", "LC50", "EC50")    , expr(new_dur %in% c(504, 672))       ,
    # Worms
    "Worms"                               , "acute"          , "MOR"                 , NULL            , "g/g"           , c("LD50", "LC50", "EC50")    , expr(new_dur == 336)                 ,
    "Worms"                               , "chronic"        , "MOR"                 , NULL            , "g/g"           , c("NOEC", "NOEL", "NR-ZERO") , expr(new_dur <= 336)                 ,
    # Crustaceans
    "Crustaceans"                         , "acute"          , "MOR"                 , NULL            , "g/L"           , c("LD50", "LC50", "EC50")    , expr(new_dur <= 96)                  ,
    "Crustaceans"                         , "chronic"        , "MOR"                 , NULL            , "g/L"           , c("NOEC", "NOEL", "NR-ZERO") , expr(new_dur >= 672)                 ,
    # Algae, Fungi, Moss, Hornworts
    c("Algae", "Fungi", "Moss/Hornworts") , "acute"          , NULL                  , NULL            , "g/L"           , c("LD50", "LC50", "EC50")    , expr(new_dur <= 168)                 ,
    c("Algae", "Fungi", "Moss/Hornworts") , "chronic"        , NULL                  , NULL            , "g/L"           , c("NOEC", "NOEL", "NR-ZERO") , expr(new_dur == 96)                  ,
    # Flowers, Trees, Shrubs, Ferns
    "Flowers/Trees/Shrubs/Ferns"          , "acute"          , NULL                  , NULL            , "g/L"           , c("LD50", "LC50", "EC50")    , expr(new_dur <= 168)                 ,
    "Flowers/Trees/Shrubs/Ferns"          , "chronic"        , expr(effect != "MOR") , NULL            , NULL            , c("NOEC", "NOEL", "NR-ZERO") , NULL
  ) |>
    dplyr::relocate(final_test_type, .after = dplyr::last_col())

  # Serialize list and expression columns to character strings for DB storage
  test_result_duration_dictionary <- dplyr::mutate(
    test_result_duration_dictionary,
    dplyr::across(
      where(is.list),
      ~ purrr::map_chr(.x, function(item) {
        if (is.null(item)) {
          NA_character_
        } else if (is.call(item) || is.expression(item) || is.symbol(item)) {
          deparse(item)
        } else {
          paste(stats::na.omit(item), collapse = "|")
        }
      })
    )
  )

  DBI::dbWriteTable(eco_con, "dict_test_result_duration", test_result_duration_dictionary, overwrite = TRUE)

  # 14. Risk binning rules -----------------------------------------------------

  cli::cli_alert_info("Writing risk binning rules...")
  #fmt: table
  risk_binning_rules <- tibble::tribble(
    ~eco_group      , ~test_type , ~bin , ~lower_bound , ~upper_bound ,
    # Mammals
    "Mammals"       , "acute"    , "VH" , -Inf         ,   10         ,
    "Mammals"       , "acute"    , "H"  ,   10         ,   50         ,
    "Mammals"       , "acute"    , "M"  ,   50         ,  500         ,
    "Mammals"       , "acute"    , "L"  ,  500         , 2000         ,
    "Mammals"       , "acute"    , "XL" , 2000         , Inf          ,
    "Mammals"       , "chronic"  , "VH" , -Inf         ,    1         ,
    "Mammals"       , "chronic"  , "H"  ,    1         ,   10         ,
    "Mammals"       , "chronic"  , "M"  ,   10         ,  200         ,
    "Mammals"       , "chronic"  , "L"  ,  200         , 1000         ,
    "Mammals"       , "chronic"  , "XL" , 1000         , Inf          ,
    # Birds
    "Birds"         , "acute"    , "VH" , -Inf         ,   10         ,
    "Birds"         , "acute"    , "H"  ,   10         ,   50         ,
    "Birds"         , "acute"    , "M"  ,   50         ,  500         ,
    "Birds"         , "acute"    , "L"  ,  500         , 2000         ,
    "Birds"         , "acute"    , "XL" , 2000         , Inf          ,
    "Birds"         , "chronic"  , "VH" , -Inf         ,    1         ,
    "Birds"         , "chronic"  , "H"  ,    1         ,   10         ,
    "Birds"         , "chronic"  , "M"  ,   10         ,  200         ,
    "Birds"         , "chronic"  , "L"  ,  200         , 1000         ,
    "Birds"         , "chronic"  , "XL" , 1000         , Inf          ,
    # Fish
    "Fish"          , "acute"    , "VH" , -Inf         ,    0.1       ,
    "Fish"          , "acute"    , "H"  ,    0.1       ,    1         ,
    "Fish"          , "acute"    , "M"  ,    1         ,   10         ,
    "Fish"          , "acute"    , "L"  ,   10         ,  100         ,
    "Fish"          , "acute"    , "XL" ,  100         , Inf          ,
    "Fish"          , "chronic"  , "VH" , -Inf         ,    0.01      ,
    "Fish"          , "chronic"  , "H"  ,    1         ,   10         ,
    "Fish"          , "chronic"  , "M"  ,   10         ,  200         ,
    "Fish"          , "chronic"  , "L"  ,  200         , 1000         ,
    "Fish"          , "chronic"  , "XL" , 1000         , Inf          ,
    # Bees
    "Bees"          , "acute"    , "VH" , -Inf         ,    0.1       ,
    "Bees"          , "acute"    , "H"  ,    0.1       ,    1         ,
    "Bees"          , "acute"    , "M"  ,    1         ,   10         ,
    "Bees"          , "acute"    , "L"  ,   10         ,  100         ,
    "Bees"          , "acute"    , "XL" ,  100         , Inf          ,
    "Bees"          , "chronic"  , "VH" , -Inf         ,    0.01      ,
    "Bees"          , "chronic"  , "H"  ,    1         ,   10         ,
    "Bees"          , "chronic"  , "M"  ,   10         ,  200         ,
    "Bees"          , "chronic"  , "L"  ,  200         , 1000         ,
    "Bees"          , "chronic"  , "XL" , 1000         , Inf          ,
    # Insects
    "Insects"       , "acute"    , "VH" , -Inf         ,    0.1       ,
    "Insects"       , "acute"    , "H"  ,    0.1       ,    1         ,
    "Insects"       , "acute"    , "M"  ,    1         ,   10         ,
    "Insects"       , "acute"    , "L"  ,   10         ,  100         ,
    "Insects"       , "acute"    , "XL" ,  100         , Inf          ,
    "Insects"       , "chronic"  , "VH" , -Inf         ,    0.01      ,
    "Insects"       , "chronic"  , "H"  ,    1         ,   10         ,
    "Insects"       , "chronic"  , "M"  ,   10         ,  200         ,
    "Insects"       , "chronic"  , "L"  ,  200         , 1000         ,
    "Insects"       , "chronic"  , "XL" , 1000         , Inf          ,
    # Invertebrates
    "Invertebrates" , "acute"    , "VH" , -Inf         ,    0.1       ,
    "Invertebrates" , "acute"    , "H"  ,    0.1       ,    1         ,
    "Invertebrates" , "acute"    , "M"  ,    1         ,   10         ,
    "Invertebrates" , "acute"    , "L"  ,   10         ,  100         ,
    "Invertebrates" , "acute"    , "XL" ,  100         , Inf          ,
    "Invertebrates" , "chronic"  , "VH" , -Inf         ,    0.01      ,
    "Invertebrates" , "chronic"  , "H"  ,    1         ,   10         ,
    "Invertebrates" , "chronic"  , "M"  ,   10         ,  200         ,
    "Invertebrates" , "chronic"  , "L"  ,  200         , 1000         ,
    "Invertebrates" , "chronic"  , "XL" , 1000         , Inf          ,
    # Worms
    "Worms"         , "acute"    , "VH" , -Inf         ,    0.1       ,
    "Worms"         , "acute"    , "H"  ,    0.1       ,    1         ,
    "Worms"         , "acute"    , "M"  ,    1         ,   10         ,
    "Worms"         , "acute"    , "L"  ,   10         ,  100         ,
    "Worms"         , "acute"    , "XL" ,  100         , Inf          ,
    "Worms"         , "chronic"  , "VH" , -Inf         ,    0.01      ,
    "Worms"         , "chronic"  , "H"  ,    1         ,   10         ,
    "Worms"         , "chronic"  , "M"  ,   10         ,  200         ,
    "Worms"         , "chronic"  , "L"  ,  200         , 1000         ,
    "Worms"         , "chronic"  , "XL" , 1000         , Inf          ,
    # Crustaceans
    "Crustaceans"   , "acute"    , "VH" , -Inf         ,    0.1       ,
    "Crustaceans"   , "acute"    , "H"  ,    0.1       ,    1         ,
    "Crustaceans"   , "acute"    , "M"  ,    1         ,   10         ,
    "Crustaceans"   , "acute"    , "L"  ,   10         ,  100         ,
    "Crustaceans"   , "acute"    , "XL" ,  100         , Inf          ,
    "Crustaceans"   , "chronic"  , "VH" , -Inf         ,    0.01      ,
    "Crustaceans"   , "chronic"  , "H"  ,    1         ,   10         ,
    "Crustaceans"   , "chronic"  , "M"  ,   10         ,  200         ,
    "Crustaceans"   , "chronic"  , "L"  ,  200         , 1000         ,
    "Crustaceans"   , "chronic"  , "XL" , 1000         , Inf
  )

  DBI::dbWriteTable(eco_con, "dict_risk_binning", risk_binning_rules, overwrite = TRUE)

  # 15. Full unit conversion ---------------------------------------------------

  cli::cli_alert_info("Building full unit conversion tables...")

  units_intermediate <- dplyr::tbl(eco_con, "results") |>
    dplyr::select(orig = conc1_unit, test_id) |>
    dplyr::inner_join(
      dplyr::tbl(eco_con, "tests") |>
        dplyr::select(
          test_id,
          test_cas,
          species_number,
          reference_number,
          organism_habitat
        ),
      by = "test_id"
    ) |>
    dplyr::inner_join(
      dplyr::tbl(eco_con, "references") |>
        dplyr::select(reference_number, publication_year),
      by = "reference_number"
    ) |>
    dplyr::group_by(orig, organism_habitat) |>
    dplyr::summarize(
      n = dplyr::n(),
      cas_n = dplyr::n_distinct(test_cas),
      species_n = dplyr::n_distinct(species_number),
      ref_n = dplyr::n_distinct(reference_number),
      date_n = dplyr::n_distinct(publication_year),
      ref_date = max(
        dplyr::sql("TRY_CAST(REPLACE(publication_year, 'xx', '15') AS NUMERIC)"),
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      dplyr::desc(n),
      dplyr::desc(cas_n),
      dplyr::desc(species_n),
      dplyr::desc(ref_n)
    ) |>
    dplyr::collect() |>
    dplyr::select(
      -cas_n,
      species_n,
      ref_n,
      -date_n,
      -ref_date
    ) |>
    dplyr::mutate(
      idx = seq_len(dplyr::n()),
      # One-off injections
      raw = stringr::str_replace_all(
        orig,
        c(
          "1k" = "1000",
          "mgdrydiet" = "mg dry_diet",
          "gwetbdwt" = "g wet_bdwt",
          "6 in pots" = "6inpots",
          "u-atoms" = "u_atoms",
          "ug-atoms" = "ug_atoms",
          "0/00" = "ppt",
          "\\bppmw\\b" = "ppm",
          "\\bppmv\\b" = "ppm",
          "\\bppm w/w\\b" = "ppm",
          "\\bml\\b" = "mL",
          "\\bul\\b" = "uL",
          "\\bof\\b" = "",
          "\\bmi\\b" = "min",
          " for " = "/",
          "fl oz" = "fl_oz",
          "ppt v/v" = "mL/L",
          "ppm w/v" = "mg/L",
          "-" = "/"
        )
      ) |>
        stringr::str_squish()
    )

  # Build symbol pattern for replacement
  sym_pattern <- dplyr::tbl(eco_con, "dict_unit_symbols") |>
    dplyr::collect() |>
    dplyr::arrange(-stringr::str_length(symbol))
  sym_regex <- sym_pattern |>
    dplyr::pull(symbol) |>
    stringr::str_escape() |>
    (\(x) paste0("(?<!\\w)", x, "(?!\\w)"))() |>
    stringr::str_flatten("|")

  units_intermediate <- units_intermediate |>
    dplyr::mutate(
      raw = stringr::str_replace_all(raw, sym_regex, "") |>
        stringr::str_squish() |>
        # Add a space between numbers and letters where missing
        stringr::str_replace_all("(?<=\\d)(?=[a-zA-Z])", " ") |>
        stringr::str_replace_all(c("/ " = "/", "% " = "%_")) |>
        # Replace space with underscore after numbers
        stringr::str_replace_all(
          "(\\b\\d*\\.?\\d+) (?=[[:alpha:]]|\\d)",
          "\\1_"
        ) |>
        stringr::str_replace_all(
          c(
            " in " = "",
            " in" = "",
            " " = "/",
            "//" = "/",
            "%_v/v" = "%_v_v",
            "%_w/v" = "%_w_v",
            "%_w/w" = "%_w_w",
            "%_g/g" = "%_w_w",
            "6inpots" = "6 in pots"
          )
        ) |>
        stringr::str_squish() |>
        stringr::str_remove("/$"),

      has_number = stringr::str_detect(raw, pattern = "/\\d+"),
      suffix = stringr::str_extract_all(orig, sym_regex),
      suffix = purrr::map_chr(suffix, ~ paste(.x, collapse = " ")),
      u = raw
    ) |>
    tidyr::separate_wider_delim(
      u,
      delim = "/",
      names_sep = "_",
      too_few = "align_start"
    ) |>
    dplyr::mutate(
      dplyr::across(dplyr::starts_with("u"), ~ dplyr::na_if(.x, "")),
      part_counts = rowSums(
        !is.na(dplyr::select(
          dplyr::pick(dplyr::starts_with("u")),
          dplyr::everything()
        ))
      )
    ) |>
    dplyr::relocate(part_counts, .after = has_number) |>
    tidyr::pivot_longer(
      cols = dplyr::starts_with("u"),
      names_to = "name"
    ) |>
    dplyr::mutate(
      value = dplyr::case_when(
        value == "%_" ~ "%",
        value == "%_v_v" ~ "% v/v",
        value == "%_w_v" ~ "% w/v",
        value == "%_w_w" ~ "% w/v",
        value == "u_atoms" ~ "u-atoms",
        value == "ug_atoms" ~ "ug-atoms",
        .default = value
      ),
      num_mod = stringr::str_extract(value, "\\b\\d*\\.?\\d+_") |>
        stringr::str_remove_all("_") |>
        as.numeric(),
      value = stringr::str_remove_all(value, "\\b\\d*\\.?\\d+_") |>
        stringr::str_squish()
    ) |>
    # Join against unit dictionary
    dplyr::left_join(
      DBI::dbReadTable(eco_con, "app_unit_conversion"),
      by = c("value" = "unit")
    ) |>
    tidyr::pivot_wider(
      names_from = name,
      values_from = value:type
    ) |>
    # Replace NA with 1 in num_mod and multiplier columns
    dplyr::mutate(
      dplyr::across(dplyr::matches("^(num_mod|mult)"), ~ dplyr::if_else(is.na(.x), 1, .x))
    ) |>
    # Calculate the conversion factor per row
    dplyr::rowwise() |>
    dplyr::mutate(
      numer = dplyr::c_across(dplyr::starts_with("multiplier_u_"))[1] *
        dplyr::c_across(dplyr::starts_with("num_mod_u_"))[1],
      denoms = list(
        dplyr::c_across(dplyr::starts_with("multiplier_u_"))[-1] *
          dplyr::c_across(dplyr::starts_with("num_mod_u_"))[-1]
      ),
      conversion_factor = {
        if (length(denoms) > 0) {
          numer / purrr::reduce(denoms, `*`)
        } else {
          numer
        }
      }
    ) |>
    dplyr::ungroup() |>
    # Create cur_unit and cur_unit_type
    tidyr::unite("cur_unit", dplyr::starts_with("unit_conv_u_"), sep = "/", na.rm = TRUE) |>
    tidyr::unite("cur_unit_type", dplyr::starts_with("type_u_"), sep = "/", na.rm = TRUE) |>
    dplyr::mutate(
      unit_domain = dplyr::case_when(
        stringr::str_detect(cur_unit_type, "noscience") | cur_unit_type == "" ~
          "Invalid / Uncategorized",
        stringr::str_ends(cur_unit_type, "/time") &
          stringr::str_count(cur_unit_type, "/") == 2 ~
          "Dosing Rate",
        cur_unit_type %in% c("mass/area", "volume/area", "mol/area") ~
          "Application Rate",
        cur_unit_type %in% c("mass/volume", "mol/volume", "fraction/volume") ~
          "Concentration (Liquid)",
        cur_unit_type %in% c("mass/mass", "mol/mass", "volume/mass") ~
          "Concentration (Matrix)",
        cur_unit_type %in% c("mass/time", "volume/time", "fraction/time") ~
          "Rate",
        cur_unit_type %in% c("fraction", "volume/volume") ~
          "Ratio / Fraction",
        stringr::str_starts(cur_unit_type, "radioactivity") ~
          "Radioactivity",
        cur_unit_type %in% c("mass/length", "volume/length") ~
          "Linear Density",
        cur_unit_type == "mass" ~ "Mass",
        cur_unit_type == "volume" ~ "Volume",
        cur_unit_type == "mol" ~ "Amount (molar)",
        cur_unit_type == "length" ~ "Length",
        cur_unit_type == "time" ~ "Time",
        TRUE ~ "Other Complex Unit"
      )
    )

  unit_conversion <- units_intermediate |>
    dplyr::select(
      orig,
      cur_unit_result = cur_unit,
      suffix,
      cur_unit_type,
      conversion_factor_unit = conversion_factor,
      unit_domain
    ) |>
    dplyr::distinct(orig, .keep_all = TRUE)

  DBI::dbWriteTable(eco_con, "z_unit_intermediate", units_intermediate, overwrite = TRUE)
  DBI::dbWriteTable(eco_con, "unit_conversion", unit_conversion, overwrite = TRUE)

  # 16. Lifestage dictionary ---------------------------------------------------

  cli::cli_alert_info("Writing lifestage dictionary...")

  .classify_lifestage_keywords <- function(descriptions) {
    # Developmental stage rules -- no "Reproductive" category.
    # Reproductive status is captured independently via the reproductive_stage flag.
    #fmt: off
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

  #fmt: off
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

  DBI::dbWriteTable(eco_con, "lifestage_dictionary", life_stage, overwrite = TRUE)

  # -- Build gate: detect unmapped lifestage terms --
  db_lifestages <- DBI::dbGetQuery(
    eco_con,
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
    DBI::dbWriteTable(eco_con, "lifestage_review", keyword_mapped, overwrite = TRUE)
  }

  # 17. Effects super-group ----------------------------------------------------

  cli::cli_alert_info("Building effects group dictionary...")

  effect_conversion <-
    dplyr::tbl(eco_con, "app_effect_groups") |>
    dplyr::mutate(
      effect_group = stringr::str_sub(group_effect_term_s, 1, 3)
    ) |>
    dplyr::rename(
      term = group_effect_term_s,
      effect_description = description,
      effect_definition = definition
    ) |>
    dplyr::collect() |>
    tidyr::separate_longer_delim(cols = c(term, effect_description), delim = "/") |>
    tidyr::separate_longer_delim(cols = c(term, effect_description), delim = ",") |>
    dplyr::mutate(
      dplyr::across(
        c(effect_description, term),
        ~ stringr::str_squish(.x)
      )
    ) |>
    dplyr::distinct() |>
    dplyr::arrange(effect_group)

  effect_conversion <- effect_conversion |>
    dplyr::inner_join(
      effect_conversion |>
        dplyr::select(term, super_effect_description = effect_description) |>
        dplyr::distinct(term, .keep_all = TRUE),
      by = dplyr::join_by(effect_group == term)
    )

  DBI::dbWriteTable(eco_con, "effect_groups_dictionary", effect_conversion, overwrite = TRUE)

  # 18. Persist + metadata -----------------------------------------------------

  cli::cli_alert_info("Persisting database to disk...")

  # Windows path fix for DuckDB ATTACH
  safe_output_path <- gsub("\\\\", "/", output_path)

  persist_sql <- glue::glue(
    "ATTACH '{safe_output_path}' AS ecotox;
   COPY FROM DATABASE memory TO ecotox;
   DETACH ecotox;"
  )
  DBI::dbExecute(eco_con, persist_sql)

  # Write metadata into the persisted file
  persist_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = output_path, read_only = FALSE)
  on.exit(DBI::dbDisconnect(persist_con, shutdown = TRUE), add = TRUE)

  metadata <- data.frame(
    key = c("build_date", "ecotox_release", "ecotox_release_date", "builder", "builder_version"),
    value = c(
      as.character(Sys.Date()),
      latest_zip,
      as.character(latest_date),
      "ComptoxR",
      as.character(utils::packageVersion("ComptoxR"))
    ),
    stringsAsFactors = FALSE
  )
  DBI::dbWriteTable(persist_con, "_metadata", metadata, overwrite = TRUE)

  cli::cli_alert_success(
    "ECOTOX database built at {.path {output_path}}"
  )
  cli::cli_alert_info(
    "Release: {latest_zip} ({latest_date})"
  )

  invisible(output_path)
}
.build_ecotox_db()
