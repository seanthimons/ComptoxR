# data-raw/pt.R
# Builds the `pt` package data object (periodic table with oxidation states,
# element list, and isotopes/nuclides annotated with DTXSIDs).
#
# Run this script to regenerate data/pt.rda:
#   source("data-raw/pt.R")
#
# Prerequisites:
#   - DSSTox database installed (dss_install())
#   - Valid ctx_api_key set (Sys.setenv(ctx_api_key = "..."))
#   - Packages: dplyr, tidyr, stringr, purrr, tibble, rvest, duckdb, usethis
#
# NOTE: This script opens a read-write connection to the DSSTox DuckDB file
# (for temporary table support). Do not run while a package session has an
# active dss_connect() open — disconnect first with dss_disconnect().

# packages ----------------------------------------------------------------
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(tibble)
library(rvest)
library(duckdb)
library(ComptoxR)

if (!nzchar(Sys.getenv("ctx_api_key"))) {
  stop("ctx_api_key not set. Run: Sys.setenv(ctx_api_key = 'YOUR_KEY')")
}

`%ni%` <- Negate(`%in%`)

# DSSTox connection -------------------------------------------------------
# Open a dedicated read-write connection for this build script.
# Temporary tables (for nuclide joins) require a non-read-only connection.
dsstox_path_val <- file.path(tools::R_user_dir("ComptoxR", "data"), "dsstox.duckdb")
if (!file.exists(dsstox_path_val)) {
  stop("DSSTox database not found at: ", dsstox_path_val,
       "\nRun dss_install() first.")
}

dsstox_db <- DBI::dbConnect(
  duckdb::duckdb(),
  dbdir = dsstox_path_val,
  read_only = FALSE
)

# PT list  ----------------------------------------------------------------
pt <- list()

# Oxidation states --------------------------------------------------------
ind_html <-
  httr2::request("https://en.wikipedia.org/wiki/Oxidation_state#List_of_oxidation_states_of_the_elements") |>
  httr2::req_user_agent("ComptoxR data-raw script; https://github.com/seanthimons/ComptoxR") |>
  httr2::req_perform() |>
  httr2::resp_body_html() |>
  rvest::html_nodes("table.wikitable") |>
  rvest::html_table()

pt$oxidation_state <- ind_html[[3]] %>%
  .[4:121, 1:19] %>%
  setNames(., LETTERS[1:19]) %>%
  as_tibble() %>%
  mutate(
    I = as.character(I),
    A = as.numeric(A)
  ) %>%
  mutate(across(B:S, ~ na_if(., ""))) %>%
  pivot_longer(
    .,
    cols = D:R,
    values_to = 'oxidation_state',
    values_drop_na = T
  ) %>%
  select(-name) %>%
  setNames(., c('number', 'element', 'symbol', 'group', 'oxs')) %>%
  mutate(
    ox_symbol = case_when(
      stringr::str_detect(oxs, "\\+") ~ "+",
      stringr::str_detect(oxs, "\u2212") ~ "-",
      .default = " "
    ),
    charge_number = stringr::str_remove_all(oxs, "[[:symbol:]]"),
    oxidation_state = paste0(ox_symbol, charge_number) %>% str_trim(),
    smiles = case_when(
      oxidation_state == '0' ~ paste0("[", symbol, "]"),
      oxidation_state == '-1' | oxidation_state == '+1' ~ paste0("[", symbol, ox_symbol, "]"),
      oxidation_state == '+2' | oxidation_state == '-2' ~ paste0("[", symbol, ox_symbol, ox_symbol, "]"),
      .default = paste0("[", symbol, oxidation_state, "]")
    ),
  ) %>% select(!c(oxs, ox_symbol, charge_number))

ox_dsstox <- dss_query(query = pt$oxidation_state$smiles, con = dsstox_db) %>%
  select(dtxsid = DTXSID, values)

pt$oxidation_state <- left_join(
  pt$oxidation_state,
  ox_dsstox,
  join_by(smiles == values)
)

rm(ind_html)

# Elements table ----------------------------------------------------------
pt$elements <- httr2::request("https://en.wikipedia.org/wiki/List_of_chemical_elements") |>
  httr2::req_user_agent("ComptoxR data-raw script; https://github.com/seanthimons/ComptoxR") |>
  httr2::req_perform() |>
  httr2::resp_body_html() |>
  rvest::html_nodes(".wikitable") |>
  rvest::html_table() |>
  pluck(1) %>%
  unname() %>%
  tibble::as_tibble(.name_repair = 'universal') %>%
  select(1:3) %>%
  set_names(., c('Number', 'Symbol', 'Name')) %>%
  slice(., 2:nrow(.)) %>%
  mutate(Number = as.integer(Number))

element_list <- ct_chemical_list_search_by_name(
  'ELEMENTS',
  projection = 'chemicallistwithdtxsids',
  extract_dtxsids = TRUE
) %>%
  pluck(., 1) %>%
  ct_chemical_detail_search_bulk(query = ., projection = 'chemicaldetailall') %>%
  select(dtxsid, inchikey, inchiString, smiles) %>%
  mutate(
    molFormula =
      str_remove_all(inchiString, pattern = "InChI=1S/") %>%
        str_remove_all(., pattern = '\\n|.\\d+H|.H|\\/i1\\+0')
  )

pt$elements <-
  left_join(
    pt$elements,
    element_list,
    join_by(Symbol == molFormula)
  ) %>%
  mutate(Number = as.character(Number))

rm(element_list)

# Nuclides and isotopes ---------------------------------------------------
nuc_page <- httr2::request("https://en.wikipedia.org/wiki/Table_of_nuclides") |>
  httr2::req_user_agent("ComptoxR data-raw script; https://github.com/seanthimons/ComptoxR") |>
  httr2::req_perform() |>
  httr2::resp_body_html()

nuc_cells <- nuc_page %>%
  rvest::html_nodes(".wikitable") %>%
  .[[3]] %>%
  rvest::html_nodes("td")

nuclides <- tibble(
  iso = rvest::html_text(nuc_cells) %>% str_trim(),
  title = rvest::html_attr(nuc_cells, "title")
) %>%
  filter(str_detect(iso, "\\d+[A-Z]")) %>%
  mutate(
    isotope_hl = case_when(
      str_detect(title, "Isotope:") ~
        str_extract(title, "Isotope: ([^;]+)", group = 1) %>% str_trim(),
      .default = str_extract(title, "Half-life: (.+)$", group = 1) %>% str_trim()
    ),
    isomer_hl = str_extract(title, "Nuclear isomer: (.+)$", group = 1) %>% str_trim()
  ) %>%
  filter(
    isotope_hl != "< 1 day" & isotope_hl != "<1 day" |
      (!is.na(isomer_hl) & isomer_hl != "< 1 day" & isomer_hl != "<1 day")
  ) %>%
  mutate(
    Z = str_extract(iso, "\\d+"),
    element = str_extract(iso, "[A-Z][a-z]?")
  ) %>%
  inner_join(
    pt$elements %>% select(Symbol:Name) %>% distinct(Symbol, .keep_all = TRUE),
    join_by(element == Symbol)
  ) %>%
  mutate(smiles = paste0("[", Z, element, "]")) %>%
  select(-iso, -title)

rm(nuc_page, nuc_cells)

DBI::dbWriteTable(dsstox_db, 'nucs', nuclides, temporary = TRUE, overwrite = TRUE)

dss_nuc <- dplyr::tbl(dsstox_db, 'nucs')

nuc_good <- dplyr::left_join(
  dss_nuc,
  dplyr::tbl(dsstox_db, 'dsstox') %>%
    dplyr::filter(
      !stringr::str_detect(parent_col, 'MOLECULAR_FORMULA')
    ),
  join_by(smiles == values)
) %>%
  dplyr::select(-parent_col, -sort_order) %>%
  dplyr::arrange(Z) %>%
  dplyr::collect()

# PubChem backfill for unresolved isotopes --------------------------------
nuc_missing <- nuc_good %>% filter(is.na(DTXSID))

if (nrow(nuc_missing) > 0) {
  pubchem_name_fix <- c(
    "Caesium"   = "Cesium",
    "Aluminium" = "Aluminum",
    "Sulphur"   = "Sulfur"
  )

  nuc_missing <- nuc_missing %>%
    mutate(
      pc_name    = str_replace_all(Name, pubchem_name_fix),
      search_name = paste0(pc_name, "-", Z)
    )

  # Step 1: PubChem name search
  n_total <- nrow(nuc_missing)
  pc_name_cids <- purrr::imap(
    nuc_missing$search_name,
    function(name, i) {
      cli::cli_alert_info("[{i}/{n_total}] Name search: {.val {name}}")
      purrr::possibly(
        ~ pubchem_search(.x, type = "name", cache = TRUE),
        tibble::tibble(cid = integer(0))
      )(name)
    }
  ) %>%
    set_names(nuc_missing$smiles) %>%
    bind_rows(.id = "smiles") %>%
    slice_min(cid, by = smiles, n = 1)

  # Step 2: SMILES fallback for name misses
  name_hit_smiles  <- pc_name_cids$smiles
  smiles_to_search <- nuc_missing %>%
    filter(smiles %ni% name_hit_smiles) %>%
    pull(smiles)

  if (length(smiles_to_search) > 0) {
    n_smiles <- length(smiles_to_search)
    pc_smiles_cids <- purrr::imap(
      smiles_to_search,
      function(smi, i) {
        cli::cli_alert_info("[{i}/{n_smiles}] SMILES search: {.val {smi}}")
        purrr::possibly(
          ~ pubchem_search(.x, type = "smiles", cache = TRUE),
          tibble::tibble(cid = integer(0))
        )(smi)
      }
    ) %>%
      set_names(smiles_to_search) %>%
      bind_rows(.id = "smiles") %>%
      slice_min(cid, by = smiles, n = 1)

    pc_cids <- bind_rows(pc_name_cids, pc_smiles_cids)
  } else {
    pc_cids <- pc_name_cids
  }

  if (nrow(pc_cids) > 0) {
    pc_cids <- pc_cids %>%
      left_join(
        nuc_missing %>% select(smiles, Name, Z) %>% distinct(smiles, .keep_all = TRUE),
        by = "smiles"
      )

    # Step 3: CID -> DTXSID via synonyms
    cli::cli_alert_info("Fetching PubChem synonyms for {nrow(pc_cids)} CIDs")
    pc_syns <- pubchem_synonyms(pc_cids$cid, tidy = TRUE, cache = TRUE)

    dtxsid_candidates <- pc_syns %>%
      filter(str_detect(synonym, "^DTXSID\\d+$")) %>%
      rename(DTXSID = synonym)

    single_hits <- dtxsid_candidates %>%
      add_count(cid) %>%
      filter(n == 1) %>%
      select(cid, DTXSID)

    multi_hits <- dtxsid_candidates %>%
      add_count(cid) %>%
      filter(n > 1) %>%
      select(cid, DTXSID)

    if (nrow(multi_hits) > 0) {
      candidate_dtxsids <- unique(multi_hits$DTXSID)
      dss_check <- dplyr::tbl(dsstox_db, 'dsstox') %>%
        dplyr::filter(DTXSID %in% candidate_dtxsids) %>%
        dplyr::collect()

      resolved_multi <- multi_hits %>%
        inner_join(pc_cids %>% select(cid, smiles), by = "cid") %>%
        inner_join(
          dss_check %>% select(DTXSID, values),
          by = "DTXSID",
          relationship = "many-to-many"
        ) %>%
        filter(smiles == values) %>%
        distinct(cid, .keep_all = TRUE) %>%
        select(cid, DTXSID)

      # Secondary: match preferred name
      still_unresolved <- multi_hits %>%
        filter(cid %ni% resolved_multi$cid)

      if (nrow(still_unresolved) > 0) {
        pref_names <- dss_check %>%
          filter(parent_col == "PREFERRED_NAME") %>%
          select(DTXSID, preferred_name = values)

        resolved_by_name <- still_unresolved %>%
          inner_join(pc_cids %>% select(cid, smiles, Name, Z), by = "cid") %>%
          inner_join(pref_names, by = "DTXSID") %>%
          filter(
            str_detect(preferred_name, regex(Name, ignore_case = TRUE)) |
              str_detect(preferred_name, regex(paste0(Name, ".*", Z), ignore_case = TRUE))
          ) %>%
          distinct(cid, .keep_all = TRUE) %>%
          select(cid, DTXSID)

        resolved_multi <- bind_rows(resolved_multi, resolved_by_name)
      }

      # Tertiary: CASRN from synonyms
      still_unresolved2 <- multi_hits %>%
        filter(cid %ni% resolved_multi$cid)

      if (nrow(still_unresolved2) > 0) {
        cas_for_disambig <- pc_syns %>%
          filter(
            cid %in% still_unresolved2$cid,
            str_detect(synonym, "^\\d{1,7}-\\d{2}-\\d$")
          ) %>%
          distinct(cid, .keep_all = TRUE)

        if (nrow(cas_for_disambig) > 0) {
          dss_cas_check <- dss_check %>%
            filter(parent_col == "CASRN") %>%
            select(DTXSID, casrn = values)

          resolved_by_cas <- still_unresolved2 %>%
            inner_join(cas_for_disambig %>% select(cid, synonym), by = "cid") %>%
            inner_join(dss_cas_check, join_by(synonym == casrn)) %>%
            filter(DTXSID.x == DTXSID.y) %>%
            rename(DTXSID = DTXSID.x) %>%
            distinct(cid, .keep_all = TRUE) %>%
            select(cid, DTXSID)

          resolved_multi <- bind_rows(resolved_multi, resolved_by_cas)
        }
      }

      # Last resort: take first candidate
      still_ambiguous <- multi_hits %>%
        filter(cid %ni% resolved_multi$cid) %>%
        distinct(cid, .keep_all = TRUE)

      if (nrow(still_ambiguous) > 0) {
        cli::cli_warn("{nrow(still_ambiguous)} CID{?s} with multiple DTXSIDs could not be disambiguated; using first")
      }

      resolved_multi <- bind_rows(resolved_multi, still_ambiguous)
    } else {
      resolved_multi <- tibble::tibble(cid = integer(0), DTXSID = character(0))
    }

    dtxsid_resolved <- bind_rows(single_hits, resolved_multi)
    pc_cids <- pc_cids %>%
      left_join(dtxsid_resolved, by = "cid")

    # Step 4a: CAS fallback from synonyms
    unresolved_cids_cas <- pc_cids %>% filter(is.na(DTXSID)) %>% pull(cid)
    if (length(unresolved_cids_cas) > 0) {
      cas_from_syns <- pc_syns %>%
        filter(
          cid %in% unresolved_cids_cas,
          str_detect(synonym, "^\\d{1,7}-\\d{2}-\\d$")
        ) %>%
        distinct(cid, .keep_all = TRUE)

      if (nrow(cas_from_syns) > 0) {
        cli::cli_alert_info("Searching dsstox for {nrow(cas_from_syns)} CASRNs from synonyms")
        dss_cas_hits <- dss_cas(cas_from_syns$synonym, con = dsstox_db)
        if (nrow(dss_cas_hits) > 0) {
          cas_match <- cas_from_syns %>%
            inner_join(
              dss_cas_hits %>% select(query, DTXSID) %>% distinct(query, .keep_all = TRUE),
              join_by(synonym == query)
            )
          for (idx in seq_len(nrow(cas_match))) {
            cid_row <- which(pc_cids$cid == cas_match$cid[idx])
            if (length(cid_row) > 0 && is.na(pc_cids$DTXSID[cid_row[1]])) {
              pc_cids$DTXSID[cid_row[1]] <- cas_match$DTXSID[idx]
            }
          }
        }
      }
    }

    # Step 4b: Property fallback
    unresolved_cids <- pc_cids %>% filter(is.na(DTXSID)) %>% pull(cid)

    if (length(unresolved_cids) > 0) {
      cli::cli_alert_info("Fetching PubChem properties for {length(unresolved_cids)} unresolved CIDs")
      pc_props <- purrr::possibly(
        ~ pubchem_properties(.x, properties = c("MolecularFormula", "CanonicalSMILES", "InChIKey"), cache = TRUE),
        tibble::tibble()
      )(unresolved_cids)

      if (nrow(pc_props) > 0) {
        prop_cols <- intersect(
          c("MolecularFormula", "CanonicalSMILES", "InChIKey"),
          names(pc_props)
        )

        if (length(prop_cols) > 0) {
          search_values <- pc_props %>%
            select(all_of(prop_cols)) %>%
            unlist(use.names = FALSE) %>%
            na.omit() %>%
            unique()
        } else {
          search_values <- character(0)
        }

        if (length(search_values) > 0) {
          dss_prop_hits <- dss_query(search_values, con = dsstox_db) %>%
            select(DTXSID, values) %>%
            distinct(values, .keep_all = TRUE)

          if (nrow(dss_prop_hits) > 0) {
            prop_match <- pc_props %>%
              tidyr::pivot_longer(
                cols = all_of(prop_cols),
                values_to = "prop_value",
                values_drop_na = TRUE
              ) %>%
              inner_join(dss_prop_hits, join_by(prop_value == values)) %>%
              distinct(CID, .keep_all = TRUE)

            for (idx in seq_len(nrow(prop_match))) {
              cid_row <- which(pc_cids$cid == prop_match$CID[idx])
              if (length(cid_row) > 0 && is.na(pc_cids$DTXSID[cid_row[1]])) {
                pc_cids$DTXSID[cid_row[1]] <- prop_match$DTXSID[idx]
              }
            }
          }
        }
      }
    }

    # Step 5: Patch resolved DTXSIDs back into nuc_good
    new_hits <- pc_cids %>% filter(!is.na(DTXSID))
    if (nrow(new_hits) > 0) {
      nuc_good <- nuc_good %>%
        left_join(
          new_hits %>% select(smiles, DTXSID_pc = DTXSID),
          by = "smiles"
        ) %>%
        mutate(DTXSID = coalesce(DTXSID, DTXSID_pc)) %>%
        select(-DTXSID_pc)
    }
  }
  rm(nuc_missing, pc_cids)
}

# Sanity checks -----------------------------------------------------------
{
  baseline <- dplyr::left_join(
    dss_nuc,
    dplyr::tbl(dsstox_db, 'dsstox') %>%
      dplyr::filter(!stringr::str_detect(parent_col, 'MOLECULAR_FORMULA')),
    join_by(smiles == values)
  ) %>%
    dplyr::select(-parent_col, -sort_order) %>%
    dplyr::arrange(Z) %>%
    dplyr::collect()

  cli::cli_h2("Sanity Check: Backfill Impact")
  cli::cli_alert_info("Baseline (dsstox only): {sum(!is.na(baseline$DTXSID))}/{nrow(baseline)} resolved")
  cli::cli_alert_info("After backfill: {sum(!is.na(nuc_good$DTXSID))}/{nrow(nuc_good)} resolved")
  cli::cli_alert_info("PubChem backfill added: {sum(!is.na(nuc_good$DTXSID)) - sum(!is.na(baseline$DTXSID))} DTXSIDs")

  dupes <- nuc_good %>% count(smiles, sort = TRUE) %>% filter(n > 1)
  if (nrow(dupes) > 0) {
    cli::cli_alert_warning("{nrow(dupes)} duplicate SMILES found")
    print(dupes, n = 20)
  } else {
    cli::cli_alert_success("No duplicate SMILES")
  }

  cli::cli_alert_info("nuclides input rows: {nrow(nuclides)}, nuc_good output rows: {nrow(nuc_good)}")
  if (nrow(nuc_good) != nrow(nuclides)) {
    cli::cli_alert_warning("Row count mismatch! {nrow(nuclides) - nrow(nuc_good)} rows lost/gained")
  }

  n_unique <- n_distinct(nuc_good$DTXSID)
  cli::cli_alert_info("Unique DTXSIDs: {n_unique} across {nrow(nuc_good)} isotopes")

  cli::cli_h3("Spot checks")
  cat("--- Iodine ---\n")
  nuc_good %>% filter(element == "I") %>% select(Z, element, Name, smiles, DTXSID) %>% print(n = 20)
  cat("--- Cesium ---\n")
  nuc_good %>% filter(element == "Cs") %>% select(Z, element, Name, smiles, DTXSID) %>% print(n = 20)
  cat("--- Strontium ---\n")
  nuc_good %>% filter(element == "Sr") %>% select(Z, element, Name, smiles, DTXSID) %>% print(n = 20)

  rm(baseline, dupes, n_unique)
}

pt$isotopes <- nuc_good

# Export ------------------------------------------------------------------
DBI::dbDisconnect(dsstox_db, shutdown = TRUE)
rm(dsstox_db, dsstox_path_val, dss_nuc, nuc_good, nuclides)

usethis::use_data(pt, overwrite = TRUE)
