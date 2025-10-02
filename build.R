#Adding new testing chemicals

build_testing_chemicals(chems = c(

))

#Load latest data 
#pt <- readRDS("C:\\Users\\STHIMONS\\Documents\\curation\\final\\pt.RDS")
#usethis::use_data(pt, overwrite = TRUE)

run_verbose(TRUE)

#Checks documentation
devtools::document()

#Merge branches here! 

usethis::use_version(
	which = 'minor',
	push = FALSE
)

library(autonewsmd)

an <- autonewsmd$new(repo_name = "ComptoxR", repo_path = here::here())
an$generate()

# an$repo_list <- an$repo_list %>% 
# 	map(., 'commits') %>%
# 	map(., function(df){
# 		df %>% mutate(across(c(summary, message), ~str_replace(.x, pattern = "^-", replacement = "") %>% str_squish()))
# })
	
an$write(force = TRUE)

rm(an)



#Builds Windows ZIP
devtools::build(binary = TRUE)


#Clean, build, and install, reload
#Cntrl + Shift + B
devtools::install(pkg = ".", dependencies = TRUE, reload = TRUE)
