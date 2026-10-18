#' Export WebTEST predictions
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON or text, raw binary bytes, or NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_webtest_predict_export <- function(body) {
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(
        body,
        structure(
          list(
            properties = list(
              format = list(
                enum = list("UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML", "XML", "DOCX"),
                type = "string"
              ),
              predictionResult = structure(
                list(
                  properties = list(
                    chemicals = list(
                      items = structure(
                        list(
                          properties = list(
                            chemical = structure(
                              list(
                                properties = list(
                                  averageMass = list(format = "double", type = "number"),
                                  casrn = list(type = "string"),
                                  chemId = list(type = "string"),
                                  cid = list(type = "string"),
                                  error = list(type = "string"),
                                  id = list(type = "string"),
                                  inchi = list(type = "string"),
                                  inchiKey = list(type = "string"),
                                  inchiKey1 = list(type = "string"),
                                  mol = list(type = "string"),
                                  monoisotopicMass = list(format = "double", type = "number"),
                                  name = list(type = "string"),
                                  sid = list(type = "string"),
                                  smiles = list(type = "string")
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/DSSToxRecord"
                            ),
                            chemicalId = list(type = "string"),
                            endpoints = list(
                              items = structure(
                                list(
                                  properties = list(
                                    displayedExperimentalString = list(
                                      type = "string"
                                    ),
                                    displayedPredictedString = list(type = "string"),
                                    endpoint = structure(
                                      list(
                                        properties = list(
                                          binary = list(type = "boolean"),
                                          description = list(type = "string"),
                                          id = list(type = "string"),
                                          logMolar = list(type = "boolean"),
                                          logUnits = list(type = "string"),
                                          logValueDigits = list(format = "int32", type = "integer"),
                                          name = list(type = "string"),
                                          units = list(type = "string"),
                                          valueDigits = list(format = "int32", type = "integer")
                                        ),
                                        type = "object"
                                      ),
                                      specmill_id = "#/components/schemas/EndpointInfo"
                                    ),
                                    experimental = list(
                                      items = structure(
                                        list(
                                          properties = list(
                                            active = list(type = "boolean"),
                                            error = list(type = "string"),
                                            errorCode = list(type = "string"),
                                            logValue = list(format = "double", type = "number"),
                                            message = list(type = "string"),
                                            method = list(type = "string"),
                                            predictionResults = structure(
                                              list(
                                                properties = list(
                                                  binaryEndpoint = list(type = "boolean"),
                                                  cacheId = list(type = "string"),
                                                  cas = list(type = "string"),
                                                  clusterTable = structure(
                                                    list(
                                                      properties = list(
                                                        caption = list(
                                                          type = "string"
                                                        ),
                                                        clusterModels = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                binary = list(type = "boolean"),
                                                                clusterID = list(type = "string"),
                                                                concordance = list(type = "string"),
                                                                descriptors = list(
                                                                  items = structure(
                                                                    list(
                                                                      properties = list(
                                                                        coefficient = list(type = "string"),
                                                                        coefficientUncertainty = list(type = "string"),
                                                                        definition = list(type = "string"),
                                                                        name = list(type = "string"),
                                                                        value = list(type = "string"),
                                                                        value_x_coefficient = list(type = "string")
                                                                      ),
                                                                      type = "object"
                                                                    ),
                                                                    specmill_id = "#/components/schemas/Descriptor"
                                                                  ),
                                                                  type = "array"
                                                                ),
                                                                messageAD = list(type = "string"),
                                                                minMaxValue = list(type = "string"),
                                                                modelEquation = list(type = "string"),
                                                                numChemicals = list(format = "int32", type = "integer"),
                                                                omitted = list(type = "boolean"),
                                                                plotImage = list(type = "string"),
                                                                predictedValue = list(type = "string"),
                                                                predictedValueLabel = list(type = "string"),
                                                                q2 = list(type = "string"),
                                                                r2 = list(type = "string"),
                                                                sensitivity = list(type = "string"),
                                                                specificity = list(type = "string"),
                                                                url = list(type = "string"),
                                                                urlDescriptors = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/ClusterModel"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        message = list(type = "string"),
                                                        units = list(type = "string")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/ClusterTable"
                                                  ),
                                                  createDetailedReport = list(type = "boolean"),
                                                  dtxcid = list(type = "string"),
                                                  dtxsid = list(type = "string"),
                                                  endpoint = list(type = "string"),
                                                  error = list(type = "string"),
                                                  imageURL = list(type = "string"),
                                                  imgSize = list(format = "int32", type = "integer"),
                                                  individualPredictionsForConsensus = structure(
                                                    list(
                                                      properties = list(
                                                        consensusPredictions = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                fileName = list(type = "string"),
                                                                method = list(type = "string"),
                                                                prediction = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/PredictionIndividualMethod"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        units = list(type = "string")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/IndividualPredictionsForConsensus"
                                                  ),
                                                  invalidClusterTable = structure(
                                                    list(
                                                      properties = list(
                                                        caption = list(type = "string"),
                                                        clusterModels = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                binary = list(type = "boolean"),
                                                                clusterID = list(type = "string"),
                                                                concordance = list(type = "string"),
                                                                descriptors = list(
                                                                  items = structure(
                                                                    list(
                                                                      properties = list(
                                                                        coefficient = list(type = "string"),
                                                                        coefficientUncertainty = list(type = "string"),
                                                                        definition = list(type = "string"),
                                                                        name = list(type = "string"),
                                                                        value = list(type = "string"),
                                                                        value_x_coefficient = list(type = "string")
                                                                      ),
                                                                      type = "object"
                                                                    ),
                                                                    specmill_id = "#/components/schemas/Descriptor"
                                                                  ),
                                                                  type = "array"
                                                                ),
                                                                messageAD = list(type = "string"),
                                                                minMaxValue = list(type = "string"),
                                                                modelEquation = list(type = "string"),
                                                                numChemicals = list(format = "int32", type = "integer"),
                                                                omitted = list(type = "boolean"),
                                                                plotImage = list(type = "string"),
                                                                predictedValue = list(type = "string"),
                                                                predictedValueLabel = list(type = "string"),
                                                                q2 = list(type = "string"),
                                                                r2 = list(type = "string"),
                                                                sensitivity = list(type = "string"),
                                                                specificity = list(type = "string"),
                                                                url = list(type = "string"),
                                                                urlDescriptors = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/ClusterModel"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        message = list(type = "string"),
                                                        units = list(type = "string")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/ClusterTable"
                                                  ),
                                                  logMolarEndpoint = list(type = "boolean"),
                                                  method = list(type = "string"),
                                                  moaTable = structure(
                                                    list(
                                                      properties = list(
                                                        moapredictions = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                clusterModelLC50 = structure(
                                                                  list(
                                                                    properties = list(
                                                                      binary = list(type = "boolean"),
                                                                      clusterID = list(type = "string"),
                                                                      concordance = list(type = "string"),
                                                                      descriptors = list(
                                                                        items = structure(
                                                                          list(
                                                                            properties = list(
                                                                              coefficient = list(type = "string"),
                                                                              coefficientUncertainty = list(
                                                                                type = "string"
                                                                              ),
                                                                              definition = list(type = "string"),
                                                                              name = list(type = "string"),
                                                                              value = list(type = "string"),
                                                                              value_x_coefficient = list(
                                                                                type = "string"
                                                                              )
                                                                            ),
                                                                            type = "object"
                                                                          ),
                                                                          specmill_id = "#/components/schemas/Descriptor"
                                                                        ),
                                                                        type = "array"
                                                                      ),
                                                                      messageAD = list(type = "string"),
                                                                      minMaxValue = list(type = "string"),
                                                                      modelEquation = list(type = "string"),
                                                                      numChemicals = list(
                                                                        format = "int32",
                                                                        type = "integer"
                                                                      ),
                                                                      omitted = list(type = "boolean"),
                                                                      plotImage = list(type = "string"),
                                                                      predictedValue = list(type = "string"),
                                                                      predictedValueLabel = list(type = "string"),
                                                                      q2 = list(type = "string"),
                                                                      r2 = list(type = "string"),
                                                                      sensitivity = list(type = "string"),
                                                                      specificity = list(type = "string"),
                                                                      url = list(type = "string"),
                                                                      urlDescriptors = list(type = "string")
                                                                    ),
                                                                    type = "object"
                                                                  ),
                                                                  specmill_id = "#/components/schemas/ClusterModel"
                                                                ),
                                                                clusterModelMOA = structure(
                                                                  list(
                                                                    properties = list(
                                                                      binary = list(type = "boolean"),
                                                                      clusterID = list(type = "string"),
                                                                      concordance = list(type = "string"),
                                                                      descriptors = list(
                                                                        items = structure(
                                                                          list(
                                                                            properties = list(
                                                                              coefficient = list(type = "string"),
                                                                              coefficientUncertainty = list(
                                                                                type = "string"
                                                                              ),
                                                                              definition = list(type = "string"),
                                                                              name = list(type = "string"),
                                                                              value = list(
                                                                                type = "string"
                                                                              ),
                                                                              value_x_coefficient = list(
                                                                                type = "string"
                                                                              )
                                                                            ),
                                                                            type = "object"
                                                                          ),
                                                                          specmill_id = "#/components/schemas/Descriptor"
                                                                        ),
                                                                        type = "array"
                                                                      ),
                                                                      messageAD = list(type = "string"),
                                                                      minMaxValue = list(type = "string"),
                                                                      modelEquation = list(type = "string"),
                                                                      numChemicals = list(
                                                                        format = "int32",
                                                                        type = "integer"
                                                                      ),
                                                                      omitted = list(type = "boolean"),
                                                                      plotImage = list(type = "string"),
                                                                      predictedValue = list(type = "string"),
                                                                      predictedValueLabel = list(type = "string"),
                                                                      q2 = list(type = "string"),
                                                                      r2 = list(type = "string"),
                                                                      sensitivity = list(type = "string"),
                                                                      specificity = list(type = "string"),
                                                                      url = list(type = "string"),
                                                                      urlDescriptors = list(type = "string")
                                                                    ),
                                                                    type = "object"
                                                                  ),
                                                                  specmill_id = "#/components/schemas/ClusterModel"
                                                                ),
                                                                color = list(type = "string"),
                                                                lc50Score = list(type = "string"),
                                                                lc50ScoreMsg = list(type = "string"),
                                                                moa = list(type = "string"),
                                                                moascore = list(type = "string"),
                                                                moascoreMsg = list(type = "string"),
                                                                tag = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/MOAPrediction"
                                                          ),
                                                          type = "array"
                                                        )
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/MOATable"
                                                  ),
                                                  predictionResultsPrimaryTable = structure(
                                                    list(
                                                      properties = list(
                                                        dtxcid = list(type = "string"),
                                                        endpointSources = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                sourceName = list(type = "string"),
                                                                sourceURL = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/EndpointSource"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        endpointSubscripted = list(type = "string"),
                                                        expCAS = list(type = "string"),
                                                        expMOA = list(
                                                          type = "string"
                                                        ),
                                                        expSet = list(type = "string"),
                                                        expToxValMass = list(type = "string"),
                                                        expToxValue = list(type = "string"),
                                                        expToxValueEndpoint = list(type = "string"),
                                                        massUnits = list(type = "string"),
                                                        maxScoreMOA = list(type = "string"),
                                                        message = list(type = "string"),
                                                        molarLogUnits = list(type = "string"),
                                                        predMOA = list(type = "string"),
                                                        predMinMaxVal = list(type = "string"),
                                                        predMinMaxValMass = list(type = "string"),
                                                        predToxValMass = list(type = "string"),
                                                        predToxValue = list(type = "string"),
                                                        predValueEndpoint = list(type = "string"),
                                                        predictedValueNote = list(type = "string"),
                                                        predictedValueSuperscript = list(type = "string"),
                                                        source = list(type = "string"),
                                                        writePredictionInterval = list(type = "boolean")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/PredictionResultsPrimaryTable"
                                                  ),
                                                  reportBase = list(type = "string"),
                                                  scmin = list(format = "double", type = "number"),
                                                  similarChemicals = list(
                                                    items = structure(
                                                      list(
                                                        properties = list(
                                                          cancerStats = structure(
                                                            list(
                                                              properties = list(
                                                                concordance = list(type = "string"),
                                                                correctCount = list(format = "int32", type = "integer"),
                                                                negConcordance = list(type = "string"),
                                                                negCorrectCount = list(
                                                                  format = "int32",
                                                                  type = "integer"
                                                                ),
                                                                negPredCount = list(format = "int32", type = "integer"),
                                                                posConcordance = list(type = "string"),
                                                                posCorrectCount = list(
                                                                  format = "int32",
                                                                  type = "integer"
                                                                ),
                                                                posPredCount = list(format = "int32", type = "integer"),
                                                                predCount = list(format = "int32", type = "integer")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/CancerStats"
                                                          ),
                                                          expVal = list(type = "string"),
                                                          externalPredChart = structure(
                                                            list(
                                                              properties = list(
                                                                externalPredChartImageSrc = list(type = "string"),
                                                                mae = list(format = "double", type = "number"),
                                                                maeentireTestSet = list(
                                                                  format = "double",
                                                                  type = "number"
                                                                )
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/ExternalPredChart"
                                                          ),
                                                          predVal = list(type = "string"),
                                                          similarChemicalsCount = list(
                                                            format = "int32",
                                                            type = "integer"
                                                          ),
                                                          similarChemicalsList = list(
                                                            items = structure(
                                                              list(
                                                                properties = list(
                                                                  backgroundColor = list(
                                                                    type = "string"
                                                                  ),
                                                                  cas = list(type = "string"),
                                                                  dsstoxcid = list(type = "string"),
                                                                  dsstoxsid = list(type = "string"),
                                                                  expVal = list(type = "string"),
                                                                  gsid = list(type = "string"),
                                                                  imageUrl = list(type = "string"),
                                                                  predVal = list(type = "string"),
                                                                  similarityCoefficient = list(type = "string")
                                                                ),
                                                                type = "object"
                                                              ),
                                                              specmill_id = "#/components/schemas/SimilarChemical"
                                                            ),
                                                            type = "array"
                                                          ),
                                                          similarChemicalsSet = list(type = "string"),
                                                          units = list(type = "string")
                                                        ),
                                                        type = "object"
                                                      ),
                                                      specmill_id = "#/components/schemas/SimilarChemicals"
                                                    ),
                                                    type = "array"
                                                  ),
                                                  smiles = list(type = "string"),
                                                  version = list(type = "string"),
                                                  webPath = list(type = "string"),
                                                  webPath2 = list(type = "string")
                                                ),
                                                type = "object"
                                              ),
                                              specmill_id = "#/components/schemas/PredictionResults"
                                            ),
                                            resultMessage = structure(
                                              list(
                                                properties = list(
                                                  code = list(type = "string"),
                                                  message = list(type = "string"),
                                                  severity = list(
                                                    enum = list("INFO", "WARNING", "ERROR"),
                                                    type = "string"
                                                  )
                                                ),
                                                type = "object"
                                              ),
                                              specmill_id = "#/components/schemas/PredictionResultMessage"
                                            ),
                                            value = list(format = "double", type = "number")
                                          ),
                                          type = "object"
                                        ),
                                        specmill_id = "#/components/schemas/PredictionValue"
                                      ),
                                      type = "array"
                                    ),
                                    path = list(type = "string"),
                                    predicted = list(
                                      items = structure(
                                        list(
                                          properties = list(
                                            active = list(type = "boolean"),
                                            error = list(type = "string"),
                                            errorCode = list(type = "string"),
                                            logValue = list(format = "double", type = "number"),
                                            message = list(type = "string"),
                                            method = list(type = "string"),
                                            predictionResults = structure(
                                              list(
                                                properties = list(
                                                  binaryEndpoint = list(type = "boolean"),
                                                  cacheId = list(type = "string"),
                                                  cas = list(type = "string"),
                                                  clusterTable = structure(
                                                    list(
                                                      properties = list(
                                                        caption = list(type = "string"),
                                                        clusterModels = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                binary = list(type = "boolean"),
                                                                clusterID = list(type = "string"),
                                                                concordance = list(type = "string"),
                                                                descriptors = list(
                                                                  items = structure(
                                                                    list(
                                                                      properties = list(
                                                                        coefficient = list(type = "string"),
                                                                        coefficientUncertainty = list(type = "string"),
                                                                        definition = list(type = "string"),
                                                                        name = list(type = "string"),
                                                                        value = list(type = "string"),
                                                                        value_x_coefficient = list(type = "string")
                                                                      ),
                                                                      type = "object"
                                                                    ),
                                                                    specmill_id = "#/components/schemas/Descriptor"
                                                                  ),
                                                                  type = "array"
                                                                ),
                                                                messageAD = list(type = "string"),
                                                                minMaxValue = list(type = "string"),
                                                                modelEquation = list(type = "string"),
                                                                numChemicals = list(format = "int32", type = "integer"),
                                                                omitted = list(type = "boolean"),
                                                                plotImage = list(type = "string"),
                                                                predictedValue = list(type = "string"),
                                                                predictedValueLabel = list(type = "string"),
                                                                q2 = list(type = "string"),
                                                                r2 = list(type = "string"),
                                                                sensitivity = list(type = "string"),
                                                                specificity = list(type = "string"),
                                                                url = list(type = "string"),
                                                                urlDescriptors = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/ClusterModel"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        message = list(type = "string"),
                                                        units = list(type = "string")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/ClusterTable"
                                                  ),
                                                  createDetailedReport = list(
                                                    type = "boolean"
                                                  ),
                                                  dtxcid = list(type = "string"),
                                                  dtxsid = list(type = "string"),
                                                  endpoint = list(type = "string"),
                                                  error = list(type = "string"),
                                                  imageURL = list(type = "string"),
                                                  imgSize = list(format = "int32", type = "integer"),
                                                  individualPredictionsForConsensus = structure(
                                                    list(
                                                      properties = list(
                                                        consensusPredictions = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                fileName = list(type = "string"),
                                                                method = list(type = "string"),
                                                                prediction = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/PredictionIndividualMethod"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        units = list(type = "string")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/IndividualPredictionsForConsensus"
                                                  ),
                                                  invalidClusterTable = structure(
                                                    list(
                                                      properties = list(
                                                        caption = list(type = "string"),
                                                        clusterModels = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                binary = list(type = "boolean"),
                                                                clusterID = list(type = "string"),
                                                                concordance = list(type = "string"),
                                                                descriptors = list(
                                                                  items = structure(
                                                                    list(
                                                                      properties = list(
                                                                        coefficient = list(type = "string"),
                                                                        coefficientUncertainty = list(type = "string"),
                                                                        definition = list(type = "string"),
                                                                        name = list(type = "string"),
                                                                        value = list(type = "string"),
                                                                        value_x_coefficient = list(type = "string")
                                                                      ),
                                                                      type = "object"
                                                                    ),
                                                                    specmill_id = "#/components/schemas/Descriptor"
                                                                  ),
                                                                  type = "array"
                                                                ),
                                                                messageAD = list(type = "string"),
                                                                minMaxValue = list(type = "string"),
                                                                modelEquation = list(type = "string"),
                                                                numChemicals = list(format = "int32", type = "integer"),
                                                                omitted = list(type = "boolean"),
                                                                plotImage = list(
                                                                  type = "string"
                                                                ),
                                                                predictedValue = list(type = "string"),
                                                                predictedValueLabel = list(type = "string"),
                                                                q2 = list(type = "string"),
                                                                r2 = list(type = "string"),
                                                                sensitivity = list(type = "string"),
                                                                specificity = list(type = "string"),
                                                                url = list(type = "string"),
                                                                urlDescriptors = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/ClusterModel"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        message = list(type = "string"),
                                                        units = list(type = "string")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/ClusterTable"
                                                  ),
                                                  logMolarEndpoint = list(type = "boolean"),
                                                  method = list(type = "string"),
                                                  moaTable = structure(
                                                    list(
                                                      properties = list(
                                                        moapredictions = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                clusterModelLC50 = structure(
                                                                  list(
                                                                    properties = list(
                                                                      binary = list(type = "boolean"),
                                                                      clusterID = list(type = "string"),
                                                                      concordance = list(type = "string"),
                                                                      descriptors = list(
                                                                        items = structure(
                                                                          list(
                                                                            properties = list(
                                                                              coefficient = list(type = "string"),
                                                                              coefficientUncertainty = list(
                                                                                type = "string"
                                                                              ),
                                                                              definition = list(
                                                                                type = "string"
                                                                              ),
                                                                              name = list(type = "string"),
                                                                              value = list(type = "string"),
                                                                              value_x_coefficient = list(
                                                                                type = "string"
                                                                              )
                                                                            ),
                                                                            type = "object"
                                                                          ),
                                                                          specmill_id = "#/components/schemas/Descriptor"
                                                                        ),
                                                                        type = "array"
                                                                      ),
                                                                      messageAD = list(type = "string"),
                                                                      minMaxValue = list(type = "string"),
                                                                      modelEquation = list(type = "string"),
                                                                      numChemicals = list(
                                                                        format = "int32",
                                                                        type = "integer"
                                                                      ),
                                                                      omitted = list(type = "boolean"),
                                                                      plotImage = list(type = "string"),
                                                                      predictedValue = list(type = "string"),
                                                                      predictedValueLabel = list(
                                                                        type = "string"
                                                                      ),
                                                                      q2 = list(type = "string"),
                                                                      r2 = list(type = "string"),
                                                                      sensitivity = list(type = "string"),
                                                                      specificity = list(type = "string"),
                                                                      url = list(type = "string"),
                                                                      urlDescriptors = list(type = "string")
                                                                    ),
                                                                    type = "object"
                                                                  ),
                                                                  specmill_id = "#/components/schemas/ClusterModel"
                                                                ),
                                                                clusterModelMOA = structure(
                                                                  list(
                                                                    properties = list(
                                                                      binary = list(type = "boolean"),
                                                                      clusterID = list(type = "string"),
                                                                      concordance = list(type = "string"),
                                                                      descriptors = list(
                                                                        items = structure(
                                                                          list(
                                                                            properties = list(
                                                                              coefficient = list(type = "string"),
                                                                              coefficientUncertainty = list(
                                                                                type = "string"
                                                                              ),
                                                                              definition = list(type = "string"),
                                                                              name = list(type = "string"),
                                                                              value = list(type = "string"),
                                                                              value_x_coefficient = list(
                                                                                type = "string"
                                                                              )
                                                                            ),
                                                                            type = "object"
                                                                          ),
                                                                          specmill_id = "#/components/schemas/Descriptor"
                                                                        ),
                                                                        type = "array"
                                                                      ),
                                                                      messageAD = list(type = "string"),
                                                                      minMaxValue = list(type = "string"),
                                                                      modelEquation = list(type = "string"),
                                                                      numChemicals = list(
                                                                        format = "int32",
                                                                        type = "integer"
                                                                      ),
                                                                      omitted = list(
                                                                        type = "boolean"
                                                                      ),
                                                                      plotImage = list(type = "string"),
                                                                      predictedValue = list(type = "string"),
                                                                      predictedValueLabel = list(type = "string"),
                                                                      q2 = list(type = "string"),
                                                                      r2 = list(type = "string"),
                                                                      sensitivity = list(type = "string"),
                                                                      specificity = list(type = "string"),
                                                                      url = list(type = "string"),
                                                                      urlDescriptors = list(type = "string")
                                                                    ),
                                                                    type = "object"
                                                                  ),
                                                                  specmill_id = "#/components/schemas/ClusterModel"
                                                                ),
                                                                color = list(type = "string"),
                                                                lc50Score = list(type = "string"),
                                                                lc50ScoreMsg = list(
                                                                  type = "string"
                                                                ),
                                                                moa = list(type = "string"),
                                                                moascore = list(type = "string"),
                                                                moascoreMsg = list(type = "string"),
                                                                tag = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/MOAPrediction"
                                                          ),
                                                          type = "array"
                                                        )
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/MOATable"
                                                  ),
                                                  predictionResultsPrimaryTable = structure(
                                                    list(
                                                      properties = list(
                                                        dtxcid = list(type = "string"),
                                                        endpointSources = list(
                                                          items = structure(
                                                            list(
                                                              properties = list(
                                                                sourceName = list(type = "string"),
                                                                sourceURL = list(type = "string")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/EndpointSource"
                                                          ),
                                                          type = "array"
                                                        ),
                                                        endpointSubscripted = list(type = "string"),
                                                        expCAS = list(type = "string"),
                                                        expMOA = list(type = "string"),
                                                        expSet = list(type = "string"),
                                                        expToxValMass = list(type = "string"),
                                                        expToxValue = list(type = "string"),
                                                        expToxValueEndpoint = list(type = "string"),
                                                        massUnits = list(type = "string"),
                                                        maxScoreMOA = list(type = "string"),
                                                        message = list(type = "string"),
                                                        molarLogUnits = list(type = "string"),
                                                        predMOA = list(type = "string"),
                                                        predMinMaxVal = list(type = "string"),
                                                        predMinMaxValMass = list(type = "string"),
                                                        predToxValMass = list(type = "string"),
                                                        predToxValue = list(type = "string"),
                                                        predValueEndpoint = list(type = "string"),
                                                        predictedValueNote = list(type = "string"),
                                                        predictedValueSuperscript = list(type = "string"),
                                                        source = list(type = "string"),
                                                        writePredictionInterval = list(type = "boolean")
                                                      ),
                                                      type = "object"
                                                    ),
                                                    specmill_id = "#/components/schemas/PredictionResultsPrimaryTable"
                                                  ),
                                                  reportBase = list(type = "string"),
                                                  scmin = list(format = "double", type = "number"),
                                                  similarChemicals = list(
                                                    items = structure(
                                                      list(
                                                        properties = list(
                                                          cancerStats = structure(
                                                            list(
                                                              properties = list(
                                                                concordance = list(type = "string"),
                                                                correctCount = list(format = "int32", type = "integer"),
                                                                negConcordance = list(type = "string"),
                                                                negCorrectCount = list(
                                                                  format = "int32",
                                                                  type = "integer"
                                                                ),
                                                                negPredCount = list(format = "int32", type = "integer"),
                                                                posConcordance = list(type = "string"),
                                                                posCorrectCount = list(
                                                                  format = "int32",
                                                                  type = "integer"
                                                                ),
                                                                posPredCount = list(format = "int32", type = "integer"),
                                                                predCount = list(format = "int32", type = "integer")
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/CancerStats"
                                                          ),
                                                          expVal = list(type = "string"),
                                                          externalPredChart = structure(
                                                            list(
                                                              properties = list(
                                                                externalPredChartImageSrc = list(type = "string"),
                                                                mae = list(format = "double", type = "number"),
                                                                maeentireTestSet = list(
                                                                  format = "double",
                                                                  type = "number"
                                                                )
                                                              ),
                                                              type = "object"
                                                            ),
                                                            specmill_id = "#/components/schemas/ExternalPredChart"
                                                          ),
                                                          predVal = list(type = "string"),
                                                          similarChemicalsCount = list(
                                                            format = "int32",
                                                            type = "integer"
                                                          ),
                                                          similarChemicalsList = list(
                                                            items = structure(
                                                              list(
                                                                properties = list(
                                                                  backgroundColor = list(type = "string"),
                                                                  cas = list(type = "string"),
                                                                  dsstoxcid = list(type = "string"),
                                                                  dsstoxsid = list(type = "string"),
                                                                  expVal = list(type = "string"),
                                                                  gsid = list(type = "string"),
                                                                  imageUrl = list(type = "string"),
                                                                  predVal = list(type = "string"),
                                                                  similarityCoefficient = list(type = "string")
                                                                ),
                                                                type = "object"
                                                              ),
                                                              specmill_id = "#/components/schemas/SimilarChemical"
                                                            ),
                                                            type = "array"
                                                          ),
                                                          similarChemicalsSet = list(type = "string"),
                                                          units = list(type = "string")
                                                        ),
                                                        type = "object"
                                                      ),
                                                      specmill_id = "#/components/schemas/SimilarChemicals"
                                                    ),
                                                    type = "array"
                                                  ),
                                                  smiles = list(type = "string"),
                                                  version = list(type = "string"),
                                                  webPath = list(type = "string"),
                                                  webPath2 = list(type = "string")
                                                ),
                                                type = "object"
                                              ),
                                              specmill_id = "#/components/schemas/PredictionResults"
                                            ),
                                            resultMessage = structure(
                                              list(
                                                properties = list(
                                                  code = list(type = "string"),
                                                  message = list(
                                                    type = "string"
                                                  ),
                                                  severity = list(
                                                    enum = list("INFO", "WARNING", "ERROR"),
                                                    type = "string"
                                                  )
                                                ),
                                                type = "object"
                                              ),
                                              specmill_id = "#/components/schemas/PredictionResultMessage"
                                            ),
                                            value = list(format = "double", type = "number")
                                          ),
                                          type = "object"
                                        ),
                                        specmill_id = "#/components/schemas/PredictionValue"
                                      ),
                                      type = "array"
                                    )
                                  ),
                                  type = "object"
                                ),
                                specmill_id = "#/components/schemas/PredictionEndpoint"
                              ),
                              type = "array"
                            ),
                            error = structure(
                              list(
                                properties = list(
                                  code = list(type = "string"),
                                  message = list(
                                    type = "string"
                                  ),
                                  severity = list(enum = list("INFO", "WARNING", "ERROR"), type = "string")
                                ),
                                type = "object"
                              ),
                              specmill_id = "#/components/schemas/PredictionResultMessage"
                            )
                          ),
                          type = "object"
                        ),
                        specmill_id = "#/components/schemas/PredictionChemical"
                      ),
                      type = "array"
                    ),
                    condition = list(type = "string"),
                    id = list(type = "string"),
                    predictionTime = list(type = "string"),
                    software = list(type = "string"),
                    softwareVersion = list(type = "string")
                  ),
                  type = "object"
                ),
                specmill_id = "#/components/schemas/PredictionResult"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/ExportRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/webtest/predict/export",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
