#!/usr/bin/env Rscript
# ==============================================================================
# Synthetic Watershed Monitoring Dataset Generator
# ==============================================================================
# Generates realistic, sparse chemical occurrence data for testing a
# hierarchical ToxPi-style site prioritization framework.
#
# Outputs:
#   1. sites.csv          - Site metadata (distance from discharge, coordinates)
#   2. chemicals.csv      - Chemical portfolio with CAS, class, family, order
#   3. sampling_events.csv - Which methods were run at which sites on which dates
#   4. detections.csv     - Analytical results (concentrations + detect/ND)
#   5. bioassay.csv       - AhR bioassay results (continuous response per site-event)
#   6. method_coverage.csv - Which methods were available at each site
#
# Design decisions:
#   - Sparsity is STRUCTURAL, not random: method availability varies by site
#   - Detection probability decays with distance from discharge (with noise)
#   - PFAS and hydrocarbons cluster near discharge; metals are ubiquitous
#   - Temporal trends are baked in (some analytes increasing, some decreasing)
#   - Bioassay response correlates loosely with total chemical burden
# ==============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(purrr)
library(tibble)

set.seed(42)

# --- Configuration -----------------------------------------------------------

n_sites       <- 18
n_years       <- 12        # 2013-2024
events_per_yr <- 12        # monthly sampling
discharge_km  <- c(0, 0.5) # two discharge points (km from river origin)

# --- Chemical hierarchy -------------------------------------------------------
# Order > Family > Analyte Class (Domain) > Individual Analytes

# Build portfolio as a data.frame to avoid tribble limits
make_chem <- function(order, family, domain, analyte, cas, units, conc, det_class) {
  tibble(order=order, family=family, domain=domain, analyte=analyte,
         cas=cas, units=units, typical_conc_ug_l=conc, detection_class=det_class)
}

chemical_portfolio <- bind_rows(
  # --- VOCs ---
  make_chem("Organics","Volatiles","VOCs","Benzene","71-43-2","ug/L",2.5,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Toluene","108-88-3","ug/L",5.0,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Ethylbenzene","100-41-4","ug/L",1.2,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Xylenes (total)","1330-20-7","ug/L",3.8,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Chloroform","67-66-3","ug/L",4.1,"ubiquitous"),
  make_chem("Organics","Volatiles","VOCs","1,1-Dichloroethene","75-35-4","ug/L",0.8,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Trichloroethylene","79-01-6","ug/L",1.5,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Tetrachloroethylene","127-18-4","ug/L",0.9,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Methyl tert-butyl ether","1634-04-4","ug/L",3.2,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Vinyl chloride","75-01-4","ug/L",0.3,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","1,2-Dichloroethane","107-06-2","ug/L",0.6,"discharge_driven"),
  make_chem("Organics","Volatiles","VOCs","Carbon tetrachloride","56-23-5","ug/L",0.4,"rare_hit"),
  # --- SVOCs ---
  make_chem("Organics","Semivolatiles","SVOCs","Benzo(a)pyrene","50-32-8","ug/L",0.02,"discharge_driven"),
  make_chem("Organics","Semivolatiles","SVOCs","Naphthalene","91-20-3","ug/L",1.8,"discharge_driven"),
  make_chem("Organics","Semivolatiles","SVOCs","Fluoranthene","206-44-0","ug/L",0.15,"discharge_driven"),
  make_chem("Organics","Semivolatiles","SVOCs","Pyrene","129-00-0","ug/L",0.12,"discharge_driven"),
  make_chem("Organics","Semivolatiles","SVOCs","Phenanthrene","85-01-8","ug/L",0.25,"discharge_driven"),
  make_chem("Organics","Semivolatiles","SVOCs","Bis(2-ethylhexyl) phthalate","117-81-7","ug/L",1.5,"ubiquitous"),
  make_chem("Organics","Semivolatiles","SVOCs","Di-n-butyl phthalate","84-74-2","ug/L",0.8,"ubiquitous"),
  make_chem("Organics","Semivolatiles","SVOCs","Pentachlorophenol","87-86-5","ug/L",0.5,"discharge_driven"),
  make_chem("Organics","Semivolatiles","SVOCs","2,4-Dinitrotoluene","121-14-2","ug/L",0.3,"rare_hit"),
  # --- Hydrocarbons ---
  make_chem("Organics","Hydrocarbons","Hydrocarbons","TPH-DRO (C10-C28)","NA-DRO","ug/L",120,"discharge_driven"),
  make_chem("Organics","Hydrocarbons","Hydrocarbons","TPH-GRO (C6-C10)","NA-GRO","ug/L",85,"discharge_driven"),
  make_chem("Organics","Hydrocarbons","Hydrocarbons","TPH-ORO (C28-C36)","NA-ORO","ug/L",45,"discharge_driven"),
  make_chem("Organics","Hydrocarbons","Hydrocarbons","Oil & Grease","NA-OG","mg/L",5.0,"discharge_driven"),
  # --- PFAS ---
  make_chem("Organics","PFAS","PFAS","PFOS","1763-23-1","ng/L",18,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFOA","335-67-1","ng/L",12,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFHxS","355-46-4","ng/L",8.5,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFNA","375-95-1","ng/L",3.2,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFDA","335-76-2","ng/L",2.1,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFUnDA","2058-94-8","ng/L",1.5,"rare_hit"),
  make_chem("Organics","PFAS","PFAS","PFBS","375-73-5","ng/L",6.0,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFHxA","307-24-4","ng/L",9.0,"ubiquitous"),
  make_chem("Organics","PFAS","PFAS","PFHpA","375-85-9","ng/L",4.0,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFBA","375-22-4","ng/L",15,"ubiquitous"),
  make_chem("Organics","PFAS","PFAS","6:2 FTS","27619-97-2","ng/L",5.5,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","8:2 FTS","39108-34-4","ng/L",2.8,"rare_hit"),
  make_chem("Organics","PFAS","PFAS","ADONA","919005-14-4","ng/L",1.0,"rare_hit"),
  make_chem("Organics","PFAS","PFAS","GenX (HFPO-DA)","13252-13-6","ng/L",7.0,"discharge_driven"),
  make_chem("Organics","PFAS","PFAS","PFMBA","863090-89-5","ng/L",0.8,"rare_hit"),
  make_chem("Organics","PFAS","PFAS","PFMPA","377-73-1","ng/L",0.5,"rare_hit"),
  make_chem("Organics","PFAS","PFAS","NEtFOSAA","2991-50-6","ng/L",1.2,"rare_hit"),
  make_chem("Organics","PFAS","PFAS","NMeFOSAA","2355-31-9","ng/L",1.0,"rare_hit"),
  # --- Metals ---
  make_chem("Inorganics","Metals","Metals","Arsenic","7440-38-2","ug/L",5.0,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Cadmium","7440-43-9","ug/L",0.5,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Chromium","7440-47-3","ug/L",3.0,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Copper","7440-50-8","ug/L",8.0,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Lead","7439-92-1","ug/L",2.5,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Mercury","7439-97-6","ug/L",0.1,"discharge_driven"),
  make_chem("Inorganics","Metals","Metals","Nickel","7440-02-0","ug/L",6.0,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Selenium","7782-49-2","ug/L",2.0,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Zinc","7440-66-6","ug/L",25.0,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Thallium","7440-28-0","ug/L",0.3,"rare_hit"),
  make_chem("Inorganics","Metals","Metals","Antimony","7440-36-0","ug/L",1.5,"discharge_driven"),
  make_chem("Inorganics","Metals","Metals","Barium","7440-39-3","ug/L",50.0,"ubiquitous"),
  make_chem("Inorganics","Metals","Metals","Beryllium","7440-41-7","ug/L",0.2,"rare_hit"),
  make_chem("Inorganics","Metals","Metals","Silver","7440-22-4","ug/L",0.3,"rare_hit"),
  make_chem("Inorganics","Metals","Metals","Vanadium","7440-62-2","ug/L",4.0,"ubiquitous"),
  # --- Radionuclides ---
  make_chem("Radionuclides","Radionuclides","Radionuclides","Gross Alpha","NA-GALPHA","pCi/L",8.0,"ubiquitous"),
  make_chem("Radionuclides","Radionuclides","Radionuclides","Gross Beta","NA-GBETA","pCi/L",12.0,"ubiquitous"),
  make_chem("Radionuclides","Radionuclides","Radionuclides","Radium-226","13982-63-3","pCi/L",2.0,"ubiquitous"),
  make_chem("Radionuclides","Radionuclides","Radionuclides","Radium-228","15262-20-1","pCi/L",1.5,"ubiquitous"),
  make_chem("Radionuclides","Radionuclides","Radionuclides","Uranium","7440-61-1","ug/L",3.0,"ubiquitous"),
  make_chem("Radionuclides","Radionuclides","Radionuclides","Strontium-90","10098-97-2","pCi/L",0.5,"rare_hit"),
  make_chem("Radionuclides","Radionuclides","Radionuclides","Tritium","10028-17-8","pCi/L",500,"discharge_driven"),
  # --- WQ Parameters ---
  make_chem("WQ_Parameters","Conventional","WQ_Metrics","pH","NA-PH","SU",7.2,"ubiquitous"),
  make_chem("WQ_Parameters","Conventional","WQ_Metrics","Dissolved Oxygen","NA-DO","mg/L",7.5,"ubiquitous"),
  make_chem("WQ_Parameters","Conventional","WQ_Metrics","Specific Conductance","NA-SPCOND","uS/cm",450,"ubiquitous"),
  make_chem("WQ_Parameters","Conventional","WQ_Metrics","Turbidity","NA-TURB","NTU",15.0,"ubiquitous"),
  make_chem("WQ_Parameters","Conventional","WQ_Metrics","Temperature","NA-TEMP","degC",18.0,"ubiquitous"),
  make_chem("WQ_Parameters","Conventional","WQ_Metrics","Total Dissolved Solids","NA-TDS","mg/L",300,"ubiquitous"),
  make_chem("WQ_Parameters","Nutrients","WQ_Metrics","Nitrate as N","14797-55-8","mg/L",2.5,"ubiquitous"),
  make_chem("WQ_Parameters","Nutrients","WQ_Metrics","Total Phosphorus","NA-TP","mg/L",0.15,"ubiquitous"),
  make_chem("WQ_Parameters","Nutrients","WQ_Metrics","Ammonia as N","7664-41-7","mg/L",0.5,"discharge_driven")
) %>%
  mutate(analyte_id = row_number())

cat("Chemical portfolio:", nrow(chemical_portfolio), "analytes across",
    n_distinct(chemical_portfolio$domain), "domains\n")

# --- Sites along the watershed ------------------------------------------------

# Simulate a river running 0-32 km with discharge points at km 2 and km 5
sites <- tibble(
  site_id = paste0("SITE-", str_pad(1:n_sites, 2, pad = "0")),
  river_km = sort(c(0.5, 1.0, 2.0, 2.5, 3.0, 4.0, 5.0, 5.5, 6.5, 8.0,
                     10.0, 12.0, 15.0, 18.0, 22.0, 25.0, 28.0, 32.0)),
  # Two discharge points
  dist_discharge_1_km = abs(river_km - 2.0),
  dist_discharge_2_km = abs(river_km - 5.0),
  dist_nearest_discharge_km = pmin(dist_discharge_1_km, dist_discharge_2_km),
  # Approximate lat/lon for a hypothetical Ohio River tributary
  lat = 39.1 + river_km * 0.002 + rnorm(n_sites, 0, 0.001),
  lon = -84.5 - river_km * 0.003 + rnorm(n_sites, 0, 0.001),
  site_type = case_when(
    river_km %in% c(2.0, 5.0) ~ "discharge_point",
    dist_nearest_discharge_km <= 1.5 ~ "near_field",
    dist_nearest_discharge_km <= 5.0 ~ "mid_field",
    TRUE ~ "far_field"
  )
)

cat("Sites generated:", nrow(sites), "\n")
cat("  Discharge points:", sum(sites$site_type == "discharge_point"), "\n")
cat("  Near field:", sum(sites$site_type == "near_field"), "\n")
cat("  Mid field:", sum(sites$site_type == "mid_field"), "\n")
cat("  Far field:", sum(sites$site_type == "far_field"), "\n")

# --- Method coverage by site --------------------------------------------------
# Not every method is run at every site. This is the STRUCTURAL sparsity.

method_domains <- tibble(
  domain = c("VOCs", "SVOCs", "Hydrocarbons", "PFAS", "Metals",
             "Radionuclides", "WQ_Metrics"),
  method_name = c("SW-846 8260", "SW-846 8270", "SW-846 8015/418.1",
                   "EPA 533/537.1", "SW-846 6020", "EPA 900.0/903.0",
                   "Field/SM Methods")
)

# Base coverage probabilities by site type and domain
coverage_probs <- expand_grid(
  site_type = c("discharge_point", "near_field", "mid_field", "far_field"),
  domain = method_domains$domain
) %>%
  mutate(
    prob = case_when(
      # Everyone gets WQ and metals
      domain == "WQ_Metrics"    ~ 0.98,
      domain == "Metals"        ~ 0.95,
      # Radionuclides fairly standard
      domain == "Radionuclides" ~ 0.80,
      # PFAS targeted near discharge, less common far away
      domain == "PFAS" & site_type == "discharge_point" ~ 0.95,
      domain == "PFAS" & site_type == "near_field"      ~ 0.85,
      domain == "PFAS" & site_type == "mid_field"        ~ 0.50,
      domain == "PFAS" & site_type == "far_field"        ~ 0.25,
      # VOCs/SVOCs heavy near discharge
      domain %in% c("VOCs", "SVOCs") & site_type == "discharge_point" ~ 0.95,
      domain %in% c("VOCs", "SVOCs") & site_type == "near_field"      ~ 0.85,
      domain %in% c("VOCs", "SVOCs") & site_type == "mid_field"        ~ 0.60,
      domain %in% c("VOCs", "SVOCs") & site_type == "far_field"        ~ 0.30,
      # Hydrocarbons near discharge
      domain == "Hydrocarbons" & site_type == "discharge_point" ~ 0.90,
      domain == "Hydrocarbons" & site_type == "near_field"      ~ 0.75,
      domain == "Hydrocarbons" & site_type == "mid_field"        ~ 0.40,
      domain == "Hydrocarbons" & site_type == "far_field"        ~ 0.15,
      TRUE ~ 0.50
    )
  )

# Generate method coverage: for each site x year, decide which methods are run
# Methods can come and go over the monitoring period (program evolution)
sampling_dates <- tibble(
  year = rep(2013:2024, each = 12),
  month = rep(1:12, times = n_years)
) %>%
  mutate(
    sample_date = as.Date(paste(year, month, 15, sep = "-")),
    event_id = row_number()
  )

# For each site, determine which methods are available in which years
# (some methods added later, e.g., PFAS methods post-2018)
method_coverage <- expand_grid(
  site_id = sites$site_id,
  year = 2013:2024,
  domain = method_domains$domain
) %>%
  left_join(sites %>% select(site_id, site_type), by = "site_id") %>%
  left_join(coverage_probs, by = c("site_type", "domain")) %>%
  mutate(
    # PFAS methods weren't widely deployed until ~2018
    prob = if_else(domain == "PFAS" & year < 2018, prob * 0.1, prob),
    # Hydrocarbons added at more sites over time
    prob = if_else(domain == "Hydrocarbons" & year < 2016, prob * 0.5, prob),
    # Random draw
    method_available = rbinom(n(), 1, prob)
  ) %>%
  select(site_id, year, domain, method_available, site_type)

cat("\nMethod coverage summary (fraction of site-years with method):\n")
method_coverage %>%
  group_by(domain) %>%
  summarise(pct_available = mean(method_available), .groups = "drop") %>%
  print()

# --- Generate detection data --------------------------------------------------

# For each site x event x analyte (where the method was run), determine
# detection and concentration

generate_detections <- function(sites, sampling_dates, chemical_portfolio,
                                 method_coverage) {

  # Expand to all possible site x event x analyte combinations
  base_grid <- expand_grid(
    site_id = sites$site_id,
    event_id = sampling_dates$event_id
  ) %>%
    left_join(sampling_dates, by = "event_id") %>%
    left_join(sites, by = "site_id")

  # Cross with chemicals, but only where method was run
  detections <- base_grid %>%
    cross_join(chemical_portfolio) %>%
    # Join method coverage (by site, year, domain)
    left_join(
      method_coverage %>% select(site_id, year, domain, method_available),
      by = c("site_id", "year", "domain")
    ) %>%
    # Keep only where method was available
    filter(method_available == 1) %>%
    # Calculate detection probability based on distance and class
    mutate(
      # Spatial decay: detection probability drops with distance from discharge
      spatial_factor = case_when(
        detection_class == "discharge_driven" ~
          exp(-0.15 * dist_nearest_discharge_km),
        detection_class == "ubiquitous" ~
          pmax(0.3, 1 - 0.02 * dist_nearest_discharge_km),
        detection_class == "rare_hit" ~
          exp(-0.25 * dist_nearest_discharge_km) * 0.15,
        TRUE ~ 0.5
      ),
      # Temporal trend: some analytes increasing over time
      year_centered = (year - 2018),
      temporal_factor = case_when(
        # PFAS generally increasing until regulations catch up
        domain == "PFAS" & year <= 2020 ~ 1 + 0.05 * year_centered,
        domain == "PFAS" & year > 2020  ~ 1.1 - 0.03 * (year - 2020),
        # VOCs decreasing (remediation working)
        domain == "VOCs" ~ 1 - 0.02 * year_centered,
        # Metals stable
        domain == "Metals" ~ 1 + rnorm(n(), 0, 0.02),
        TRUE ~ 1
      ),
      temporal_factor = pmax(0.1, temporal_factor),
      # Seasonal component (some analytes higher in summer)
      seasonal_factor = case_when(
        domain %in% c("VOCs", "SVOCs") ~
          1 + 0.2 * sin(2 * pi * (month - 3) / 12),
        domain == "WQ_Metrics" & analyte == "Temperature" ~
          1 + 0.4 * sin(2 * pi * (month - 3) / 12),
        domain == "WQ_Metrics" & analyte == "Dissolved Oxygen" ~
          1 - 0.15 * sin(2 * pi * (month - 3) / 12),
        TRUE ~ 1 + rnorm(n(), 0, 0.05)
      ),
      # Combined detection probability
      detect_prob = pmin(0.95, spatial_factor * temporal_factor * 0.7),
      # WQ parameters always "detected" (they're measurements, not analytes)
      detect_prob = if_else(domain == "WQ_Metrics", 1.0, detect_prob),
      # Draw detection
      detected = rbinom(n(), 1, detect_prob),
      # Generate concentration (lognormal, conditional on detection)
      log_conc_mean = log(typical_conc_ug_l) +
        log(spatial_factor) +
        log(temporal_factor) +
        log(pmax(0.5, seasonal_factor)),
      log_conc_sd = 0.5,  # about 1.6x CV
      concentration = if_else(
        detected == 1,
        exp(rnorm(n(), log_conc_mean, log_conc_sd)),
        NA_real_
      ),
      # Reporting limit (varies by method, roughly 1/10 of typical conc)
      reporting_limit = typical_conc_ug_l * runif(n(), 0.05, 0.2),
      # For NDs, report < RL
      result_qualifier = if_else(detected == 1, "", "U"),
      # Final reported result
      reported_result = if_else(detected == 1, concentration, reporting_limit)
    ) %>%
    select(
      site_id, event_id, sample_date, year, month,
      analyte_id, analyte, cas, domain, family, order,
      units, detected, concentration, reporting_limit,
      result_qualifier, reported_result,
      dist_nearest_discharge_km, site_type
    )

  return(detections)
}

cat("\nGenerating detections (this may take a moment)...\n")
detections <- generate_detections(sites, sampling_dates, chemical_portfolio,
                                   method_coverage)

cat("Total records:", nrow(detections), "\n")
cat("Detections:", sum(detections$detected, na.rm = TRUE), "\n")
cat("Non-detects:", sum(detections$detected == 0, na.rm = TRUE), "\n")
cat("Detection rate:", round(mean(detections$detected, na.rm = TRUE), 3), "\n")

# --- Generate bioassay data ---------------------------------------------------
# AhR (Aryl Hydrocarbon Receptor) response assay
# Continuous response (fold-induction over control), collected per site per event
# Response correlates loosely with total organic chemical burden

bioassay <- detections %>%
  filter(domain %in% c("VOCs", "SVOCs", "Hydrocarbons", "PFAS")) %>%
  group_by(site_id, event_id, sample_date, year, month,
           dist_nearest_discharge_km, site_type) %>%
  summarise(
    n_organic_detects = sum(detected, na.rm = TRUE),
    total_organic_conc = sum(concentration, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    # AhR fold-induction: baseline ~1.0, increases with chemical burden
    # Log-transform the concentration to get a reasonable driver
    log_burden = log1p(total_organic_conc),
    # Correlated but noisy (R^2 ~ 0.4-0.6 with total burden)
    ahr_fold_induction = pmax(
      0.8,
      1.0 + 0.3 * log_burden + rnorm(n(), 0, 0.8)
    ),
    # Add some site-specific random effects (different matrices at each site)
    site_random = rnorm(n(), 0, 0.3)[match(site_id, unique(site_id))],
    ahr_fold_induction = ahr_fold_induction + site_random,
    ahr_fold_induction = pmax(0.5, ahr_fold_induction),
    # Flag significant responses (> 1.5 fold is biologically meaningful)
    ahr_significant = ahr_fold_induction > 1.5,
    # Add a quality flag
    ahr_qc_flag = sample(c("Pass", "Pass", "Pass", "Flag-matrix"),
                          n(), replace = TRUE)
  ) %>%
  select(
    site_id, event_id, sample_date, year, month,
    dist_nearest_discharge_km, site_type,
    n_organic_detects, total_organic_conc,
    ahr_fold_induction, ahr_significant, ahr_qc_flag
  )

cat("\nBioassay summary:\n")
cat("  Events with AhR data:", nrow(bioassay), "\n")
cat("  Significant responses:", sum(bioassay$ahr_significant), 
    "(", round(mean(bioassay$ahr_significant) * 100, 1), "%)\n")

# --- Write outputs ------------------------------------------------------------

output_dir <- "/home/claude/synthetic_watershed_data"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

write_csv(sites, file.path(output_dir, "sites.csv"))
write_csv(
  chemical_portfolio %>% select(-detection_class),
  file.path(output_dir, "chemicals.csv")
)
write_csv(sampling_dates, file.path(output_dir, "sampling_events.csv"))
write_csv(detections, file.path(output_dir, "detections.csv"))
write_csv(bioassay, file.path(output_dir, "bioassay.csv"))
write_csv(method_coverage, file.path(output_dir, "method_coverage.csv"))

# --- Summary stats for sanity checking ----------------------------------------

cat("\n========================================\n")
cat("Dataset Summary\n")
cat("========================================\n")
cat("Sites:", nrow(sites), "\n")
cat("Analytes:", nrow(chemical_portfolio), "\n")
cat("Sampling events:", nrow(sampling_dates), "months x", nrow(sites), "sites\n")
cat("Total analytical records:", nrow(detections), "\n")
cat("Bioassay records:", nrow(bioassay), "\n\n")

cat("Detection rates by domain:\n")
detections %>%
  group_by(domain) %>%
  summarise(
    n_records = n(),
    n_detected = sum(detected),
    detect_rate = round(mean(detected), 3),
    .groups = "drop"
  ) %>%
  arrange(desc(detect_rate)) %>%
  print(n = Inf)

cat("\nDetection rates by site type:\n")
detections %>%
  filter(domain != "WQ_Metrics") %>%
  group_by(site_type) %>%
  summarise(
    n_records = n(),
    detect_rate = round(mean(detected), 3),
    .groups = "drop"
  ) %>%
  print()

cat("\nMethod coverage over time (fraction of sites with method):\n")
method_coverage %>%
  group_by(year, domain) %>%
  summarise(coverage = round(mean(method_available), 2), .groups = "drop") %>%
  pivot_wider(names_from = domain, values_from = coverage) %>%
  print(n = Inf)

cat("\nFiles written to:", output_dir, "\n")
cat("  - sites.csv\n")
cat("  - chemicals.csv\n")
cat("  - sampling_events.csv\n")
cat("  - detections.csv\n")
cat("  - bioassay.csv\n")
cat("  - method_coverage.csv\n")
