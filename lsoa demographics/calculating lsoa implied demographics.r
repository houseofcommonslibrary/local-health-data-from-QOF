library(tidyverse)

# This file is used for comparing calculating "implied" demographics for LSOAs 
# based on the patient age breakdown of the GP practices serving the LSOA. It's used
# only in the detection of LSOAs where the resident population may differ from the 
# GP registered population and not used directly in producing the prevalence estimates.

#load source data on GP patients by LSOA from NHS Digital
gp_lsoa <- read_csv('gp-patients-lsoa-apr20.csv')

#filter out records without an LSOA
gp_lsoa2 <- filter(gp_lsoa,LSOA_CODE!="NO2011")
rm(gp_lsoa)

#pivot total patients at each GP practice
gp_lsoa_group <- group_by(gp_lsoa2,PRACTICE_CODE)
gp_patients <-summarise(gp_lsoa_group,total_practice_patients=sum(patients))

#add total patients to original gp-lsoa list
gp_lsoa3 <- merge(gp_lsoa2,gp_patients)
rm(gp_lsoa2)

#calculate proportion of patients in each LSOA
gp_lsoa3$perc_here <- (gp_lsoa3$patients / gp_lsoa3$total_practice_patients)

#load gp practice demographics
gp_demographics <- read_csv('gp_demographics.csv')

#merge gp-lsoa and demographics
gp_demographics_merged<- merge(gp_lsoa3,gp_demographics,all.x=TRUE,all.y=TRUE)

#add new columns for each age group
gp_demographics_merged$`age_all` <- (gp_demographics_merged$`patients` * gp_demographics_merged$`AgeAll`)

gp_demographics_merged$`age_m` <- (gp_demographics_merged$`patients` * gp_demographics_merged$`AgeMale`)

gp_demographics_merged$`age_f` <- (gp_demographics_merged$`patients` * gp_demographics_merged$`AgeFemale`)

gp_demographics_merged$`males` <- 
(gp_demographics_merged$`patients` *
gp_demographics_merged$`Percent_male`)

gp_demographics_merged$`16pop` <-
(gp_demographics_merged$`patients` *
gp_demographics_merged$`16perc`)

gp_demographics_merged$`17pop` <-
(gp_demographics_merged$`patients` *
gp_demographics_merged$`17perc`)

gp_demographics_merged$`18pop` <-
(gp_demographics_merged$patients *
gp_demographics_merged$`18perc`)

gp_demographics_merged$`3074pop` <-
(gp_demographics_merged$patients *
gp_demographics_merged$`30_74perc`)

gp_demographics_merged$`50pop` <-
(gp_demographics_merged$`patients` *
gp_demographics_merged$`50perc`)

gp_demographics_merged$`0_64pop` <-
(gp_demographics_merged$`patients` *
gp_demographics_merged$`0_64perc`)

gp_demographics_merged$`65pop` <-
(gp_demographics_merged$`patients` *
gp_demographics_merged$`65perc`)

#group by LSOA

lsoa_gp_pop_group <- group_by(gp_demographics_merged,LSOA_CODE)

lsoa_gp_pop <- summarise(lsoa_gp_pop_group,
age_all=sum(age_all),
age_m=sum(age_m),
age_f=sum(age_f),
males=sum(males),
`16pop`=sum(`16pop`),
`17pop`=sum(`17pop`),
`18pop`=sum(`18pop`),
`3074pop`=sum(`3074pop`),
`50pop`=sum(`50pop`),
`0_64pop`=sum(`0_64pop`),
`65pop`=sum(`65pop`),
`patients`=sum(`patients`))

#average ages
lsoa_gp_pop$`ave_age_all` <- (lsoa_gp_pop$`age_all` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`ave_age_m` <- (lsoa_gp_pop$`age_m` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`ave_age_f` <- (lsoa_gp_pop$`age_f` / lsoa_gp_pop$`patients`)

#age groups
lsoa_gp_pop$`16perc` <- (lsoa_gp_pop$`16pop` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`17perc` <- (lsoa_gp_pop$`17pop` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`18perc` <- (lsoa_gp_pop$`18pop` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`3074perc` <- (lsoa_gp_pop$`3074pop` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`50perc` <- (lsoa_gp_pop$`50pop` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`65perc` <- (lsoa_gp_pop$`65pop` / lsoa_gp_pop$`patients`)
lsoa_gp_pop$`0_64perc` <- (lsoa_gp_pop$`0_64pop` / lsoa_gp_pop$`patients`)

write_csv(lsoa_gp_pop,'lsoa_gp_pop.csv')