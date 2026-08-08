#' Run EpiSuite calculations
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES notation of the chemical. Either smiles or cas is required.
#' @param cas CAS registry number. Either smiles or cas is required.
#' @param caseNumber Case identifier for tracking purposes
#' @param modules Comma-separated list of modules to run. If not specified, all modules are run. Valid values: logKow, mpbpvp, waterSolubilityFromLogKow, waterSolubilityFromWaterNt, henrysLawConstant, logKoa, logKoc, biodegradationRate, hydrocarbonBiodegradationRate, bioconcentration, aerosolAdsorptionFraction, atmosphericHalfLife, hydrolysis, waterVolatilization, sewageTreatmentModel, fugacityModel, dermalPermeability, ecosar, aimanalogs
#' @param userLogKow User-provided octanol-water partition coefficient (log Kow) override
#' @param userMeltingPoint User-provided melting point override (Celsius)
#' @param userBoilingPoint User-provided boiling point override (Celsius)
#' @param userVaporPressure User-provided vapor pressure override (mmHg)
#' @param userWaterSolubility User-provided water solubility override (mg/L)
#' @param userHenrysLawConstant User-provided Henry's Law constant override (atm-m3/mol)
#' @param userLogKoa User-provided octanol-air partition coefficient (log Koa) override
#' @param userLogKoc User-provided soil adsorption coefficient (log Koc) override (L/kg)
#' @param userHydroxylReactionRateConstant User-provided hydroxyl reaction rate constant (cm3/molecule-sec)
#' @param userAtmosphericHydroxylRadicalConcentration User-provided atmospheric hydroxyl radical concentration (radicals/cm3). Default: 1.5e6 (default: 1500000)
#' @param userAtmosphericOzoneConcentration User-provided atmospheric ozone concentration (molecules/cm3). Default: 7e11 (default: 7e+11)
#' @param userAtmosphericDaylightHours User-provided average daylight hours for atmospheric calculations. Default: 12 (default: 12)
#' @param userDermalPermeabilityCoefficient User-provided dermal permeability coefficient override (cm/hr)
#' @param userBiodegradationRateRemoveMetals Whether to remove metals from biodegradation rate calculation. Default: true (default: TRUE)
#' @param userStpHalfLifePrimaryClarifier User-provided STP primary clarifier half-life (hours). Default: 10000 (default: 10000)
#' @param userStpHalfLifeAerationVessel User-provided STP aeration vessel half-life (hours). Default: 10000 (default: 10000)
#' @param userStpHalfLifeSettlingTank User-provided STP settling tank half-life (hours). Default: 10000 (default: 10000)
#' @param userFugacityHalfLifeAir User-provided fugacity model air half-life (hours). Default: 0 (calculated from atmospheric half-life) (default: 0)
#' @param userFugacityHalfLifeWater User-provided fugacity model water half-life (hours). Default: 0 (calculated from biodegradation) (default: 0)
#' @param userFugacityHalfLifeSoil User-provided fugacity model soil half-life (hours). Default: 0 (calculated from biodegradation) (default: 0)
#' @param userFugacityHalfLifeSediment User-provided fugacity model sediment half-life (hours). Default: 0 (calculated from biodegradation) (default: 0)
#' @param userFugacityEmissionRateAir User-provided fugacity model air emission rate (kg/hour). Default: 1000 (default: 1000)
#' @param userFugacityEmissionRateWater User-provided fugacity model water emission rate (kg/hour). Default: 1000 (default: 1000)
#' @param userFugacityEmissionRateSoil User-provided fugacity model soil emission rate (kg/hour). Default: 1000 (default: 1000)
#' @param userFugacityEmissionRateSediment User-provided fugacity model sediment emission rate (kg/hour). Default: 0 (default: 0)
#' @param userFugacityAdvectionTimeAir User-provided fugacity model air advection residence time (hours). Default: 100 (default: 100)
#' @param userFugacityAdvectionTimeWater User-provided fugacity model water advection residence time (hours). Default: 1000 (default: 1000)
#' @param userFugacityAdvectionTimeSoil User-provided fugacity model soil advection residence time (hours). Default: 0 (default: 0)
#' @param userFugacityAdvectionTimeSediment User-provided fugacity model sediment advection residence time (hours). Default: 50000 (default: 50000)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_submit(smiles = "c1ccccc1")
#' }
epi_submit <- function(
  smiles = NULL,
  cas = NULL,
  caseNumber = NULL,
  modules = NULL,
  userLogKow = NULL,
  userMeltingPoint = NULL,
  userBoilingPoint = NULL,
  userVaporPressure = NULL,
  userWaterSolubility = NULL,
  userHenrysLawConstant = NULL,
  userLogKoa = NULL,
  userLogKoc = NULL,
  userHydroxylReactionRateConstant = NULL,
  userAtmosphericHydroxylRadicalConcentration = 1500000,
  userAtmosphericOzoneConcentration = 7e+11,
  userAtmosphericDaylightHours = 12,
  userDermalPermeabilityCoefficient = NULL,
  userBiodegradationRateRemoveMetals = TRUE,
  userStpHalfLifePrimaryClarifier = 10000,
  userStpHalfLifeAerationVessel = 10000,
  userStpHalfLifeSettlingTank = 10000,
  userFugacityHalfLifeAir = 0,
  userFugacityHalfLifeWater = 0,
  userFugacityHalfLifeSoil = 0,
  userFugacityHalfLifeSediment = 0,
  userFugacityEmissionRateAir = 1000,
  userFugacityEmissionRateWater = 1000,
  userFugacityEmissionRateSoil = 1000,
  userFugacityEmissionRateSediment = 0,
  userFugacityAdvectionTimeAir = 100,
  userFugacityAdvectionTimeWater = 1000,
  userFugacityAdvectionTimeSoil = 0,
  userFugacityAdvectionTimeSediment = 50000
) {
  result <- generic_request(
    endpoint = "submit",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    `smiles` = smiles,
    `cas` = cas,
    `caseNumber` = caseNumber,
    `modules` = modules,
    `userLogKow` = userLogKow,
    `userMeltingPoint` = userMeltingPoint,
    `userBoilingPoint` = userBoilingPoint,
    `userVaporPressure` = userVaporPressure,
    `userWaterSolubility` = userWaterSolubility,
    `userHenrysLawConstant` = userHenrysLawConstant,
    `userLogKoa` = userLogKoa,
    `userLogKoc` = userLogKoc,
    `userHydroxylReactionRateConstant` = userHydroxylReactionRateConstant,
    `userAtmosphericHydroxylRadicalConcentration` = userAtmosphericHydroxylRadicalConcentration,
    `userAtmosphericOzoneConcentration` = userAtmosphericOzoneConcentration,
    `userAtmosphericDaylightHours` = userAtmosphericDaylightHours,
    `userDermalPermeabilityCoefficient` = userDermalPermeabilityCoefficient,
    `userBiodegradationRateRemoveMetals` = userBiodegradationRateRemoveMetals,
    `userStpHalfLifePrimaryClarifier` = userStpHalfLifePrimaryClarifier,
    `userStpHalfLifeAerationVessel` = userStpHalfLifeAerationVessel,
    `userStpHalfLifeSettlingTank` = userStpHalfLifeSettlingTank,
    `userFugacityHalfLifeAir` = userFugacityHalfLifeAir,
    `userFugacityHalfLifeWater` = userFugacityHalfLifeWater,
    `userFugacityHalfLifeSoil` = userFugacityHalfLifeSoil,
    `userFugacityHalfLifeSediment` = userFugacityHalfLifeSediment,
    `userFugacityEmissionRateAir` = userFugacityEmissionRateAir,
    `userFugacityEmissionRateWater` = userFugacityEmissionRateWater,
    `userFugacityEmissionRateSoil` = userFugacityEmissionRateSoil,
    `userFugacityEmissionRateSediment` = userFugacityEmissionRateSediment,
    `userFugacityAdvectionTimeAir` = userFugacityAdvectionTimeAir,
    `userFugacityAdvectionTimeWater` = userFugacityAdvectionTimeWater,
    `userFugacityAdvectionTimeSoil` = userFugacityAdvectionTimeSoil,
    `userFugacityAdvectionTimeSediment` = userFugacityAdvectionTimeSediment
  )

  result <- run_hook(
    "epi_submit",
    "post_response",
    list(
      result = result,
      params = list(
        `smiles` = smiles,
        `cas` = cas,
        `caseNumber` = caseNumber,
        `modules` = modules,
        `userLogKow` = userLogKow,
        `userMeltingPoint` = userMeltingPoint,
        `userBoilingPoint` = userBoilingPoint,
        `userVaporPressure` = userVaporPressure,
        `userWaterSolubility` = userWaterSolubility,
        `userHenrysLawConstant` = userHenrysLawConstant,
        `userLogKoa` = userLogKoa,
        `userLogKoc` = userLogKoc,
        `userHydroxylReactionRateConstant` = userHydroxylReactionRateConstant,
        `userAtmosphericHydroxylRadicalConcentration` = userAtmosphericHydroxylRadicalConcentration,
        `userAtmosphericOzoneConcentration` = userAtmosphericOzoneConcentration,
        `userAtmosphericDaylightHours` = userAtmosphericDaylightHours,
        `userDermalPermeabilityCoefficient` = userDermalPermeabilityCoefficient,
        `userBiodegradationRateRemoveMetals` = userBiodegradationRateRemoveMetals,
        `userStpHalfLifePrimaryClarifier` = userStpHalfLifePrimaryClarifier,
        `userStpHalfLifeAerationVessel` = userStpHalfLifeAerationVessel,
        `userStpHalfLifeSettlingTank` = userStpHalfLifeSettlingTank,
        `userFugacityHalfLifeAir` = userFugacityHalfLifeAir,
        `userFugacityHalfLifeWater` = userFugacityHalfLifeWater,
        `userFugacityHalfLifeSoil` = userFugacityHalfLifeSoil,
        `userFugacityHalfLifeSediment` = userFugacityHalfLifeSediment,
        `userFugacityEmissionRateAir` = userFugacityEmissionRateAir,
        `userFugacityEmissionRateWater` = userFugacityEmissionRateWater,
        `userFugacityEmissionRateSoil` = userFugacityEmissionRateSoil,
        `userFugacityEmissionRateSediment` = userFugacityEmissionRateSediment,
        `userFugacityAdvectionTimeAir` = userFugacityAdvectionTimeAir,
        `userFugacityAdvectionTimeWater` = userFugacityAdvectionTimeWater,
        `userFugacityAdvectionTimeSoil` = userFugacityAdvectionTimeSoil,
        `userFugacityAdvectionTimeSediment` = userFugacityAdvectionTimeSediment
      )
    )
  )
  # Additional post-processing can be added here

  return(result)
}
