# TODO: Documentar como GFM
# TODO: Cambiar nombres de este archivo y en python

library(tidyverse)

path2main <- getwd()
path2gobmexicano <- paste0(path2main, "/Gobierno-Mexicano")
path2msmdata <- paste0(path2gobmexicano, "/MSM/datos")

db <- openxlsx::read.xlsx(
    xlsxFile = paste0("https://smn.conagua.gob.mx/tools/RESOURCES/",
                      "Monitor%20de%20Sequia%20en%20Mexico/",
                      "MunicipiosSequia.xlsx")) %>%
  as_tibble() %>%
  janitor::clean_names() %>%
  mutate(across(dplyr::starts_with("x"), as.character)) %>%
  pivot_longer(
    cols = all_of(starts_with("x")),
    names_to = "full_date",
    values_to = "sequia") %>%
  mutate(
    full_date = str_remove(
      string = full_date,
      pattern = "x"),
    full_date = openxlsx::convertToDate(full_date)) %>%
  replace_na(list(sequia = "Sin sequia")) %>%
  filter(!(year(full_date) == 2003 & month(full_date) == 8)) %>%
  filter(!(year(full_date) == 2004 & month(full_date) == 2))

write_csv(
  x = db,
  file = paste0(path2msmdata, "/sequia_municipios.csv.bz2"),
  na = "")
