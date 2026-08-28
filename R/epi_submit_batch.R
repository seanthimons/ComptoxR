#' Estimate an ordered batch of chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param modules Selected calculations. Items run in canonical dependency order rather than submitted array order; use waterSolubilityProvider for the shared water-solubility choice.
#' @param advectionTimeAir Optional parameter
#' @param advectionTimeSediment Optional parameter
#' @param advectionTimeSoil Optional parameter
#' @param advectionTimeWater Optional parameter
#' @param amineNitrogens Optional parameter
#' @param aopRateConstant Optional parameter
#' @param averageMolecularWeight Optional parameter
#' @param averagingTimeDays Optional parameter
#' @param biowin3 Optional parameter
#' @param biowin5 Optional parameter
#' @param biowinScore Optional parameter
#' @param bodyWeightKg Optional parameter
#' @param boilingPointC Optional parameter
#' @param branchedCarbons Optional parameter
#' @param branches Optional parameter
#' @param carbonChainLength Optional parameter
#' @param cas CAS Registry Number. Only a CAS-identified batch item can resolve experimental results; CAS takes precedence when SMILES is also supplied.
#' @param cationAnionRatio Optional parameter
#' @param chemicalName Optional parameter
#' @param daylightHours Optional parameter
#' @param emissionRateAir Optional parameter
#' @param emissionRateSediment Optional parameter
#' @param emissionRateSoil Optional parameter
#' @param emissionRateWater Optional parameter
#' @param ethoxylate Optional parameter
#' @param eventDurationHours Optional parameter
#' @param eventFrequencyPerDay Optional parameter
#' @param exposureDurationYears Optional parameter
#' @param exposureFrequencyDaysPerYear Optional parameter
#' @param fractionAbsorbed Optional parameter
#' @param halfLifeAir Optional parameter
#' @param halfLifeHoursAerationVessel Optional parameter
#' @param halfLifeHoursPrimaryClarifier Optional parameter
#' @param halfLifeHoursSettlingTank Optional parameter
#' @param halfLifeSediment Optional parameter
#' @param halfLifeSoil Optional parameter
#' @param halfLifeWater Optional parameter
#' @param henryAtmM3PerMol Optional parameter
#' @param koc Optional parameter
#' @param lakeCurrentMPerSec Optional parameter
#' @param lakeDepthMeters Optional parameter
#' @param lakeWindMPerSec Optional parameter
#' @param logKoa Optional parameter
#' @param logKow Optional parameter
#' @param mainCarbons Optional parameter
#' @param meltingPointC Optional parameter
#' @param molecularWeight Optional resolved molecular weight. Part of the complete positive VP/WSOL/MW triplet that enables the HENRYWIN VP/WSOL candidate.
#' @param mw1000Percentage Optional parameter
#' @param mw500Percentage Optional parameter
#' @param ohConcentrationE6OhPerCm3 Optional parameter
#' @param ozoneConcentrationE11MolPerCm3 Optional parameter
#' @param polymerType Optional parameter
#' @param propoxyGroups Optional parameter
#' @param removeMetals Optional parameter
#' @param riverCurrentMPerSec Optional parameter
#' @param riverDepthMeters Optional parameter
#' @param riverWindMPerSec Optional parameter
#' @param skinSurfaceAreaCm2 Optional parameter
#' @param smiles Raw structure input. A SMILES-only batch item is estimated without experimental results.
#' @param solubilityType Optional parameter
#' @param subcooledVaporPressureMmHg Optional parameter
#' @param theta Optional parameter
#' @param tspUgPerM3 Optional parameter
#' @param userKpCmPerHour Optional parameter
#' @param useSmiles Optional parameter
#' @param vaporPressureMmHg Optional resolved vapor pressure in mmHg. Its omission leaves structural HENRYWIN candidates available.
#' @param vaporPressureTemperatureC Fixed MPBPVP calculation temperature in °C; values other than 25 are rejected.. Options: 25 (default: 25)
#' @param waterConcentrationMgPerCm3 Optional parameter
#' @param waterConcentrationMgPerLiter Optional parameter
#' @param waterSolubility Optional parameter
#' @param waterSolubilityMgPerL Optional resolved water solubility in mg/L. Its omission leaves structural HENRYWIN candidates available.
#' @param waterSolubilityProvider Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_submit_batch(modules = "DTXSID1024122")
#' }
epi_submit_batch <- function(modules, advectionTimeAir = NULL, advectionTimeSediment = NULL, advectionTimeSoil = NULL, advectionTimeWater = NULL, amineNitrogens = NULL, aopRateConstant = NULL, averageMolecularWeight = NULL, averagingTimeDays = NULL, biowin3 = NULL, biowin5 = NULL, biowinScore = NULL, bodyWeightKg = NULL, boilingPointC = NULL, branchedCarbons = NULL, branches = NULL, carbonChainLength = NULL, cas = NULL, cationAnionRatio = NULL, chemicalName = NULL, daylightHours = NULL, emissionRateAir = NULL, emissionRateSediment = NULL, emissionRateSoil = NULL, emissionRateWater = NULL, ethoxylate = NULL, eventDurationHours = NULL, eventFrequencyPerDay = NULL, exposureDurationYears = NULL, exposureFrequencyDaysPerYear = NULL, fractionAbsorbed = NULL, halfLifeAir = NULL, halfLifeHoursAerationVessel = NULL, halfLifeHoursPrimaryClarifier = NULL, halfLifeHoursSettlingTank = NULL, halfLifeSediment = NULL, halfLifeSoil = NULL, halfLifeWater = NULL, henryAtmM3PerMol = NULL, koc = NULL, lakeCurrentMPerSec = NULL, lakeDepthMeters = NULL, lakeWindMPerSec = NULL, logKoa = NULL, logKow = NULL, mainCarbons = NULL, meltingPointC = NULL, molecularWeight = NULL, mw1000Percentage = NULL, mw500Percentage = NULL, ohConcentrationE6OhPerCm3 = NULL, ozoneConcentrationE11MolPerCm3 = NULL, polymerType = NULL, propoxyGroups = NULL, removeMetals = NULL, riverCurrentMPerSec = NULL, riverDepthMeters = NULL, riverWindMPerSec = NULL, skinSurfaceAreaCm2 = NULL, smiles = NULL, solubilityType = NULL, subcooledVaporPressureMmHg = NULL, theta = NULL, tspUgPerM3 = NULL, userKpCmPerHour = NULL, useSmiles = NULL, vaporPressureMmHg = NULL, vaporPressureTemperatureC = 25, waterConcentrationMgPerCm3 = NULL, waterConcentrationMgPerLiter = NULL, waterSolubility = NULL, waterSolubilityMgPerL = NULL, waterSolubilityProvider = NULL) {

  # Build request body
  request_body <- list()
  request_body$modules <- modules
  if (!is.null(advectionTimeAir)) request_body$advectionTimeAir <- advectionTimeAir
  if (!is.null(advectionTimeSediment)) request_body$advectionTimeSediment <- advectionTimeSediment
  if (!is.null(advectionTimeSoil)) request_body$advectionTimeSoil <- advectionTimeSoil
  if (!is.null(advectionTimeWater)) request_body$advectionTimeWater <- advectionTimeWater
  if (!is.null(amineNitrogens)) request_body$amineNitrogens <- amineNitrogens
  if (!is.null(aopRateConstant)) request_body$aopRateConstant <- aopRateConstant
  if (!is.null(averageMolecularWeight)) request_body$averageMolecularWeight <- averageMolecularWeight
  if (!is.null(averagingTimeDays)) request_body$averagingTimeDays <- averagingTimeDays
  if (!is.null(biowin3)) request_body$biowin3 <- biowin3
  if (!is.null(biowin5)) request_body$biowin5 <- biowin5
  if (!is.null(biowinScore)) request_body$biowinScore <- biowinScore
  if (!is.null(bodyWeightKg)) request_body$bodyWeightKg <- bodyWeightKg
  if (!is.null(boilingPointC)) request_body$boilingPointC <- boilingPointC
  if (!is.null(branchedCarbons)) request_body$branchedCarbons <- branchedCarbons
  if (!is.null(branches)) request_body$branches <- branches
  if (!is.null(carbonChainLength)) request_body$carbonChainLength <- carbonChainLength
  if (!is.null(cas)) request_body$cas <- cas
  if (!is.null(cationAnionRatio)) request_body$cationAnionRatio <- cationAnionRatio
  if (!is.null(chemicalName)) request_body$chemicalName <- chemicalName
  if (!is.null(daylightHours)) request_body$daylightHours <- daylightHours
  if (!is.null(emissionRateAir)) request_body$emissionRateAir <- emissionRateAir
  if (!is.null(emissionRateSediment)) request_body$emissionRateSediment <- emissionRateSediment
  if (!is.null(emissionRateSoil)) request_body$emissionRateSoil <- emissionRateSoil
  if (!is.null(emissionRateWater)) request_body$emissionRateWater <- emissionRateWater
  if (!is.null(ethoxylate)) request_body$ethoxylate <- ethoxylate
  if (!is.null(eventDurationHours)) request_body$eventDurationHours <- eventDurationHours
  if (!is.null(eventFrequencyPerDay)) request_body$eventFrequencyPerDay <- eventFrequencyPerDay
  if (!is.null(exposureDurationYears)) request_body$exposureDurationYears <- exposureDurationYears
  if (!is.null(exposureFrequencyDaysPerYear)) request_body$exposureFrequencyDaysPerYear <- exposureFrequencyDaysPerYear
  if (!is.null(fractionAbsorbed)) request_body$fractionAbsorbed <- fractionAbsorbed
  if (!is.null(halfLifeAir)) request_body$halfLifeAir <- halfLifeAir
  if (!is.null(halfLifeHoursAerationVessel)) request_body$halfLifeHoursAerationVessel <- halfLifeHoursAerationVessel
  if (!is.null(halfLifeHoursPrimaryClarifier)) request_body$halfLifeHoursPrimaryClarifier <- halfLifeHoursPrimaryClarifier
  if (!is.null(halfLifeHoursSettlingTank)) request_body$halfLifeHoursSettlingTank <- halfLifeHoursSettlingTank
  if (!is.null(halfLifeSediment)) request_body$halfLifeSediment <- halfLifeSediment
  if (!is.null(halfLifeSoil)) request_body$halfLifeSoil <- halfLifeSoil
  if (!is.null(halfLifeWater)) request_body$halfLifeWater <- halfLifeWater
  if (!is.null(henryAtmM3PerMol)) request_body$henryAtmM3PerMol <- henryAtmM3PerMol
  if (!is.null(koc)) request_body$koc <- koc
  if (!is.null(lakeCurrentMPerSec)) request_body$lakeCurrentMPerSec <- lakeCurrentMPerSec
  if (!is.null(lakeDepthMeters)) request_body$lakeDepthMeters <- lakeDepthMeters
  if (!is.null(lakeWindMPerSec)) request_body$lakeWindMPerSec <- lakeWindMPerSec
  if (!is.null(logKoa)) request_body$logKoa <- logKoa
  if (!is.null(logKow)) request_body$logKow <- logKow
  if (!is.null(mainCarbons)) request_body$mainCarbons <- mainCarbons
  if (!is.null(meltingPointC)) request_body$meltingPointC <- meltingPointC
  if (!is.null(molecularWeight)) request_body$molecularWeight <- molecularWeight
  if (!is.null(mw1000Percentage)) request_body$mw1000Percentage <- mw1000Percentage
  if (!is.null(mw500Percentage)) request_body$mw500Percentage <- mw500Percentage
  if (!is.null(ohConcentrationE6OhPerCm3)) request_body$ohConcentrationE6OhPerCm3 <- ohConcentrationE6OhPerCm3
  if (!is.null(ozoneConcentrationE11MolPerCm3)) request_body$ozoneConcentrationE11MolPerCm3 <- ozoneConcentrationE11MolPerCm3
  if (!is.null(polymerType)) request_body$polymerType <- polymerType
  if (!is.null(propoxyGroups)) request_body$propoxyGroups <- propoxyGroups
  if (!is.null(removeMetals)) request_body$removeMetals <- removeMetals
  if (!is.null(riverCurrentMPerSec)) request_body$riverCurrentMPerSec <- riverCurrentMPerSec
  if (!is.null(riverDepthMeters)) request_body$riverDepthMeters <- riverDepthMeters
  if (!is.null(riverWindMPerSec)) request_body$riverWindMPerSec <- riverWindMPerSec
  if (!is.null(skinSurfaceAreaCm2)) request_body$skinSurfaceAreaCm2 <- skinSurfaceAreaCm2
  if (!is.null(smiles)) request_body$smiles <- smiles
  if (!is.null(solubilityType)) request_body$solubilityType <- solubilityType
  if (!is.null(subcooledVaporPressureMmHg)) request_body$subcooledVaporPressureMmHg <- subcooledVaporPressureMmHg
  if (!is.null(theta)) request_body$theta <- theta
  if (!is.null(tspUgPerM3)) request_body$tspUgPerM3 <- tspUgPerM3
  if (!is.null(userKpCmPerHour)) request_body$userKpCmPerHour <- userKpCmPerHour
  if (!is.null(useSmiles)) request_body$useSmiles <- useSmiles
  if (!is.null(vaporPressureMmHg)) request_body$vaporPressureMmHg <- vaporPressureMmHg
  if (!is.null(vaporPressureTemperatureC)) request_body$vaporPressureTemperatureC <- vaporPressureTemperatureC
  if (!is.null(waterConcentrationMgPerCm3)) request_body$waterConcentrationMgPerCm3 <- waterConcentrationMgPerCm3
  if (!is.null(waterConcentrationMgPerLiter)) request_body$waterConcentrationMgPerLiter <- waterConcentrationMgPerLiter
  if (!is.null(waterSolubility)) request_body$waterSolubility <- waterSolubility
  if (!is.null(waterSolubilityMgPerL)) request_body$waterSolubilityMgPerL <- waterSolubilityMgPerL
  if (!is.null(waterSolubilityProvider)) request_body$waterSolubilityProvider <- waterSolubilityProvider
  result <- generic_request(
    query = NULL,
    endpoint = "submit/batch",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000")),
    body = request_body
  )

  # Additional post-processing can be added here

  return(result)
}


