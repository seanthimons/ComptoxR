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
#' @return Returns a tibble with the batch response
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_submit_batch(modules = "logKow", smiles = "CCO")
#' }
# Generated with specmill; do not edit by hand.
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
  params <- base::list(
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
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/submit/batch",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = .api_validation$body_value(
      base::list(base::Filter(base::Negate(base::is.null), params)),
      list(
        items = structure(
          list(
            additionalProperties = FALSE,
            properties = list(
              advectionTimeAir = list(type = "number"),
              advectionTimeSediment = list(type = "number"),
              advectionTimeSoil = list(type = "number"),
              advectionTimeWater = list(type = "number"),
              amineNitrogens = list(type = "number"),
              aopRateConstant = list(type = "number"),
              averageMolecularWeight = list(type = "number"),
              averagingTimeDays = list(type = "number"),
              biowin3 = list(type = "number"),
              biowin5 = list(type = "number"),
              biowinScore = list(type = "number"),
              bodyWeightKg = list(type = "number"),
              boilingPointC = list(type = "number"),
              branchedCarbons = list(type = "integer"),
              branches = list(type = "integer"),
              carbonChainLength = list(type = "integer"),
              cas = list(
                description = "CAS Registry Number. Only a CAS-identified batch item can resolve experimental results; CAS takes precedence when SMILES is also supplied.",
                type = "string"
              ),
              cationAnionRatio = list(
                type = "number"
              ),
              chemicalName = list(type = "string"),
              daylightHours = list(type = "number"),
              emissionRateAir = list(type = "number"),
              emissionRateSediment = list(type = "number"),
              emissionRateSoil = list(type = "number"),
              emissionRateWater = list(type = "number"),
              ethoxylate = list(type = "integer"),
              eventDurationHours = list(type = "number"),
              eventFrequencyPerDay = list(type = "number"),
              exposureDurationYears = list(type = "number"),
              exposureFrequencyDaysPerYear = list(type = "number"),
              fractionAbsorbed = list(type = "number"),
              halfLifeAir = list(type = "number"),
              halfLifeHoursAerationVessel = list(type = "number"),
              halfLifeHoursPrimaryClarifier = list(type = "number"),
              halfLifeHoursSettlingTank = list(type = "number"),
              halfLifeSediment = list(type = "number"),
              halfLifeSoil = list(type = "number"),
              halfLifeWater = list(type = "number"),
              henryAtmM3PerMol = list(type = "number"),
              koc = list(type = "number"),
              lakeCurrentMPerSec = list(type = "number"),
              lakeDepthMeters = list(type = "number"),
              lakeWindMPerSec = list(type = "number"),
              logKoa = list(type = "number"),
              logKow = list(type = "number"),
              mainCarbons = list(type = "integer"),
              meltingPointC = list(type = "number"),
              modules = list(
                description = "Selected calculations. Items run in canonical dependency order rather than submitted array order; use waterSolubilityProvider for the shared water-solubility choice.",
                items = list(
                  enum = list(
                    "logKow",
                    "physicalProperties",
                    "waterSolubilityFromLogKow",
                    "waterSolubilityFromWaterNt",
                    "henrysLawConstant",
                    "logKoc",
                    "atmosphericHalfLife",
                    "biodegradationRate",
                    "logKoa",
                    "aerosolAdsorptionFraction",
                    "dermalPermeability",
                    "sewageTreatmentModel",
                    "waterVolatilization",
                    "fugacityModel",
                    "hydrocarbonBiodegradationRate",
                    "bioconcentration",
                    "ecosar.organics",
                    "ecosar.nonionic-surfactant",
                    "ecosar.anionic-surfactant",
                    "ecosar.cationic-surfactant",
                    "ecosar.amphoteric-surfactant",
                    "ecosar.dye",
                    "ecosar.nonionic-polymer",
                    "ecosar.anionic-polymer",
                    "ecosar.amphoteric-polymer",
                    "ecosar.polycationic-polymer",
                    "fishBiotransformationRate",
                    "hydrolysis",
                    "analogIdentification"
                  ),
                  type = "string"
                ),
                minItems = 1L,
                type = "array",
                uniqueItems = TRUE
              ),
              molecularWeight = list(
                description = "Optional resolved molecular weight. Part of the complete positive VP/WSOL/MW triplet that enables the HENRYWIN VP/WSOL candidate.",
                type = "number"
              ),
              mw1000Percentage = list(type = "number"),
              mw500Percentage = list(type = "number"),
              ohConcentrationE6OhPerCm3 = list(type = "number"),
              ozoneConcentrationE11MolPerCm3 = list(
                type = "number"
              ),
              polymerType = list(type = "string"),
              propoxyGroups = list(type = "number"),
              removeMetals = list(type = "boolean"),
              riverCurrentMPerSec = list(type = "number"),
              riverDepthMeters = list(type = "number"),
              riverWindMPerSec = list(type = "number"),
              skinSurfaceAreaCm2 = list(type = "number"),
              smiles = list(
                description = "Raw structure input. A SMILES-only batch item is estimated without experimental results.",
                type = "string"
              ),
              solubilityType = list(type = "string"),
              subcooledVaporPressureMmHg = list(
                type = "number"
              ),
              theta = list(type = "number"),
              tspUgPerM3 = list(type = "number"),
              useSmiles = list(type = "boolean"),
              userKpCmPerHour = list(type = "number"),
              vaporPressureMmHg = list(
                description = "Optional resolved vapor pressure in mmHg. Its omission leaves structural HENRYWIN candidates available.",
                type = "number"
              ),
              vaporPressureTemperatureC = list(
                default = 25L,
                description = "Fixed MPBPVP calculation temperature in \U000000b0C; values other than 25 are rejected.",
                enum = list(25L),
                type = "number"
              ),
              waterConcentrationMgPerCm3 = list(type = "number"),
              waterConcentrationMgPerLiter = list(type = "number"),
              waterSolubility = list(type = "number"),
              waterSolubilityMgPerL = list(
                description = "Optional resolved water solubility in mg/L. Its omission leaves structural HENRYWIN candidates available.",
                type = "number"
              ),
              waterSolubilityProvider = list(type = "string")
            ),
            required = list("modules"),
            type = "object"
          ),
          specmill_id = "#/components/schemas/BatchEstimateRequest"
        ),
        maxItems = 100L,
        minItems = 1L,
        type = "array"
      )
    ),
    "headers" = list(Accept = "application/json"),
    "server" = list(),
    "server_resolver" = list(name = ".ct_server_url", key = "epi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = ".ct_static_tidy"
  )
  result
}
