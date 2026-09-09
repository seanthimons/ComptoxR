#' Estimate an ordered batch of chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
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
#' @param useSmiles Optional parameter
#' @param userKpCmPerHour Optional parameter
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
#' @examples
#' \dontrun{
#' epi_submit_batch(modules = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
epi_submit_batch <- function(
  modules,
  advectionTimeAir = NULL,
  advectionTimeSediment = NULL,
  advectionTimeSoil = NULL,
  advectionTimeWater = NULL,
  amineNitrogens = NULL,
  aopRateConstant = NULL,
  averageMolecularWeight = NULL,
  averagingTimeDays = NULL,
  biowin3 = NULL,
  biowin5 = NULL,
  biowinScore = NULL,
  bodyWeightKg = NULL,
  boilingPointC = NULL,
  branchedCarbons = NULL,
  branches = NULL,
  carbonChainLength = NULL,
  cas = NULL,
  cationAnionRatio = NULL,
  chemicalName = NULL,
  daylightHours = NULL,
  emissionRateAir = NULL,
  emissionRateSediment = NULL,
  emissionRateSoil = NULL,
  emissionRateWater = NULL,
  ethoxylate = NULL,
  eventDurationHours = NULL,
  eventFrequencyPerDay = NULL,
  exposureDurationYears = NULL,
  exposureFrequencyDaysPerYear = NULL,
  fractionAbsorbed = NULL,
  halfLifeAir = NULL,
  halfLifeHoursAerationVessel = NULL,
  halfLifeHoursPrimaryClarifier = NULL,
  halfLifeHoursSettlingTank = NULL,
  halfLifeSediment = NULL,
  halfLifeSoil = NULL,
  halfLifeWater = NULL,
  henryAtmM3PerMol = NULL,
  koc = NULL,
  lakeCurrentMPerSec = NULL,
  lakeDepthMeters = NULL,
  lakeWindMPerSec = NULL,
  logKoa = NULL,
  logKow = NULL,
  mainCarbons = NULL,
  meltingPointC = NULL,
  molecularWeight = NULL,
  mw1000Percentage = NULL,
  mw500Percentage = NULL,
  ohConcentrationE6OhPerCm3 = NULL,
  ozoneConcentrationE11MolPerCm3 = NULL,
  polymerType = NULL,
  propoxyGroups = NULL,
  removeMetals = NULL,
  riverCurrentMPerSec = NULL,
  riverDepthMeters = NULL,
  riverWindMPerSec = NULL,
  skinSurfaceAreaCm2 = NULL,
  smiles = NULL,
  solubilityType = NULL,
  subcooledVaporPressureMmHg = NULL,
  theta = NULL,
  tspUgPerM3 = NULL,
  useSmiles = NULL,
  userKpCmPerHour = NULL,
  vaporPressureMmHg = NULL,
  vaporPressureTemperatureC = 25,
  waterConcentrationMgPerCm3 = NULL,
  waterConcentrationMgPerLiter = NULL,
  waterSolubility = NULL,
  waterSolubilityMgPerL = NULL,
  waterSolubilityProvider = NULL
) {
  params <- list(
    "modules" = modules,
    "advectionTimeAir" = advectionTimeAir,
    "advectionTimeSediment" = advectionTimeSediment,
    "advectionTimeSoil" = advectionTimeSoil,
    "advectionTimeWater" = advectionTimeWater,
    "amineNitrogens" = amineNitrogens,
    "aopRateConstant" = aopRateConstant,
    "averageMolecularWeight" = averageMolecularWeight,
    "averagingTimeDays" = averagingTimeDays,
    "biowin3" = biowin3,
    "biowin5" = biowin5,
    "biowinScore" = biowinScore,
    "bodyWeightKg" = bodyWeightKg,
    "boilingPointC" = boilingPointC,
    "branchedCarbons" = branchedCarbons,
    "branches" = branches,
    "carbonChainLength" = carbonChainLength,
    "cas" = cas,
    "cationAnionRatio" = cationAnionRatio,
    "chemicalName" = chemicalName,
    "daylightHours" = daylightHours,
    "emissionRateAir" = emissionRateAir,
    "emissionRateSediment" = emissionRateSediment,
    "emissionRateSoil" = emissionRateSoil,
    "emissionRateWater" = emissionRateWater,
    "ethoxylate" = ethoxylate,
    "eventDurationHours" = eventDurationHours,
    "eventFrequencyPerDay" = eventFrequencyPerDay,
    "exposureDurationYears" = exposureDurationYears,
    "exposureFrequencyDaysPerYear" = exposureFrequencyDaysPerYear,
    "fractionAbsorbed" = fractionAbsorbed,
    "halfLifeAir" = halfLifeAir,
    "halfLifeHoursAerationVessel" = halfLifeHoursAerationVessel,
    "halfLifeHoursPrimaryClarifier" = halfLifeHoursPrimaryClarifier,
    "halfLifeHoursSettlingTank" = halfLifeHoursSettlingTank,
    "halfLifeSediment" = halfLifeSediment,
    "halfLifeSoil" = halfLifeSoil,
    "halfLifeWater" = halfLifeWater,
    "henryAtmM3PerMol" = henryAtmM3PerMol,
    "koc" = koc,
    "lakeCurrentMPerSec" = lakeCurrentMPerSec,
    "lakeDepthMeters" = lakeDepthMeters,
    "lakeWindMPerSec" = lakeWindMPerSec,
    "logKoa" = logKoa,
    "logKow" = logKow,
    "mainCarbons" = mainCarbons,
    "meltingPointC" = meltingPointC,
    "molecularWeight" = molecularWeight,
    "mw1000Percentage" = mw1000Percentage,
    "mw500Percentage" = mw500Percentage,
    "ohConcentrationE6OhPerCm3" = ohConcentrationE6OhPerCm3,
    "ozoneConcentrationE11MolPerCm3" = ozoneConcentrationE11MolPerCm3,
    "polymerType" = polymerType,
    "propoxyGroups" = propoxyGroups,
    "removeMetals" = removeMetals,
    "riverCurrentMPerSec" = riverCurrentMPerSec,
    "riverDepthMeters" = riverDepthMeters,
    "riverWindMPerSec" = riverWindMPerSec,
    "skinSurfaceAreaCm2" = skinSurfaceAreaCm2,
    "smiles" = smiles,
    "solubilityType" = solubilityType,
    "subcooledVaporPressureMmHg" = subcooledVaporPressureMmHg,
    "theta" = theta,
    "tspUgPerM3" = tspUgPerM3,
    "useSmiles" = useSmiles,
    "userKpCmPerHour" = userKpCmPerHour,
    "vaporPressureMmHg" = vaporPressureMmHg,
    "vaporPressureTemperatureC" = vaporPressureTemperatureC,
    "waterConcentrationMgPerCm3" = waterConcentrationMgPerCm3,
    "waterConcentrationMgPerLiter" = waterConcentrationMgPerLiter,
    "waterSolubility" = waterSolubility,
    "waterSolubilityMgPerL" = waterSolubilityMgPerL,
    "waterSolubilityProvider" = waterSolubilityProvider
  )
  result <- generic_request(
    "query" = NULL,
    "endpoint" = "submit/batch",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "1000")),
    "body" = list(local({
      .body <- Filter(
        Negate(is.null),
        list(
          "modules" = params[["modules"]],
          "advectionTimeAir" = params[["advectionTimeAir"]],
          "advectionTimeSediment" = params[["advectionTimeSediment"]],
          "advectionTimeSoil" = params[["advectionTimeSoil"]],
          "advectionTimeWater" = params[["advectionTimeWater"]],
          "amineNitrogens" = params[["amineNitrogens"]],
          "aopRateConstant" = params[["aopRateConstant"]],
          "averageMolecularWeight" = params[["averageMolecularWeight"]],
          "averagingTimeDays" = params[["averagingTimeDays"]],
          "biowin3" = params[["biowin3"]],
          "biowin5" = params[["biowin5"]],
          "biowinScore" = params[["biowinScore"]],
          "bodyWeightKg" = params[["bodyWeightKg"]],
          "boilingPointC" = params[["boilingPointC"]],
          "branchedCarbons" = params[["branchedCarbons"]],
          "branches" = params[["branches"]],
          "carbonChainLength" = params[["carbonChainLength"]],
          "cas" = params[["cas"]],
          "cationAnionRatio" = params[["cationAnionRatio"]],
          "chemicalName" = params[["chemicalName"]],
          "daylightHours" = params[["daylightHours"]],
          "emissionRateAir" = params[["emissionRateAir"]],
          "emissionRateSediment" = params[["emissionRateSediment"]],
          "emissionRateSoil" = params[["emissionRateSoil"]],
          "emissionRateWater" = params[["emissionRateWater"]],
          "ethoxylate" = params[["ethoxylate"]],
          "eventDurationHours" = params[["eventDurationHours"]],
          "eventFrequencyPerDay" = params[["eventFrequencyPerDay"]],
          "exposureDurationYears" = params[["exposureDurationYears"]],
          "exposureFrequencyDaysPerYear" = params[["exposureFrequencyDaysPerYear"]],
          "fractionAbsorbed" = params[["fractionAbsorbed"]],
          "halfLifeAir" = params[["halfLifeAir"]],
          "halfLifeHoursAerationVessel" = params[["halfLifeHoursAerationVessel"]],
          "halfLifeHoursPrimaryClarifier" = params[["halfLifeHoursPrimaryClarifier"]],
          "halfLifeHoursSettlingTank" = params[["halfLifeHoursSettlingTank"]],
          "halfLifeSediment" = params[["halfLifeSediment"]],
          "halfLifeSoil" = params[["halfLifeSoil"]],
          "halfLifeWater" = params[["halfLifeWater"]],
          "henryAtmM3PerMol" = params[["henryAtmM3PerMol"]],
          "koc" = params[["koc"]],
          "lakeCurrentMPerSec" = params[["lakeCurrentMPerSec"]],
          "lakeDepthMeters" = params[["lakeDepthMeters"]],
          "lakeWindMPerSec" = params[["lakeWindMPerSec"]],
          "logKoa" = params[["logKoa"]],
          "logKow" = params[["logKow"]],
          "mainCarbons" = params[["mainCarbons"]],
          "meltingPointC" = params[["meltingPointC"]],
          "molecularWeight" = params[["molecularWeight"]],
          "mw1000Percentage" = params[["mw1000Percentage"]],
          "mw500Percentage" = params[["mw500Percentage"]],
          "ohConcentrationE6OhPerCm3" = params[["ohConcentrationE6OhPerCm3"]],
          "ozoneConcentrationE11MolPerCm3" = params[["ozoneConcentrationE11MolPerCm3"]],
          "polymerType" = params[["polymerType"]],
          "propoxyGroups" = params[["propoxyGroups"]],
          "removeMetals" = params[["removeMetals"]],
          "riverCurrentMPerSec" = params[["riverCurrentMPerSec"]],
          "riverDepthMeters" = params[["riverDepthMeters"]],
          "riverWindMPerSec" = params[["riverWindMPerSec"]],
          "skinSurfaceAreaCm2" = params[["skinSurfaceAreaCm2"]],
          "smiles" = params[["smiles"]],
          "solubilityType" = params[["solubilityType"]],
          "subcooledVaporPressureMmHg" = params[["subcooledVaporPressureMmHg"]],
          "theta" = params[["theta"]],
          "tspUgPerM3" = params[["tspUgPerM3"]],
          "useSmiles" = params[["useSmiles"]],
          "userKpCmPerHour" = params[["userKpCmPerHour"]],
          "vaporPressureMmHg" = params[["vaporPressureMmHg"]],
          "vaporPressureTemperatureC" = params[["vaporPressureTemperatureC"]],
          "waterConcentrationMgPerCm3" = params[["waterConcentrationMgPerCm3"]],
          "waterConcentrationMgPerLiter" = params[["waterConcentrationMgPerLiter"]],
          "waterSolubility" = params[["waterSolubility"]],
          "waterSolubilityMgPerL" = params[["waterSolubilityMgPerL"]],
          "waterSolubilityProvider" = params[["waterSolubilityProvider"]]
        )
      )
      if (length(.body)) .body else list()
    })),
    "server" = "epi_burl",
    "auth" = FALSE
  )
  result
}
