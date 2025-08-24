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
#' 
#' > [!NOTE] 
#' > 
#' > Por el momento, todas las visualizaciones seran exportadas como 
#' imágenes estáticas. Conforme el proyecto avance, se includirán las 
#' versiones interactivas, sea con una librería de JavaScript o alguna 
#' herramienta de visualización de datos como Flourish.

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

#' ## _Grid_ de _line charts_: Acumulación mensual de la precipitación a nivel estatal
#' 
#' ### Años a mostrar
#' 
#' Se omitirán los años _base_, aquellos con los que se hizo el cálculo de 
#' la normal (también llamado _promedio histórico_), por lo que solamente 
#' se mostrarán los años del 2011 en adelante.
#' 
#' ### Texto a mostrar
#' 
#' Al tratarse de una sola imagen no se van a etiquetar todas las líneas, 
#' por lo que solo se van a mostrar los siguientes años por estado:
#' - Año con mayor lluvia
#' - Año con menor lluvia
#' - Año actual
#' - Año anterior al actual
#' 
#' El número máximo de etiquetas por estado es 4, ya que el año con mayor o 
#' menor lluvia puede ser el año anterior al actual.
#' 
#' ### Líneas a resaltar
#' 
#' Resaltar con texto no es suficiente, por lo que también se resaltará 
#' a través del grosor de las líneas aquellas con los mismos años. Además 
#' también se resaltará la línea que represente el promedio histórico. 
#' 
#' Al final de cada línea resaltada se agregará un circulo al final.

current_n_year <- chirps_ent_nac_month %>%
  arrange(n_year) %>%
  pull(n_year) %>%
  max()

df_cumsum_pr_ent_2011 <- chirps_ent_nac_month %>%
  mutate(n_month = as.integer(n_month)) %>%
  filter(
    # Año 2011 en adelante
    n_year >= 2011,
    # Ignorar valores nacionales
    cve_ent != "00") %>%
  select(cve_ent, nombre_estado, n_year, n_month, cumsum_pr_mm) %>%
  mutate(n_year = as.character(n_year))

# Promedio histórico (adaptado)
df_cumsum_pr_ent_historical_average <- normal_ent_nac_month %>%
      mutate(n_month = as.integer(n_month)) %>%
      filter(cve_ent != "00") %>%
      select(cve_ent, nombre_estado, n_month, normal_cumsum_pr_mm) %>%
      rename(cumsum_pr_mm = normal_cumsum_pr_mm) %>%
      mutate(n_year = "Promedio histórico")

df_vis_cumulative_pr_mm <- bind_rows(
    df_cumsum_pr_ent_2011,
    df_cumsum_pr_ent_historical_average) %>%
  # Drop NA rows
  filter(!is.na(cumsum_pr_mm)) %>%
  mutate(
  # Order lines
    n_year = ordered(
      x = n_year,
      levels = c(as.character(2011:2024), "Promedio histórico", "2025")),
  
  # colour coding years
    n_year_colour = case_when(
      n_year %in% 2011:2015 ~ "2011-2015",
      n_year %in% 2016:2020 ~ "2016-2020",
      n_year %in% 2021:2024 ~ "2021-2024",
      .default = n_year)) %>%
  group_by(
    cve_ent,
    nombre_estado) %>%
  arrange(n_year, n_month, .by_group = TRUE) %>%
  mutate(
    # Locate years of interest: promedio historico, current, previous, rainiest and driest
    n_year_oi = if_else(
      condition = cumsum_pr_mm == max(cumsum_pr_mm[which(n_month == max(n_month))]) |
                  cumsum_pr_mm == min(cumsum_pr_mm[which(n_month == max(n_month))]) |
                  n_year %in% c("Promedio histórico", current_n_year, current_n_year - 1),
      true = n_year,
      false = NA_character_)) %>%
  group_by(
    cve_ent,
    nombre_estado,
    n_year) %>%
  mutate(
    # Label only latest month and ignore "Promedio histórico"
    n_year_label = case_when(
      n_year_oi == "Promedio histórico" ~ NA_character_,
      !is.na(n_year_oi) & n_month == max(n_month) ~ n_year_oi,
      .default = NA_character_),
    n_month_endpoint_year_oi = if_else(
      condition = !is.na(n_year_oi) & n_month == max(n_month),
      true = n_month,
      false = NA)) %>%
  ungroup() %>%
  group_by(
    cve_ent,
    nombre_estado) %>%
  mutate(
    # Highlight years of interest with linewidth
    n_year_linewidth = if_else(
      condition = n_year %in% unique(n_year_oi[!is.na(n_year_oi)]),
      true = n_year,
      false = NA)) %>%
  ungroup() %>%
  select(!n_year_oi)

# DATAVIS TESTING
# testing mex grid
mex_grid <- geofacet::mx_state_grid3 %>%
  as_tibble() %>%
  select(row,col, code) %>%
  mutate(
    code = if_else(
      condition = code >= 10,
      true = as.character(code),
      false = paste0("0", code))) %>%
  left_join(
    y = df_vis_cumulative_pr_mm %>%
          distinct(cve_ent, nombre_estado) %>%
          rename(name = nombre_estado),
    by = join_by(code == cve_ent))

geofacet::grid_preview(mex_grid)

# vis
df_vis_cumulative_pr_mm %>%
  ggplot(
    mapping = aes(
      x = n_month,
      y = cumsum_pr_mm,
      group = n_year,
      colour = n_year_colour,
      label = n_year_label,
      linewidth = if_else(condition = !is.na(n_year_linewidth), true = 0.7, false = 0.3)
    )
  ) +
  geom_line() +
  geom_point(
    mapping = aes(
      x = n_month_endpoint_year_oi)
        ) +
  geom_text(show.legend = FALSE) +
  # geofacet::facet_geo(facets = vars(nombre_estado), grid = mex_grid, label = "name", scales = "free") +
  facet_wrap(facets = vars(nombre_estado),ncol = 4,scales = "free") +
  scale_linewidth_identity() +
  coord_cartesian(clip = "off") +
  theme(
    legend.location = "none",
    legend.position = "top",
    legend.justification = "left")

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