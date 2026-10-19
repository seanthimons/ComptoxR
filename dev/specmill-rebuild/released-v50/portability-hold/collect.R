loadNamespace('specmill',lib.loc=path.expand('~/.cache/comptoxr-specmill-finish/release50-verification/library'))
base<-path.expand('~/.cache/comptoxr-specmill-finish/release50-verification/portability');root<-file.path(base,'original');moved<-file.path(base,'relocated')
err<-tryCatch(specmill::generate_client(validation=TRUE,moved,config='specmill.yml',mode='check'),error=identity)
stopifnot(inherits(err,'error'),grepl('.specmill/manifest.json',conditionMessage(err),fixed=TRUE))
plan<-specmill::generate_client(validation=TRUE,moved,config='specmill.yml',mode='plan');saveRDS(plan,file.path(base,'relocated-plan.rds'))
before<-jsonlite::read_json(file.path(moved,'.specmill/manifest.json'));changes<-Filter(function(file)file$action!='unchanged',plan$files);print(changes)
specmill::generate_client(validation=TRUE,moved,config='specmill.yml',mode='apply');after<-jsonlite::read_json(file.path(moved,'.specmill/manifest.json'))
stopifnot(length(changes)==1L,changes[[1]]$file=='.specmill/manifest.json',changes[[1]]$action=='write')
before_proof<-before$files[['R/render.R']]$response_sources;after_proof<-after$files[['R/render.R']]$response_sources
# Compare all metadata after removing only the new response source provenance.
before$files[['R/render.R']]$response_sources<-NULL;after$files[['R/render.R']]$response_sources<-NULL;stopifnot(identical(before,after))
jsonlite::write_json(list(version='0.1.50',source=packageDescription('specmill')[['Config/specmill/source-commit']],original=root,relocated=moved,check_error=conditionMessage(err),actions=changes,only_response_sources_differs=TRUE,before=before_proof,after=after_proof),file.path(base,'results.json'),pretty=TRUE,auto_unbox=TRUE)
cat('PASS reproduced manifest-only relocation failure caused only by response_sources absolute paths\n')
