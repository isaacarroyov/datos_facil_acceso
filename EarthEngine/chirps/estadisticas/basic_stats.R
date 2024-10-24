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
library(gghighlight)
library(sf)

theme_set(theme_void(base_family = "Helvetica", base_size = 8))
theme_update(
  # ~ ~ Text ~ ~ #
  # Title, subtitle, captions, facets
  plot.title.position = "plot",
  plot.caption.position = "plot",
  plot.title = ggtext::element_textbox(
    size = 13,
    face = "bold",
    halign = 0,
    hjust = 0,
    margin = margin(t = 0.08, b = 0.05, unit = "in"),
    width = unit(5, "in")),
  plot.subtitle = ggtext::element_textbox(
    size = 9,
    face = "plain",
    halign = 0,
    hjust = 0,
    margin = margin(b = 0.15, unit = "in"),
    width = unit(5, "in")),
  plot.caption = ggtext::element_textbox(
    size = 7,
    face = "plain",
    halign = 0,
    hjust = 0,
    margin = margin(b = 0.05, t = 0.08, unit = "in"),
    width = unit(5, "in")),
  
  # Axes
  axis.title = element_blank(),
  axis.text = element_text(),
  axis.text.x = element_text(
    hjust = 0.5,
    margin = margin(t = 0.03, unit = "in")),
  axis.text.y = element_text(
    hjust = 1,
    margin = margin(r = 0.03, unit = "in")),
  
  # Facets and grids
  strip.text = element_text(
    face = "bold",
    size = 9),
  
  # ~ ~ Lines ~ ~ #
  # Axis
  axis.ticks = element_line(color = "black", linewidth = 0.3),
  axis.ticks.length = unit(0.05, "in"),
  axis.line = element_line(color = "black", linewidth = 0.3),
  panel.grid.minor = element_blank(),
  panel.grid.major = element_line(color = "gray90", linewidth = 0.3))

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

normal_ent_week <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_ent_week.csv"))

# Municipios
normal_mun_year <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_mun_year.csv"))

normal_mun_month <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_mun_month.csv"))

normal_mun_week <- read_csv(
    file = paste0(path2data,
                  "/normal",
                  "/db_pr_normal_mun_week.csv"))

# ~ Estados ~ #
chirps_ent_year <- read_csv(
    file = paste0(path2data,
                  "/estados",
                  "/db_pr_ent_year.csv"))

chirps_ent_month <- read_csv(
    file = paste0(path2data,
                  "/estados",
                  "/db_pr_ent_month.csv"))

chirps_ent_week <- read_csv(
    file = paste0(path2data,
                  "/estados",
                  "/db_pr_ent_week.csv"))

# ~ Municipios ~ #
chirps_mun_year <- read_csv(
    file = paste0(path2data,
                  "/municipios",
                  "/db_pr_mun_year.csv"))

chirps_mun_month <- read_csv(
    file = paste0(path2data,
                  "/municipios",
                  "/db_pr_mun_month.csv.bz2"))

chirps_mun_week <- read_csv(
    file = paste0(path2data,
                  "/municipios",
                  "/db_pr_mun_week.csv.bz2"))

text_recent_date <- chirps_ent_month %>%
  filter(!is.na(pr_mm)) %>%
  filter(max(date_year_month) == date_year_month) %>%
  distinct(date_year_month) %>%
  pull(date_year_month) %>%
  format(format = "%B %Y") %>%
  str_to_title()

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

#| label: fig-cumsum-pr-nac

chirps_nac_month <- normal_ent_month %>%
  group_by(n_month) %>%
  summarise(normal_pr_mm = mean(normal_pr_mm, na.rm = TRUE)) %>%
  ungroup() %>%
  arrange(n_month) %>%
  mutate(
    n_month = as.integer(n_month),
    cumsum_normal_pr_mm = cumsum(normal_pr_mm))


chirps_ent_month %>%
  group_by(
    n_year,
    n_month) %>%
  summarise(pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(n_year) %>%
  arrange(n_month, .by_group = TRUE) %>%
  mutate(cumsum_pr_mm = cumsum(pr_mm)) %>%
  ungroup() %>%
  ggplot(
    mapping = aes(
      x = n_month,
      y = cumsum_pr_mm,
      group = n_year,
      color = case_when(
        n_year == 2024 ~ "red",
        n_year == 2023 ~ "orange",
        .default = "gray80"),
      size = if_else(
        condition = n_year %in% 2023:2024,
        true = 1,
        false = 0.3
      ))) +
  geom_line() +
  #geom_step(direction = "mid") +
  geom_line(
    data = chirps_nac_month,
    mapping = aes(y = cumsum_normal_pr_mm, group = NULL),
    color = "steelblue",
    size = 1) +
  scale_color_identity() +
  scale_size_identity() +
  scale_y_continuous(
    labels = label_comma(suffix = "\nmm"),
    expand = expansion(mult = c(0, 0))) +
  scale_x_continuous(
    breaks = 1:12,
    labels = month.abb,
    expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = paste("<span style='color:red;'>2024</span> no ha sido tan",
                  "seco como <span style='color:orange;'>2023</span>"),
    subtitle = paste("Acumulación de la precipitación en",
                      "<b>México</b>. Periodo: 1981 -",
                      text_recent_date,".",
                      "<br>Se resalta la",
                      "<b style='color:steelblue'>acumulación normal</b>."),
    caption = paste("Fuente:", text_source_chirps,
                    "<br>Nota: La <em>normal</em> es el promedio de",
                    "periodo 1981 - 2010")) +
  theme(
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.x = element_blank())

# tgutil::ggpreview(width = 5, height = 5 * 0.75, units = "in", bg = "#F3EFE1")

#'

#| label: fig-pr-nac
chirps_ent_month %>%
  group_by(
    n_year,
    n_month) %>%
  summarise(pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(n_year) %>%
  arrange(n_month, .by_group = TRUE) %>%
  mutate(cumsum_pr_mm = cumsum(pr_mm)) %>%
  ungroup() %>%
  ggplot(
    mapping = aes(
      x = n_month,
      y = pr_mm,
      group = n_year,
      color = case_when(
        n_year == 2024 ~ "red",
        n_year == 2023 ~ "orange",
        .default = "gray80"),
      size = if_else(
        condition = n_year %in% 2023:2024,
        true = 1,
        false = 0.3
      ))) +
  geom_line() +
  geom_line(
    data = chirps_nac_month,
    mapping = aes(y = normal_pr_mm, group = NULL),
    color = "steelblue",
    size = 1) +
  scale_color_identity() +
  scale_size_identity() +
  scale_y_continuous(
    labels = label_comma(suffix = "\nmm"),
    expand = expansion(mult = c(0, 0))) +
  scale_x_continuous(
    breaks = 1:12,
    labels = month.abb,
    expand = expansion(mult = c(0, 0.03))) +
  labs(
    title = paste("<span style='color:red;'>2024</span> no ha sido tan",
                  "seco como <span style='color:orange;'>2023</span>"),
    subtitle = paste("Precipitación mensual en <b>México</b>.",
                     "Periodo: 1981 -", text_recent_date,".",
                     "<br>Se resalta la",
                     "<b style='color:steelblue'>precipitación normal</b>"),
    caption = paste("Fuente:", text_source_chirps,
                    "<br>Nota: La <em>normal</em> es el promedio de",
                    "periodo 1981 - 2010")) +
  theme(
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.x = element_blank())

# tgutil::ggpreview(width = 5, height = 5 * 0.75, units = "in", bg = "#F3EFE1")

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