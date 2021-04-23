library(tidyverse)

#This files takes NHS Digital data on GP practice populations by LSOA, and joins it with 
#ONS demographic data to produce estimates of the age breakdown of each GP practice population
#by LSOA

#Load LSOA age demographics - ONS population estimates with adjustments as described in README.md 
lsoa_demographics <- read_csv('lsoa_demographics.csv')

#load NHS Digital data on GP patients broken down by LSOA
gp_lsoa <- read_csv('gp-patients-lsoa-apr20.csv')

#Load GP practice age demographics from NHS Digital
gp_age <- read_csv('gp-by-age.csv')

#filter out patients without an LSOA recorded. We will adjust to compensate for this later
gp_lsoa2 <- filter(gp_lsoa,LSOA_CODE!="NO2011")
rm(gp_lsoa)

#filter out GP practices that we aren't using in the prevalence calculation because we don't have QOF data for them. See README.md
gp_lsoa3 <- filter(gp_lsoa2,DataStatus!="No data")
rm(gp_lsoa2)

#Merge LSOA demographics with the resulting filtered GP to LSOA file by LSOA code
lsoa_gp_demographics <- merge(gp_lsoa3,lsoa_demographics,all.x=TRUE)

#impute the age breakdown of GP patients by LSOA, based on LSOA demographics (adjusted in some cases - see notes)
lsoa_gp_demographics$`16a` <- (lsoa_gp_demographics$`16OV` * lsoa_gp_demographics$`patients`)
lsoa_gp_demographics$`17a` <- (lsoa_gp_demographics$`17OV` * lsoa_gp_demographics$`patients`)
lsoa_gp_demographics$`18a` <- (lsoa_gp_demographics$`18OV` * lsoa_gp_demographics$`patients`)
lsoa_gp_demographics$`3074a` <- (lsoa_gp_demographics$`30_74` * lsoa_gp_demographics$`patients`)
lsoa_gp_demographics$`50a` <- (lsoa_gp_demographics$`50OV` * lsoa_gp_demographics$`patients`)
lsoa_gp_demographics$`65a` <- (lsoa_gp_demographics$`65OV` * lsoa_gp_demographics$`patients`)
lsoa_gp_demographics$`064a` <- (lsoa_gp_demographics$`0_64` * lsoa_gp_demographics$`patients`)

#add small adjustment for census data on long term health conditions. See README.md
lsoa_gp_demographics$`patientsd` <- (lsoa_gp_demographics$`patients` * lsoa_gp_demographics$census_health_adjustment)
lsoa_gp_demographics$`16d` <- (lsoa_gp_demographics$`16a` * lsoa_gp_demographics$census_health_adjustment)
lsoa_gp_demographics$`17d` <- (lsoa_gp_demographics$`17a` * lsoa_gp_demographics$census_health_adjustment)
lsoa_gp_demographics$`18d` <- (lsoa_gp_demographics$`18a` * lsoa_gp_demographics$census_health_adjustment)
lsoa_gp_demographics$`3074d` <- (lsoa_gp_demographics$`3074a` * lsoa_gp_demographics$census_health_adjustment)
lsoa_gp_demographics$`50d` <- (lsoa_gp_demographics$`50a` * lsoa_gp_demographics$census_health_adjustment)
lsoa_gp_demographics$`65d` <- (lsoa_gp_demographics$`65a` * lsoa_gp_demographics$census_health_adjustment)
lsoa_gp_demographics$`064d` <- (lsoa_gp_demographics$`064a` * lsoa_gp_demographics$census_health_adjustment)

#prepare a comparison between the imputed total GP population by age group based on LSOAs, and the actual 
gp_age_imputed <- group_by(lsoa_gp_demographics,PRACTICE_CODE)
gp_age_imputed2 <-summarise(gp_age_imputed,patientsa=sum(patients),patientsd=sum(patientsd),`16a`=sum(`16a`),`17a`=sum(`17a`),`18a`=sum(`18a`),`3074a`=sum(`3074a`),`50a`=sum(`50a`),`65a`=sum(`65a`),`064a`=sum(`064a`),`16d`=sum(`16d`),`17d`=sum(`17d`),`18d`=sum(`18d`),`3074d`=sum(`3074d`),`50d`=sum(`50d`),`65d`=sum(`65d`),`064d`=sum(`064d`))
gp_age_comparison <- merge (gp_age,gp_age_imputed2,all.x=TRUE,all.y=TRUE)

#calculate the ratio between imputed totals and actual totals. We do "TOTAL" too, in order to distribute the patients who had no LSOA recorded
#we do this twice - once for the versions before IMD adjustment, and once after. They will be used for the denominator and numerator respectively in the final prevalence calculation
gp_age_comparison$totalratioa <- (gp_age_comparison$`TOTAL` / gp_age_comparison$`patientsa`)
gp_age_comparison$`16ratioa` <- (gp_age_comparison$`16OV` / gp_age_comparison$`16a`)
gp_age_comparison$`17ratioa` <- (gp_age_comparison$`17OV` / gp_age_comparison$`17a`)
gp_age_comparison$`18ratioa` <- (gp_age_comparison$`18OV` / gp_age_comparison$`18a`)
gp_age_comparison$`3074ratioa` <- (gp_age_comparison$`30_74` / gp_age_comparison$`3074a`)
gp_age_comparison$`50ratioa` <- (gp_age_comparison$`50OV` / gp_age_comparison$`50a`)
gp_age_comparison$`65ratioa` <- (gp_age_comparison$`65OV` / gp_age_comparison$`65a`)
gp_age_comparison$`064ratioa` <- (gp_age_comparison$`0_64` / gp_age_comparison$`064a`)

gp_age_comparison$totalratiod <- (gp_age_comparison$`TOTAL` / gp_age_comparison$`patientsd`)
gp_age_comparison$`16ratiod` <- (gp_age_comparison$`16OV` / gp_age_comparison$`16d`)
gp_age_comparison$`17ratiod` <- (gp_age_comparison$`17OV` / gp_age_comparison$`17d`)
gp_age_comparison$`18ratiod` <- (gp_age_comparison$`18OV` / gp_age_comparison$`18d`)
gp_age_comparison$`3074ratiod` <- (gp_age_comparison$`30_74` / gp_age_comparison$`3074d`)
gp_age_comparison$`50ratiod` <- (gp_age_comparison$`50OV` / gp_age_comparison$`50d`)
gp_age_comparison$`65ratiod` <- (gp_age_comparison$`65OV` / gp_age_comparison$`65d`)
gp_age_comparison$`064ratiod` <- (gp_age_comparison$`0_64` / gp_age_comparison$`064d`)

lsoa_age_correction <- merge(x=lsoa_gp_demographics, y= gp_age_comparison[ , c("PRACTICE_CODE","totalratioa","16ratioa","17ratioa","18ratioa","3074ratioa","50ratioa","65ratioa","064ratioa","totalratiod","16ratiod","17ratiod","18ratiod","3074ratiod","50ratiod","65ratiod","064ratiod")], all.x=TRUE,all.y=TRUE)

#calculate adjusted GP to LSOA population totals using the above ratios. 
#After these adjustments, the components will now sum to match the actual 'GP practice by age' data
lsoa_age_correction$`patientsb` <- (lsoa_age_correction$`patientsd` * lsoa_age_correction$`totalratiod`)
lsoa_age_correction$`16OVb` <- (lsoa_age_correction$`16d` * lsoa_age_correction$`16ratiod`)
lsoa_age_correction$`17OVb` <- (lsoa_age_correction$`17d` * lsoa_age_correction$`17ratiod`)
lsoa_age_correction$`18OVb` <- (lsoa_age_correction$`18d` * lsoa_age_correction$`18ratiod`)
lsoa_age_correction$`30_74b` <- (lsoa_age_correction$`3074d` * lsoa_age_correction$`3074ratiod`)
lsoa_age_correction$`50OVb` <- (lsoa_age_correction$`50d` * lsoa_age_correction$`50ratiod`)
lsoa_age_correction$`65OVb` <- (lsoa_age_correction$`65d` * lsoa_age_correction$`65ratiod`)
lsoa_age_correction$`0_64b` <- (lsoa_age_correction$`064d` * lsoa_age_correction$`064ratiod`)

#same but for the denominators (pre IMD adjustment)
lsoa_age_correction$`patientsc` <- (lsoa_age_correction$`patients` * lsoa_age_correction$`totalratioa`)
lsoa_age_correction$`16OVc` <- (lsoa_age_correction$`16a` * lsoa_age_correction$`16ratioa`)
lsoa_age_correction$`17OVc` <- (lsoa_age_correction$`17a` * lsoa_age_correction$`17ratioa`)
lsoa_age_correction$`18OVc` <- (lsoa_age_correction$`18a` * lsoa_age_correction$`18ratioa`)
lsoa_age_correction$`30_74c` <- (lsoa_age_correction$`3074a` * lsoa_age_correction$`3074ratioa`)
lsoa_age_correction$`50OVc` <- (lsoa_age_correction$`50a` * lsoa_age_correction$`50ratioa`)
lsoa_age_correction$`65OVc` <- (lsoa_age_correction$`65a` * lsoa_age_correction$`65ratioa`)
lsoa_age_correction$`0_64c` <- (lsoa_age_correction$`064a` * lsoa_age_correction$`064ratioa`)

lsoa_age_correction_final <- lsoa_age_correction[ , c("PRACTICE_CODE","LSOA_CODE","patients","DataStatus","patientsb","16OVb","17OVb","18OVb","30_74b","50OVb","65OVb","0_64b","patientsc","16OVc","17OVc","18OVc","30_74c","50OVc","65OVc","0_64c")]

#this CSV is used in the 'inputs' folder by GP-LSOA.R in the root folder of the project
write_csv(lsoa_age_correction_final,'gp_patients_lsoa_plus_age.csv')
