#' Estimate one chemical
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES; required when cas is absent.
#' @param cas CAS Registry Number; required when smiles is absent.
#' @param modules Comma-separated canonical public module names; defaults to all. Array order does not control scientific precedence: selected modules run in canonical dependency order, with waterSolubilityProvider controlling the shared WSKOW/WaterNT choice. Exact implementation IDs are accepted for CLI parity but public names are the durable HTTP contract.
#' @param chemicalName Optional parameter
#' @param logKow Optional parameter
#' @param molecularWeight Optional resolved molecular weight in g/mol. Together with positive vapor pressure and water solubility, it enables the HENRYWIN VP/WSOL candidate; Bond and Group require only SMILES.
#' @param waterSolubilityMgPerL Optional resolved water solubility in mg/L. A positive VP/WSOL/MW triplet enables the HENRYWIN VP/WSOL candidate; omission does not prevent Bond or Group estimation.
#' @param waterSolubility Optional parameter
#' @param waterSolubilityProvider Selects the source used for downstream resolved water solubility. Both WSKOW and WaterNT independent results remain visible when all modules run.. Options: wskow, waternt (default: wskow)
#' @param vaporPressureMmHg Optional resolved vapor pressure in mmHg. A positive VP/WSOL/MW triplet enables the HENRYWIN VP/WSOL candidate; omission does not prevent Bond or Group estimation.
#' @param subcooledVaporPressureMmHg Optional parameter
#' @param henryAtmM3PerMol Optional parameter
#' @param logKoa Optional parameter
#' @param koc Optional parameter
#' @param meltingPointC Optional parameter
#' @param boilingPointC Optional parameter
#' @param vaporPressureTemperatureC Compatibility field for the maintained fixed-temperature MPBPVP calculation. Only 25 °C is accepted.. Options: 25 (default: 25)
#' @param aopRateConstant Optional parameter
#' @param biowinScore Optional parameter
#' @param biowin3 Optional parameter
#' @param biowin5 Optional parameter
#' @param removeMetals Whether BIOWIN removes selected metal and salt counterions; model default is true. (default: TRUE)
#' @param tspUgPerM3 Total suspended particulate matter in ug/m3; AEROWIN default is 80. (default: 80)
#' @param theta Combined Junge-Pankow cTheta in Pa (not particle surface-area Theta); AEROWIN default is 0.00010836 Pa. (default: 0.00010836)
#' @param waterConcentrationMgPerCm3 Optional parameter
#' @param waterConcentrationMgPerLiter Optional parameter
#' @param eventFrequencyPerDay Optional parameter
#' @param exposureDurationYears Optional parameter
#' @param exposureFrequencyDaysPerYear Optional parameter
#' @param skinSurfaceAreaCm2 Optional parameter
#' @param bodyWeightKg Optional parameter
#' @param averagingTimeDays Optional parameter
#' @param fractionAbsorbed Optional parameter
#' @param eventDurationHours Optional parameter
#' @param userKpCmPerHour Optional parameter
#' @param halfLifeHoursPrimaryClarifier Optional parameter
#' @param halfLifeHoursAerationVessel Optional parameter
#' @param halfLifeHoursSettlingTank Optional parameter
#' @param halfLifeAir Optional parameter
#' @param halfLifeWater Optional parameter
#' @param halfLifeSoil Optional parameter
#' @param halfLifeSediment Optional parameter
#' @param emissionRateAir Optional parameter
#' @param emissionRateWater Optional parameter
#' @param emissionRateSoil Optional parameter
#' @param emissionRateSediment Optional parameter
#' @param advectionTimeAir Optional parameter
#' @param advectionTimeWater Optional parameter
#' @param advectionTimeSoil Optional parameter
#' @param advectionTimeSediment Optional parameter
#' @param ohConcentrationE6OhPerCm3 Optional parameter
#' @param ozoneConcentrationE11MolPerCm3 Optional parameter
#' @param daylightHours Atmospheric daylight period in hours; AOPWIN default is 12.. Options: 12, 24 (default: 12)
#' @param riverWindMPerSec Optional parameter
#' @param riverCurrentMPerSec Optional parameter
#' @param riverDepthMeters Optional parameter
#' @param lakeWindMPerSec Optional parameter
#' @param lakeCurrentMPerSec Optional parameter
#' @param lakeDepthMeters Optional parameter
#' @param carbonChainLength Optional parameter
#' @param mainCarbons Optional parameter
#' @param branchedCarbons Optional parameter
#' @param branches Optional parameter
#' @param propoxyGroups Optional parameter
#' @param ethoxylate Optional parameter
#' @param amineNitrogens Optional parameter
#' @param cationAnionRatio Optional parameter
#' @param mw500Percentage Optional parameter
#' @param mw1000Percentage Optional parameter
#' @param averageMolecularWeight Optional parameter
#' @param useSmiles Optional parameter
#' @param solubilityType Optional parameter
#' @param polymerType Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_submit(smiles = "CCO")
#' }
epi_submit <- function(smiles = NULL, cas = NULL, modules = NULL, chemicalName = NULL, logKow = NULL, molecularWeight = NULL, waterSolubilityMgPerL = NULL, waterSolubility = NULL, waterSolubilityProvider = "wskow", vaporPressureMmHg = NULL, subcooledVaporPressureMmHg = NULL, henryAtmM3PerMol = NULL, logKoa = NULL, koc = NULL, meltingPointC = NULL, boilingPointC = NULL, vaporPressureTemperatureC = 25, aopRateConstant = NULL, biowinScore = NULL, biowin3 = NULL, biowin5 = NULL, removeMetals = TRUE, tspUgPerM3 = 80, theta = 0.00010836, waterConcentrationMgPerCm3 = NULL, waterConcentrationMgPerLiter = NULL, eventFrequencyPerDay = NULL, exposureDurationYears = NULL, exposureFrequencyDaysPerYear = NULL, skinSurfaceAreaCm2 = NULL, bodyWeightKg = NULL, averagingTimeDays = NULL, fractionAbsorbed = NULL, eventDurationHours = NULL, userKpCmPerHour = NULL, halfLifeHoursPrimaryClarifier = NULL, halfLifeHoursAerationVessel = NULL, halfLifeHoursSettlingTank = NULL, halfLifeAir = NULL, halfLifeWater = NULL, halfLifeSoil = NULL, halfLifeSediment = NULL, emissionRateAir = NULL, emissionRateWater = NULL, emissionRateSoil = NULL, emissionRateSediment = NULL, advectionTimeAir = NULL, advectionTimeWater = NULL, advectionTimeSoil = NULL, advectionTimeSediment = NULL, ohConcentrationE6OhPerCm3 = NULL, ozoneConcentrationE11MolPerCm3 = NULL, daylightHours = 12, riverWindMPerSec = NULL, riverCurrentMPerSec = NULL, riverDepthMeters = NULL, lakeWindMPerSec = NULL, lakeCurrentMPerSec = NULL, lakeDepthMeters = NULL, carbonChainLength = NULL, mainCarbons = NULL, branchedCarbons = NULL, branches = NULL, propoxyGroups = NULL, ethoxylate = NULL, amineNitrogens = NULL, cationAnionRatio = NULL, mw500Percentage = NULL, mw1000Percentage = NULL, averageMolecularWeight = NULL, useSmiles = NULL, solubilityType = NULL, polymerType = NULL) {
  result <- generic_request(
    endpoint = "submit",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    `smiles` = smiles,
    `cas` = cas,
    `modules` = modules,
    `chemicalName` = chemicalName,
    `logKow` = logKow,
    `molecularWeight` = molecularWeight,
    `waterSolubilityMgPerL` = waterSolubilityMgPerL,
    `waterSolubility` = waterSolubility,
    `waterSolubilityProvider` = waterSolubilityProvider,
    `vaporPressureMmHg` = vaporPressureMmHg,
    `subcooledVaporPressureMmHg` = subcooledVaporPressureMmHg,
    `henryAtmM3PerMol` = henryAtmM3PerMol,
    `logKoa` = logKoa,
    `koc` = koc,
    `meltingPointC` = meltingPointC,
    `boilingPointC` = boilingPointC,
    `vaporPressureTemperatureC` = vaporPressureTemperatureC,
    `aopRateConstant` = aopRateConstant,
    `biowinScore` = biowinScore,
    `biowin3` = biowin3,
    `biowin5` = biowin5,
    `removeMetals` = removeMetals,
    `tspUgPerM3` = tspUgPerM3,
    `theta` = theta,
    `waterConcentrationMgPerCm3` = waterConcentrationMgPerCm3,
    `waterConcentrationMgPerLiter` = waterConcentrationMgPerLiter,
    `eventFrequencyPerDay` = eventFrequencyPerDay,
    `exposureDurationYears` = exposureDurationYears,
    `exposureFrequencyDaysPerYear` = exposureFrequencyDaysPerYear,
    `skinSurfaceAreaCm2` = skinSurfaceAreaCm2,
    `bodyWeightKg` = bodyWeightKg,
    `averagingTimeDays` = averagingTimeDays,
    `fractionAbsorbed` = fractionAbsorbed,
    `eventDurationHours` = eventDurationHours,
    `userKpCmPerHour` = userKpCmPerHour,
    `halfLifeHoursPrimaryClarifier` = halfLifeHoursPrimaryClarifier,
    `halfLifeHoursAerationVessel` = halfLifeHoursAerationVessel,
    `halfLifeHoursSettlingTank` = halfLifeHoursSettlingTank,
    `halfLifeAir` = halfLifeAir,
    `halfLifeWater` = halfLifeWater,
    `halfLifeSoil` = halfLifeSoil,
    `halfLifeSediment` = halfLifeSediment,
    `emissionRateAir` = emissionRateAir,
    `emissionRateWater` = emissionRateWater,
    `emissionRateSoil` = emissionRateSoil,
    `emissionRateSediment` = emissionRateSediment,
    `advectionTimeAir` = advectionTimeAir,
    `advectionTimeWater` = advectionTimeWater,
    `advectionTimeSoil` = advectionTimeSoil,
    `advectionTimeSediment` = advectionTimeSediment,
    `ohConcentrationE6OhPerCm3` = ohConcentrationE6OhPerCm3,
    `ozoneConcentrationE11MolPerCm3` = ozoneConcentrationE11MolPerCm3,
    `daylightHours` = daylightHours,
    `riverWindMPerSec` = riverWindMPerSec,
    `riverCurrentMPerSec` = riverCurrentMPerSec,
    `riverDepthMeters` = riverDepthMeters,
    `lakeWindMPerSec` = lakeWindMPerSec,
    `lakeCurrentMPerSec` = lakeCurrentMPerSec,
    `lakeDepthMeters` = lakeDepthMeters,
    `carbonChainLength` = carbonChainLength,
    `mainCarbons` = mainCarbons,
    `branchedCarbons` = branchedCarbons,
    `branches` = branches,
    `propoxyGroups` = propoxyGroups,
    `ethoxylate` = ethoxylate,
    `amineNitrogens` = amineNitrogens,
    `cationAnionRatio` = cationAnionRatio,
    `mw500Percentage` = mw500Percentage,
    `mw1000Percentage` = mw1000Percentage,
    `averageMolecularWeight` = averageMolecularWeight,
    `useSmiles` = useSmiles,
    `solubilityType` = solubilityType,
    `polymerType` = polymerType
  )

    result <- run_hook("epi_submit", "post_response", list(result = result, params = list(`smiles` = smiles, `cas` = cas, `modules` = modules, `chemicalName` = chemicalName, `logKow` = logKow, `molecularWeight` = molecularWeight, `waterSolubilityMgPerL` = waterSolubilityMgPerL, `waterSolubility` = waterSolubility, `waterSolubilityProvider` = waterSolubilityProvider, `vaporPressureMmHg` = vaporPressureMmHg, `subcooledVaporPressureMmHg` = subcooledVaporPressureMmHg, `henryAtmM3PerMol` = henryAtmM3PerMol, `logKoa` = logKoa, `koc` = koc, `meltingPointC` = meltingPointC, `boilingPointC` = boilingPointC, `vaporPressureTemperatureC` = vaporPressureTemperatureC, `aopRateConstant` = aopRateConstant, `biowinScore` = biowinScore, `biowin3` = biowin3, `biowin5` = biowin5, `removeMetals` = removeMetals, `tspUgPerM3` = tspUgPerM3, `theta` = theta, `waterConcentrationMgPerCm3` = waterConcentrationMgPerCm3, `waterConcentrationMgPerLiter` = waterConcentrationMgPerLiter, `eventFrequencyPerDay` = eventFrequencyPerDay, `exposureDurationYears` = exposureDurationYears, `exposureFrequencyDaysPerYear` = exposureFrequencyDaysPerYear, `skinSurfaceAreaCm2` = skinSurfaceAreaCm2, `bodyWeightKg` = bodyWeightKg, `averagingTimeDays` = averagingTimeDays, `fractionAbsorbed` = fractionAbsorbed, `eventDurationHours` = eventDurationHours, `userKpCmPerHour` = userKpCmPerHour, `halfLifeHoursPrimaryClarifier` = halfLifeHoursPrimaryClarifier, `halfLifeHoursAerationVessel` = halfLifeHoursAerationVessel, `halfLifeHoursSettlingTank` = halfLifeHoursSettlingTank, `halfLifeAir` = halfLifeAir, `halfLifeWater` = halfLifeWater, `halfLifeSoil` = halfLifeSoil, `halfLifeSediment` = halfLifeSediment, `emissionRateAir` = emissionRateAir, `emissionRateWater` = emissionRateWater, `emissionRateSoil` = emissionRateSoil, `emissionRateSediment` = emissionRateSediment, `advectionTimeAir` = advectionTimeAir, `advectionTimeWater` = advectionTimeWater, `advectionTimeSoil` = advectionTimeSoil, `advectionTimeSediment` = advectionTimeSediment, `ohConcentrationE6OhPerCm3` = ohConcentrationE6OhPerCm3, `ozoneConcentrationE11MolPerCm3` = ozoneConcentrationE11MolPerCm3, `daylightHours` = daylightHours, `riverWindMPerSec` = riverWindMPerSec, `riverCurrentMPerSec` = riverCurrentMPerSec, `riverDepthMeters` = riverDepthMeters, `lakeWindMPerSec` = lakeWindMPerSec, `lakeCurrentMPerSec` = lakeCurrentMPerSec, `lakeDepthMeters` = lakeDepthMeters, `carbonChainLength` = carbonChainLength, `mainCarbons` = mainCarbons, `branchedCarbons` = branchedCarbons, `branches` = branches, `propoxyGroups` = propoxyGroups, `ethoxylate` = ethoxylate, `amineNitrogens` = amineNitrogens, `cationAnionRatio` = cationAnionRatio, `mw500Percentage` = mw500Percentage, `mw1000Percentage` = mw1000Percentage, `averageMolecularWeight` = averageMolecularWeight, `useSmiles` = useSmiles, `solubilityType` = solubilityType, `polymerType` = polymerType)))
# Additional post-processing can be added here

  return(result)
}


