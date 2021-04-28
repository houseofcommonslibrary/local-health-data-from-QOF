# Local health conditions prevalence estimates based on QOF

This project contains underlying data and R code for estimating the prevalence of health conditions at LSOA level in England, based on GP practice-level data published by NHS Digital.

The results, including maps, are available to browse on an interactive dashboard here on the [House of Commons Library website](https://commonslibrary.parliament.uk/constituency-data-how-healthy-is-your-area/). This github project provides more information on how the calculations were performed, along with the underlying data and code.

The results of this analysis give **modelled estimates** of prevalence for LSOAs and larger geographies such as constituencies. They are not counts or precise figures.

Note that in order to run the code here you will need to download the following file and place it in the 'input' folder. This file was too large to upload to github:

https://data.parliament.uk/resources/constituencystatistics/healthmaps/2021/gp_patients_lsoa_plus_age.csv

Alternatively you can obtain this file by running the 'adding_lsoa_demographics' R script in the 'lsoa demographics' folder.

## Overview
NHS Digital publishes annual results from the [Quality and Outcomes Framework (QOF)](https://digital.nhs.uk/data-and-information/publications/statistical/quality-and-outcomes-framework-achievement-prevalence-and-exceptions-data). This publication includes data for each GP practice in England about the prevalence of 21 health conditions among their registered patients. Our  analysis joins QOF practice-level prevalence data with further [NHS Digital data on patient residence](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/april-2020) - specifically, on the small areas ([LSOAs](https://www.ons.gov.uk/methodology/geography/ukgeographies/censusgeography)) where patients registered to each practice live. In short: for each GP practice, health condition prevalence numbers from QOF are apportioned to LSOAs based on the percentage of that practice's patients living in each LSOA. This results in LSOA-level estimates for the prevalence of health conditions which are then aggregated to other geographies. Further details of this analsyis are explained below.

## Prevalence data
The practice-level prevalence data used here is from the [2019/20 QOF publication](https://digital.nhs.uk/data-and-information/publications/statistical/quality-and-outcomes-framework-achievement-prevalence-and-exceptions-data/2019-20). A small proportion of GP practices were missing from this dataset, either because they did not submit data or because their data did not pass validation. For ten of these practices, prevalence data was available from the (2018/19 QOF release)[https://digital.nhs.uk/data-and-information/publications/statistical/quality-and-outcomes-framework-achievement-prevalence-and-exceptions-data/2018-19-pas]. Their 2018-19 data is used for this analysis, but the numerators are scaled to match changes in the patient list size between April 2019 and April 2020. These practices are labelled in the "/inputs/prevalence_1920.csv" data file (field: STATUS).

Two practices where 2019/20 data was available had their data altered for this analysis - F85002 (Forest Road Group Practice, Enfield) and Y03051 (Station Plaza Practice, Hastings). These practices reported unusual prevalence data in 2019-20, with reported prevalence for some conditions close to or above 100%. The analysis here uses their 2018-19 prevalence figures adjusted to their 2019/20 patient list sizes.

After these adjustments are made, there remain 69 open GP practices with no available data. These account for 16,355 patients (0.03% of the total). Even when taking this missing data into account, all LSOAs in England have data covering over 75% of resident patients, and all but six LSOAs have coverage over 90% of patients.

## GP practice patients by LSOA
Data apportioning patients to LSOAs is published quarterly as part of the [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/april-2020) publication. The data records, for each GP practice, the number of registered patients who are resident in different LSOAs. This analysis uses the April 2020 data. 

0.02% of patients registered with English GP practices (13,937) did not have an LSOA of residence recorded in April 2020. These are not included in the analysis - which is to say, the analysis assumes that patients with missing LSOAs have the same geographical distribution as those with recorded LSOAs. 

0.06% of patients registered with  English GP practices (35,246) were resident in Wales in April 2020. This means that some Welsh LSOAs are included in the output data. Note that since this data only includes patients registered at English GP practices, data for Welsh LSOAs does not represent the whole population and is not included in the [dashboard](https://commonslibrary.parliament.uk/constituency-data-how-healthy-is-your-area/).

Some patients resident in England will also be registered at Welsh GP practices. This can't be directly measured by the data used here, but it can be observed indirectly through lower-than-expected numbers of patients in LSOAs near the Welsh border (e.g. in the western parts of Forest of Dean district in Gloucestershire county). 

## Age groups and LSOA demographics
QOF registers for some health conditions are measured in respect of particular age groups rather than the whole population. For instance, the diabetes register measures the number of people *aged 17+* with diabetes, and depression is measured among those *aged 18+*. On the other hand, some conditions are measured in people of all ages (e.g. dementia, asthma, and hypertension).

QOF contains information for each practice on the number of registered patients in each of the relevant age categories (17+, 18+, all ages, etc). But the published data on GP patients by LSOA does not record information on patients by age group. For example, we know that the GP practice A81001 (The Densham Surgery in Stockton-on-Tees) had 4,111 patients in April 2020 and that 3,258 of them were aged 18+. We also know that we know that 146 of this practice's patients lived in LSOA [E01012225](https://www.doogal.co.uk/LSOA.php?code=E01012225) (a small area in the south west of Stockton). But we do not know how many of the 146 patients living in that LSOA were aged 18+.

This affects the analysis: if we apportion a practice's QOF registers to LSOAs only based on the proportion of the *all-ages* population living in each LSOA, then we risk obscuring age differences between different areas served by that practice. For example, some areas have a larger proportion of the population aged 18+ than others.

To account for this, the analysis integrates some information on LSOA demographics from [ONS annual mid-year population estimates](https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates) - in particular, LSOA population in each age group (percentage breakdown) from mid-2019. For example, in the LSOA E01012225 mentioned above, 84.3% of the population was estimated to be aged 18 or above. 

The integration of this data into the analysis takes place in the "/lsoa demographics/lsoa_demographics.r" file in the relevant sub-folder. For each practice-LSOA pair, We model the number of registered patients that are in each age group using ONS population estimates. We then adjust these LSOA age-specific figures for each practice based on published data about the *total* number of people in each age group registered with the practice. In other words, LSOA age estimates based on ONS figures are scaled to ensure that they match the actual practice-wide data from QOF.

This calculation results in modelled estimates of patients per LSOA by age group which are not round numbers (i.e. they have decimal places). These numbers are not rounded in the data files, and helps to emphasise that the analysis provides modelled estimates and not exact counts.

## Differences between the GP-registered population and the resident population
Using [ONS population estimates](https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates) in our analysis implicitly assumes that the resident population of an area has similar demographics to the GP-registered population of that area. In most areas it is likely that there are only small differences between the two. However, in a minority of areas there are substantial and important differences, usually when a portion of the population is not registered with a GP. Some commons types of areas are:

-**Military**: areas containing military facilities. Residents will typically not be registered with an NHS GP in the area but are counted in population estimates. (Example: LSOA E01027771 near Catterick Garrison, North Yorkshire. LSOA population estimate: 3,965. GP registered patients in the LSOA: 1,086). 

-**Prisons**: areas containing prisons. Inmates will typically not be registered with an NHS GP in the area but are counted in population estimates. (Example: LSOA E01007557 near Doncaster, which includes HMP Hatfield Lakes and HMP Moorland. Population estimate: 3,187. GP patients: 1,057.)

-**Students**: areas with large student populations. This manifests in more than one way. In some student areas, GP population estimates are much larger than ONS population estimates (perhaps indicating students not being counted in population estimates) while in some areas the opposite is the case (perhaps indicating students not registered with local GPs). (Example: LSOA E01033262 in Sheffield. Population estimate: 4,240. GP patients: 2,668).

-**City centres**: many city centre areas have lower GP registers than resident populations, perhaps due to their tendency to contain residents in demographic groups less likely to register with a GP. (Example: LSOA E01033653 in Manchester. Population estimate: 3,468. GP patients: 2,196).

Some of these have a large effect on the demographics of an area. For instance, in some areas with prisons, the population is overwhelmingly male and young, but this does not match with local GP practices because these residents are not registered with local GPs. So using ONS demographic data for these areas would inject error into the analysis of QOF data described above.

To account for this, the "lsoa_demographics" stage described previously substitutes demographics for problematic LSOAs (those with an obvious mismatch between resident population and GP population) with other LSOAs:  either with a neighbouring LSOA, or for figures representing the GP practice average.

This substitution process focuses on comparing NHS Digtial and ONS data to LSOAs where the GP registered population is notably lower than the resident population - i.e. those where a substantial proportion of the resident population is not registered with a GP. On a case-by-case basis these are "paired" with a neighbouring LSOA and assigned that LSOA's demographics for the "lsoa_demographics" stage. In some cases the average demographics for GP practice registers in the area are used instead.

You can see these adjustments in the "/lsoa demographics/lsoa_demographics.csv" file, in the fields *Pair_or_adjustment* and *Reason_or_note*. In addition to the area types given above, a small number of LSOAs with residential boarding schools are adjusted.

## Dividing prevalence numerators between LSOAs
The analysis described so far apportions GP prevalence registers between LSOAs only on the basis of patient numbers. This is clearly a crude approach, because it doesn't account for any differences in morbidity between LSOAs served by the same GP practice. 

The analysis makes one small adjustment to account for this using 2011 census data. LSOAs are assigned a weighting between 0.9 and 1.1 based on the proportion of the population that had a long term health problem or disability that limits their day to day activities. This is one indicator of variations in morbidity between LSOAs, though we do not know how it applies to each of the individual conditions in QOF.

This weighting is applied to patient numbers before apportioning prevalence numerators for GP practices between LSOAs. So an LSOA with a higher proportion of the population having a long term health problem than others in the area would (all other things being equal) be apportioned a larger proportion of a GP practice's prevalence numerators in the analysis.

This adjustment only has an effect in areas where a single GP practice serves several demographically different LSOAs. If a GP practice serves only areas with a high proportion of people long term health conditions, the adjustment has no effect. But if it serves some areas with a high proportion and some areas with a low proportion, the assumed division of prevalence figures between LSOAs will be different than it otherwise would have been.

The "pairing" system described in the previous section is used again here for LSOAs where the resident population and the GP-registered population differs (e.g. places with military facilities).

Some health conditions are related to age. However, we do not make adjustment for the age distributions of different conditions, because the source data from QOF does not include information on the age breakdown of conditions. For example, we do not know how many of the 5.6 million GP patients with depression are aged 20-24, or 65-69, etc. This means that we cannot further infer whether some LSOAs should be apportioned more or less cases of depression based on their fine-grained age demographics.

The except to this is dementia. NHS Digital [publishes a breakdown](https://digital.nhs.uk/data-and-information/publications/statistical/recorded-dementia-diagnoses) of GP dementia patients between ages 65+ and ages 0-64 at national level: almost 97% of people diagnosed with dementia are aged 65 or above. The analysis uses this figure to further refine the distribution of dementia cases between LSOAs, based on the proportion of the population aged 65+ in each LSOA.

The calculation stages described above result in two modelled sets of patient figures for each LSOA-GP pair, both broken down by age group categories relating to QOF figures (e.g. 16+, 30-74). The first set is adjusted using census long-term-condition data, and is used for apportioning the numerators from QOF. The second set is not adjusted in this way - this serves as the denominators for calculating LSOA prevalence. In other words - the census data is only used for adjusting the way that *health conditions* are divided between areas served by the same GP, and not in adjusting the way that *patients* are divided between those areas.

## Aggregating
The LSOA data is aggregated to larger geographies to produce the other output files (e.g. local authority, region, constituency). For constituencies, a best-fit lookup is used based on [population-weighted centroids](https://geoportal.statistics.gov.uk/datasets/b7c49538f0464f748dd7137247bbc41c_0?geometry=-23.033%2C50.531%2C18.781%2C55.170), because LSOA boundaries do not match exactly with constituency boundaries. The full set of lookups is contained in the 'inputs/lsoa_geog_lookup.csv' file. Alongside ONS geography lookups, this includes data from MHCLG's [English indices of deprivation 2019](https://www.gov.uk/government/statistics/english-indices-of-deprivation-2019).

## Summing up
It's important to reiterate that the results of this analysis are **modelled estimates** of local health condition prevalence. Based on the data available, it's not possible to say for sure how many people in a given LSOA or constituency have certain health conditions. But by apportioning GP practice-level data on prevalence to the areas served by those practices as described above we can obtain modelled estimates.

Because the bulk of this data covers 2019/20, it's possible that the data is affected by the early stages of the COVID-19 pandemic. In addition, differences between areas may reflect differences in how GPs record and measure information about their patients, rather than genuine differences in the prevalence of the conditions shown.

