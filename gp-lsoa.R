
# Imports ---------------------------------------------------------------------

library(tidyverse)
library(janitor)

# Constants -------------------------------------------------------------------

NUMERATORS <- c(
  "TOTAL" = "perc_here",
  "16OV" = "age_16ov_perc",
  "17OV" = "age_17ov_perc",
  "18OV" = "age_18ov_perc",
  "30_74" = "age_30_74_perc",
  "50OV" = "age_50ov_perc",
  "65OV" = "age_65ov_perc",
  "0_64" = "age_0_64_perc")

DENOMINATORS <- c(
  "TOTAL" = "patientsc",
  "16OV" = "age_16ovc",
  "17OV" = "age_17ovc",
  "18OV" = "age_18ovc",
  "30_74" = "age_30_74c",
  "50OV" = "age_50ovc",
  "65OV" = "age_65ovc",
  "0_64" = "age_0_64c")

INPUT_DIR <- "inputs"
OUTPUT_DIR <- "outputs"

# Analysis --------------------------------------------------------------------

# Load in data for gp practice patients broken down by LSOA. This file is 
# produced by the scripts in the \lsoa demographics\ folder. Column names are cleaned up for ease of use.

gp_lsoa <- read_csv(file.path(INPUT_DIR, "gp_patients_lsoa_plus_age.csv")) %>% 
  rename_at(5:20, ~ str_to_lower(.)) %>% 
  clean_names() %>% 
  rename_with(~ ifelse(str_starts(., "x"), str_replace(., "x", "age_"), .))

# Pivot total gp population and age groups for later calculations
gp_lsoa_totals <- gp_lsoa %>% 
  group_by(practice_code) %>% 
  summarise(
    total_practice_patients = sum(patientsb),
    age_16ovgp = sum(age_16ovb),
    age_17ovgp = sum(age_17ovb),
    age_18ovgp = sum(age_18ovb),
    age_30_74gp = sum(age_30_74b),
    age_50ovgp = sum(age_50ovb),
    age_65ovgp = sum(age_65ovb),
    age_0_64gp = sum(age_0_64b),
    .groups = "drop")

# Add total practice population to gp-lsoa list
gp_lsoa <- left_join(
    gp_lsoa, 
    gp_lsoa_totals,
    by = "practice_code") %>% 
  # Calculate proportion of patients for apportioning GP registers to LSOAs. 
  # See lsoademographics for calculation of these figures.
  mutate(
    perc_here = patientsb / total_practice_patients,
    age_16ov_perc = age_16ovb / age_16ovgp,
    age_17ov_perc = age_17ovb / age_17ovgp,
    age_18ov_perc = age_18ovb / age_18ovgp,
    age_30_74_perc = age_30_74b / age_30_74gp,
    age_50ov_perc = age_50ovb / age_50ovgp,
    age_65ov_perc = age_65ovb / age_65ovgp,
    age_0_64_perc = age_0_64b / age_0_64gp)

# Load prevalence data. This is an adapted version of a file from NHS Digital's QOF 2019/20 publication. See README.md for info
prevalence <- read_csv(file.path(INPUT_DIR, "prevalence_1920.csv")) %>%
  clean_names()

# Merge gp-lsoa and prevalence by practice code
gp_lsoa_prevalence <- full_join(gp_lsoa, prevalence, by="practice_code")

gp_lsoa_prevalence_groups <- gp_lsoa_prevalence %>% 
  filter(patient_list_type != "TOTAL-NOTUSED") %>% 
  group_split(patient_list_type)

gp_lsoa_prevalence_merged <- map_dfr(gp_lsoa_prevalence_groups, function(df) {
  group_name <- unique(df$patient_list_type)
  df$register_lsoa <- df[[NUMERATORS[group_name]]] * df$register
  df$list_lsoa <- df[[DENOMINATORS[group_name]]]
  df
})

# Group and summarise data by LSOA
lsoa_prevalence <- gp_lsoa_prevalence_merged %>% 
  group_by(
    lsoa_code, 
    group_code) %>% 
  summarise(
    register=sum(register_lsoa), 
    list=sum(list_lsoa), 
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_lsoa_prevalence.csv"))

# Load lookup from lsoas to other geographies
lsoa_geog_lookup <- read_csv(
    file.path(INPUT_DIR, "lsoa_geog_lookup.csv"), 
    col_types = cols(.default = "c")) %>% 
  clean_names()

lsoa_prevalence_geog <- inner_join(
  lsoa_prevalence,
  lsoa_geog_lookup,
  by = "lsoa_code")

# Group and summarise by msoa
msoa_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    msoa_code,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list)

# Load and add msoa names
msoa_names <- read_csv(
  "https://visual.parliament.uk/msoanames/static/MSOA-Names-Latest.csv")

msoa_prevalence_names <- left_join(
  msoa_prevalence,
  msoa_names, 
  by = c("msoa_code" = "msoa11cd")) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_msoa_prevalence.csv"))

# Group and summarise by constituency
pcon_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    pcon_code,
    pcon_name,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_pcon_prevalence.csv"))

# Group and summarise by lower tier local authority
lad_prevalence <- lsoa_prevalence_geog %>%  
  group_by(
    lad_code,
    lad_name,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_lad_prevalence.csv"))

# Group and summarise by imd_income decile
imdincome_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    imd_income,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_imdincome_prevalence.csv"))

# Group and summarise by imd_overall decile
imdincome_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    imd_overall,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_imd_prevalence.csv"))

# Group and summarise by region
region_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    region,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>%
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_region_prevalence.csv"))

# Group and summarise by imd_income decile and region
imdincome_region_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    region,
    imd_income,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_imdincome_region_prevalence.csv"))

# Group and summarise by imd_income decile and region
imdincome_region_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    region,
    imd_overall,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_imd_region_prevalence.csv"))


# Group and summarise by county/conurbation
county_prevalence <- lsoa_prevalence_geog %>% 
  group_by(
    county_conurbation,
    group_code) %>% 
  summarise(
    register=sum(register),
    list=sum(list),
    .groups = "drop") %>% 
  mutate(prevalence = register / list) %>% 
  write_csv(file.path(OUTPUT_DIR, "output_county_prevalence.csv"))
