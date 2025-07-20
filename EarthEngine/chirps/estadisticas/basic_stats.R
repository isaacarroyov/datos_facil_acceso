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
 
#| label: setworkingdir
#| eval: false
# ~ NOTE ~ #
# 
# Se puede observar que se cambia el directorio de trabajo a la carpeta 
# **`/EarthEngine/chirps/scripts`** para después agregar `/../../..` en la 
# variable **`path2main`**. Este cambio se hace para que al renderizar, el 
# código se pueda ejecutar correctamente, ya que el archivo toma como 
# directorio de trabajo la carpeta en la que se encuentra el script en el 
# que se esta haciendo el código.
setwd("./EarthEngine/chirps/estadisticas")

#'

#| label: load-libraries_paths_data
#| output: false
Sys.setlocale(locale = "es_ES")
library(tidyverse)
library(ggtext)
library(scales)
library(ggrepel)
library(MetBrewer)
library(sf)

path2main <- paste0(getwd(), "/../../..")
path2ee <- paste0(path2main, "/EarthEngine")
path2chirps <- paste0(path2ee, "/chirps")
path2data <- paste0(path2chirps, "/data")

text_source_chirps <- paste("Climate Hazards Center InfraRed",
                            "Precipitation With Station Data (CHIPRS)")

# TODO: Agregar en el procesamiento de datos, las estadísticas de la nación

# - - CHIRPS - - #
# ~ Valores normales ~ #
# Estados
normal_ent_year <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_ent_year.csv"))

normal_ent_month <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_ent_month.csv"))

# Municipios
normal_mun_year <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_mun_year.csv"))

normal_mun_month <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_mun_month.csv"))

# ~ Estados ~ #
chirps_ent_year <- read_csv(
    file = paste0(path2data,
                  "/estados",
                  "/db_pr_ent_year.csv"))

chirps_ent_month <- read_csv(
    file = paste0(path2data,
                  "/estados",
                  "/db_pr_ent_month.csv"))

# ~ Municipios ~ #
chirps_mun_year <- read_csv(
    file = paste0(path2data,
                  "/municipios",
                  "/db_pr_mun_year.csv"))

chirps_mun_month <- read_csv(
    file = paste0(path2data,
                  "/municipios",
                  "/db_pr_mun_month.csv.bz2"))

text_recent_date <- chirps_ent_month %>%
  filter(!is.na(pr_mm)) %>%
  filter(max(date_year_month) == date_year_month) %>%
  distinct(date_year_month) %>%
  pull(date_year_month) %>%
  format(format = "%B %Y") %>%
  str_to_title() %>%
  paste0("Datos a ", .)

# TODO: Datos a visualizar
# 
# Crear un conjunto de datos con los años 2011-presente + Normal
# para los 32 estados + Nacional con las métricas:
#   * pr_mm -> grafica de lineas por region (mes)
#   * cumsum_pr_mm -> grafica de lineas por region (mes)
#   * anomaly_pr_prop -> Heatmaps por region (mes y año) + mapas a nivel municipal (mes y año)
#   * cumsum_anomaly_pr_prop -> Tabla de información para generar textos (mes)

#' ## 01
#' 
#' Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean eu purus 
#' mattis, ultrices enim eget, efficitur nisl. Nulla ipsum purus, efficitur 
#' non dignissim eget, consectetur a erat. Vestibulum ante ipsum primis in 
#' faucibus orci luctus et ultrices posuere cubilia curae; Vivamus feugiat 
#' finibus urna, vel fermentum tortor sagittis eu. Vestibulum ultrices, 
#' nunc quis mollis fermentum, nibh odio finibus ante, at scelerisque 
#' turpis neque sed odio. Praesent ullamcorper velit dui, sed ultricies ex 
#' eleifend id. Fusce molestie massa tempus odio ultrices, quis dignissim 
#' libero maximus. Proin posuere vestibulum eros, at aliquam tellus 
#' convallis in. Nunc a dictum mauris. Proin tincidunt erat erat, vitae 
#' vulputate mi placerat vitae. Aenean scelerisque, turpis a varius congue, 
#' diam mi consectetur metus, eu pulvinar dui nisl nec neque.
#' 
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