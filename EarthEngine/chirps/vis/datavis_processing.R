#' ---
#' title: 'CHIRPS: Extracción y procesamiento de datos de lluvia II'
#' lang: es
#' format:
#'   gfm:
#'     toc: true
#'     number-sections: true
#'     papersize: letter
#'     fig-width: 5
#'     fig-asp: 0.75
#'     fig-dpi: 300
#'     code-annotations: below
#'     df-print: kable
#'     wrap: none
#' 
#' execute:
#'   echo: false
#'   eval: true
#'   warning: false
#' ---
 
#| label: load-libraries_paths_data
#| output: false
Sys.setlocale(locale = "es_ES")
here::i_am("EarthEngine/chirps/vis/datavis_processing.R")
library(tidyverse)
library(sf)

path2repo <- here::here()
path2ee <- here::here("EarthEngine")
path2chirps <- here::here("EarthEngine", "chirps")
path2data <- here::here("EarthEngine", "chirps", "data")

#' ## Objetivo del script
#' 
#' Se tiene como objetivo mostrar la situación actual y pasada de las 
#' lluvias a nivel nacional, estatal y municipal.
#' 
#' Para ello se prepararán los datos con la suficiente información para 
#' retratar las estadísticas básicas en tablas, gráficas y mapas.
#' 
#' Se tiene como objetivo crear la siguiente lista:
#' 
#' - _Grid_ de _line charts_ de acumulación mensual de lluvia en milimetros de los 32 estados
#' - _Grid_ de _heat maps_ de anomalía de lluvia mensual en porcentaje de los 32 estados
#' - _Grid_ de _stripes_ de anomalía de lluvia anual en porcentaje de los 32 estados
#' - Mezcla de visualizaciones en una sola imagen:
#'   - Mapa de anomalía de lluvia del mes actual en porcentaje a nivel municipal
#'   - Mapa de anomalía de acumulación de lluvia al mes actual en porcentaje a nivel municipal
#'   - _Line chart_ de acumulación mensual de lluvia en milimetros a nivel nacional
#'   - _Stripes_ de anomalía de lluvia anual en porcentaje a nivel nacional

# - - CHIRPS - - #
# ~ Normal ~ #
# Estados
normal_ent_nac_year <- read_csv(file = here::here(path2data, "normal", "db_mex_pr_normal_ent_nac_year.csv"))
normal_ent_nac_month <- read_csv(file = here::here(path2data, "normal", "db_mex_pr_normal_ent_nac_month.csv"))

# Municipios
normal_mun_year <- read_csv(file = here::here(path2data, "normal", "db_mex_pr_normal_mun_year.csv"))
normal_mun_month <- read_csv(file = here::here(path2data, "normal", "db_mex_pr_normal_mun_month.csv"))

# ~ Precipitación ~ #
# Estados
chirps_ent_nac_year <- read_csv(file = here::here(path2data, "estados", "db_mex_pr_ent_nac_year.csv"))
chirps_ent_nac_month <- read_csv(file = here::here(path2data, "estados", "db_mex_pr_ent_nac_month.csv"))

# Municipios
chirps_mun_year <- read_csv(file = here::here(path2data, "municipios", "db_mex_pr_mun_year.csv"))
chirps_mun_month <- read_csv(file = here::here(path2data, "municipios", "db_mex_pr_mun_month.csv.bz2"))

# - - Info extra - - #
text_source <- "Climate Hazards Center InfraRed Precipitation With Station Data (CHIRPS)"
date_data_as_of <- chirps_ent_nac_month %>%
  filter(!is.na(pr_mm)) %>%
  filter(max(date_year_month) == date_year_month) %>%
  distinct(date_year_month) %>%
  pull(date_year_month)

text_recent_date_month <- date_data_as_of %>%
  format(format = "%B") %>%
  str_to_title()

text_recent_date <- date_data_as_of %>%
  format(format = "%B %Y") %>%
  str_to_title() %>%
  paste0("Datos a ", .)

#' ## 02
#' 
#' Suspendisse egestas elementum convallis. Praesent cursus dictum magna, 
#' non lacinia nibh vehicula et. Ut auctor congue tellus eu interdum. Nam 
#' non blandit odio, non pretium dolor. Vestibulum facilisis tincidunt 
#' elit, in ornare dolor pulvinar id. Vivamus id purus in nisl varius 
#' posuere at id nunc. Fusce id lacus porta, euismod tellus a, tincidunt 
#' tortor. Sed euismod turpis id urna iaculis, sit amet iaculis justo 
#' efficitur. In sollicitudin est eu venenatis tincidunt. Maecenas commodo 
#' neque tincidunt purus vulputate, et congue augue tempor. Nulla non 
#' ullamcorper arcu. Aliquam sed dolor fermentum, ornare leo sit amet, 
#' pretium turpis. In pretium posuere libero id rhoncus. Fusce vestibulum, 
#' nulla ut porttitor pretium, felis sapien pretium arcu, ac convallis 
#' massa lacus sit amet ligula.
#' 
#' ## 03
#' 
#' Interdum et malesuada fames ac ante ipsum primis in faucibus. Sed dui 
#' felis, suscipit a felis ac, venenatis ultrices erat. Nulla semper mauris 
#' eu justo vulputate vulputate. Morbi nibh eros, elementum in risus quis, 
#' malesuada commodo ante. Vivamus tincidunt dui id sollicitudin 
#' cursus. Quisque a aliquam erat. Cras lobortis suscipit massa nec 
#' vulputate.
#' 
#' ## 04
#' 
#' Fusce ultrices posuere nulla eget ultricies. Vivamus lorem nibh, varius 
#' nec commodo id, dignissim at eros. Phasellus vitae elit eros. Etiam in 
#' aliquet ex. Nullam ut posuere quam, vitae scelerisque diam. Sed porta, 
#' nibh nec imperdiet luctus, mi orci volutpat est, id laoreet elit metus 
#' ut quam. Pellentesque ut sem arcu. Suspendisse condimentum nec mi 
#' egestas imperdiet.
#' 
#' ## 05
#' 
#' Donec gravida dolor augue, eu consequat nisi bibendum eget. Etiam 
#' facilisis varius urna vitae hendrerit. Pellentesque maximus orci vitae 
#' sem fringilla, a congue nisi tristique. Phasellus molestie metus vitae 
#' tempus varius. Nulla quis ornare lectus. Nam congue sapien sed lorem 
#' efficitur ullamcorper. Ut ex turpis, pellentesque vitae augue et, tempor 
#' fermentum est.