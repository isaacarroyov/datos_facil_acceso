#' ---
#' title: Pruebas con ObservablePlot
#' subtitle: Análisis Exploratorio de Datos
#' author: Isaac Arroyo
#' date-format: long
#' date: last-modified
#' lang: es
#' format:
#'   html:
#'     toc: true
#'     fontsize: 12pt
#'     mainfont: Futura
#'     fig-width: 5.5
#'     fig-asp: 0.75
#'     fig-dpi: 300
#'     code-fold: true
#'     code-annotations: below
#'     code-line-numbers: true
#' 
#' execute:
#'   echo: true
#'   eval: true
#'   warning: false
#' ---
#' 

#| label: setwd_quarto
#| eval: false
#| echo: false

setwd("./EarthEngine/chirps/estadisticas")

#' # Introducción
#' 
#' Para esta prueba se harán 3 visualizaciones 
#' con [**ObservablePlot**](https://observablehq.com/plot):
#' 
#' 1. Anomalía anual de la precipitación
#' 2. Anomalía mensual de la precipitación
#' 3. Acumulación mensual de la precipitación
#' 
#' La información se verá a partir del 2011 hasta la fecha más disponible.

#| label: load-paths2data
library(tidyverse)

path2main <- paste0(getwd(), "/../../.." )
path2ee <- paste0(path2main, "/EarthEngine")
path2chirps <- paste0(path2ee, "/chirps")
path2chirps_data <- paste0(path2chirps, "/data")
path2chirps_dataent <- paste0(path2chirps_data, "/estados")
path2chirps_datanormal <- paste0(path2chirps_data, "/normal")

db_pr_ent_year <- read_csv(
    file = paste0(path2chirps_dataent, "/db_pr_ent_year.csv")) %>%
  filter(n_year > 2010)

db_pr_ent_month <- read_csv(
    file = paste0(path2chirps_dataent, "/db_pr_ent_month.csv")) %>%
  filter(!is.na(pr_mm), n_year > 2010)

db_pr_normal_ent_year <- read_csv(
    file = paste0(
      path2chirps_datanormal,
      "/db_pr_normal_ent_year.csv"))

db_pr_normal_ent_month <- read_csv(
    file = paste0(
      path2chirps_datanormal,
      "/db_pr_normal_ent_month.csv"))

#' # Procesamiento de datos
#' 
#' ## Anomalía anual de la precipitación
#' 
#' El objetivo es poder lograr una visualización que refleje la anomalía 
#' de la lluvia al paso de los años en todo el país y en cada estado.
#' 
#' Para ello se necesita una estructura donde cada fila sea un estado 
#' (se incluye la nación) en un determinado año con su respectivo valor de 
#' anomalía.

#| label: create-df2vis_info_ent_nac_year
df2vis_info_ent_nac_year <- db_pr_ent_year %>%
  group_by(n_year) %>%
  summarise(pr_mm = mean(pr_mm)) %>%
  ungroup() %>%
  mutate(
    cve_ent = "00",
    nombre_estado = "the country",
    normal_pr_mm = mean(db_pr_normal_ent_year$normal_pr_mm),
    anomaly_pr_mm = pr_mm - normal_pr_mm,
    anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
  select(!normal_pr_mm) %>%
  bind_rows(db_pr_ent_year)

#' Un ejemplo de la visualización sería la siguiente

#| label: fig-linechart-example-anomaly-year-ent-nac
var_ent_name <- "San Luis Potosí"
var_latest_update_info <- format(max(db_pr_ent_month$date_year_month), format = "%B %Y")

df2vis_info_ent_nac_year %>%
  ggplot(
    mapping = aes(
      x = n_year,
      y = anomaly_pr_prop,
      group = cve_ent,
      color = if_else(
        condition = nombre_estado == "the country",
        true = "#BE3144",
        false = "#240750"),
      alpha = if_else(
        condition = nombre_estado %in% c(var_ent_name, "the country"),
        true = 1,
        false = 0.3),
      linewidth = if_else(
        condition = nombre_estado %in% c(var_ent_name, "the country"),
        true = 1.2,
        false = 0.3))) +
  geom_hline(yintercept = 0, color = "#000000", linewidth = 0.5) +
  geom_line() +
  scale_color_identity() +
  scale_alpha_identity() +
  scale_linewidth_identity() +
  scale_x_continuous(breaks = seq(from = 2011, to = 2024, by = 3)) +
  scale_y_continuous(
    n.breaks = 6,
    labels = scales::label_percent()) +
  labs(
    title = paste0("How much rain has <span style='color:#240750;'>",
                   var_ent_name,"</span> had in recent years?" ),
    subtitle = paste0("Yearly precipitation anomaly in ",
                      "<b style='color:#BE3144;'>the country</b> compared to ",
                      "the other <b style='color:#240750;'>states</b>.<br>",
                      "The period used for computing the climatology is ",
                      "1981-2010"),
    caption = paste("Data: Climate Hazards Center InfraRed Precipitation",
                    "With Station Data (CHIRPS).<br>",
                    "Latest update:", var_latest_update_info, "<br>",
                    "Chart: Isaac Arroyo (@isaacarroyov)")) +
  theme_void() +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = ggtext::element_textbox(
      face = "bold",
      width = unit(x = 5.5, units = "in")),
    plot.subtitle = ggtext::element_textbox(
      width = unit(x = 5.5, units = "in")),
    plot.caption = ggtext::element_textbox(
      width = unit(x = 5.5, units = "in")),
    axis.line.x = element_line(color = "#000000"),
    axis.ticks.length.x = unit(x = 0.05, units = "in"),
    axis.ticks.x = element_line(color = "#000000"),
    axis.text = element_text(),
    panel.grid.major.y = element_line(color = "#000000", linewidth = 0.05)
  )

# tgutil::ggpreview(width = 5.5, height = 5.5 * 0.75, unit = "in", bg = "#F1EFE3")

#' La principal idea, es que el valor de **`var_ent_name`** pueda ser 
#' seleccionado a través de un menú desplegable. Gracias al menú el título 
#' también cambia.
#' 
#' ## Anomalía mensual de la precipitación
#' 
#' El objetivo es poder lograr una visualización que refleje la anomalía de 
#' cada mes del año de todos los años registrados de todo el país y 
#' los estados.
#' 
#' Para ello se necesita una estructura donde cada fila sea un estado 
#' (se incluye la nación) en un determinado año con su respectivo valor de 
#' anomalía de un mes.

#| label: create-df2vis_info_ent_nac_month
df2vis_info_ent_nac_month <- db_pr_ent_month %>%
  group_by(
    n_year,
    n_month) %>%
  summarise(pr_mm = mean(pr_mm)) %>%
  ungroup() %>%
  mutate(
    cve_ent = "00",
    nombre_estado = "the country") %>%
  left_join(
    y = db_pr_normal_ent_month %>%
          group_by(n_month) %>%
          summarise(normal_pr_mm = mean(normal_pr_mm)) %>%
          ungroup() %>%
          mutate(n_month = as.integer(n_month)),
    by = join_by(n_month)) %>%
  mutate(
    anomaly_pr_mm = pr_mm - normal_pr_mm,
    anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
  bind_rows(
    select(.data = db_pr_ent_month, !date_year_month) %>%
      left_join(
        y = mutate(db_pr_normal_ent_month, n_month = as.integer(n_month)),
        by = join_by(cve_ent, nombre_estado, n_month)) %>%
      relocate(normal_pr_mm, .before = anomaly_pr_mm)) %>%
  group_by(
    cve_ent,
    nombre_estado,
    n_year) %>%
  arrange(n_month, .by_group = TRUE) %>%
  mutate(cumsum_pr_mm = cumsum(pr_mm)) %>%
  ungroup() %>%
  relocate(cumsum_pr_mm, .before = normal_pr_mm) %>%
  select(!c(normal_pr_mm)) %>%
  mutate(n_year = as.character(n_year))

#' Un ejemplo de la visualización sería la siguiente

#| label: fig-linechart-example-anomaly-pr-prop-month-ent-nac
var_n_year <- "2024"

df2vis_info_ent_nac_month %>%
  filter(n_year == var_n_year) %>%
  ggplot(
    mapping = aes(
      x = n_month,
      y = anomaly_pr_prop,
      group = cve_ent,
      color = if_else(
        condition = nombre_estado == "the country",
        true = "#BE3144",
        false = "#240750"),
      alpha = if_else(
        condition = nombre_estado %in% c(var_ent_name, "the country"),
        true = 1,
        false = 0.3),
      linewidth = if_else(
        condition = nombre_estado %in% c(var_ent_name, "the country"),
        true = 1.2,
        false = 0.3))) +
  geom_line() +
  geom_hline(yintercept = 0, color = "#000000", linewidth = 0.5) +
  geom_line() +
  scale_color_identity() +
  scale_alpha_identity() +
  scale_linewidth_identity() +
  scale_x_continuous(
    breaks = 1:12,
    labels = month.abb) +
  scale_y_continuous(
    n.breaks = 6,
    labels = scales::label_percent(big.mark = ",")) +
  coord_cartesian(xlim = c(1, 12)) +
  labs(
    title = paste0("How much rain did <span style='color:#240750;'>",
                   var_ent_name,"</span> have in ", var_n_year, "?" ),
    subtitle = paste0("Monthly precipitation anomaly in ",
                      "<b style='color:#BE3144;'>the country</b> compared to ",
                      "the other <b style='color:#240750;'>states</b>.<br>",
                      "The period used for computing the climatology is ",
                      "1981-2010"),
    caption = paste("Data: Climate Hazards Center InfraRed Precipitation",
                    "With Station Data (CHIRPS).<br>",
                    "Latest update:", var_latest_update_info,"<br>",
                    "Chart: Isaac Arroyo (@isaacarroyov)")) +
  theme_void() +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = ggtext::element_textbox(
      face = "bold",
      width = unit(x = 5.5, units = "in")),
    plot.subtitle = ggtext::element_textbox(
      width = unit(x = 5.5, units = "in")),
    plot.caption = ggtext::element_textbox(
      width = unit(x = 5.5, units = "in")),
    axis.line.x = element_line(color = "#000000"),
    axis.ticks.length.x = unit(x = 0.05, units = "in"),
    axis.ticks.x = element_line(color = "#000000"),
    axis.text = element_text(),
    panel.grid.major.y = element_line(color = "#000000", linewidth = 0.05)
  )

# tgutil::ggpreview(width = 5.5, height = 5.5 * 0.75, unit = "in", bg = "#F1EFE3")

#' La principal idea, es que el valor de **`var_ent_name`** y 
#' **`var_n_year`** puedan ser seleccionados a través de un menú 
#' desplegable (cada uno). Gracias a los menús el título también cambia.
#' 
#' ## Acumulación mensual de la precipitación
#' 
#' Para este último lo único que hace falta es poder comparar la 
#' acumulación de la precipitación con la normal.
#' 
#' Para ello se agrega la información de la acumulación normal a 
#' **`df2vis_info_ent_nac_month`**

#| label: create-df2vis_info_cumsum_ent_nac_month
df2vis_info_cumsum_ent_nac_month <- db_pr_normal_ent_month %>%
  group_by(n_month) %>%
  summarise(pr_mm = mean(normal_pr_mm)) %>%
  ungroup() %>% 
  mutate(
    cumsum_pr_mm = cumsum(pr_mm),
    n_month = as.numeric(n_month),
    n_year = "1980-2010",
    cve_ent = "00",
    nombre_estado = "the country") %>%
  select(
    cve_ent,
    nombre_estado,
    n_year, n_month,
    pr_mm,
    cumsum_pr_mm) %>%
  bind_rows(
    db_pr_normal_ent_month %>%
      mutate(n_month = as.numeric(n_month)) %>%
      rename(pr_mm = normal_pr_mm) %>%
      group_by(
        cve_ent,
        nombre_estado) %>%
      arrange(n_month, .by_group = TRUE) %>%
      mutate(cumsum_pr_mm = cumsum(pr_mm)) %>%
      ungroup() %>%
      mutate(n_year = "1980-2010") %>%
      select(
        cve_ent,
        nombre_estado,
        n_year, n_month,
        pr_mm,
        cumsum_pr_mm)) %>%
  bind_rows(
    df2vis_info_ent_nac_month %>% 
      select(
        cve_ent,
        nombre_estado,
        n_year, n_month,
        pr_mm,
        cumsum_pr_mm))

#' Un ejemplo de la visualización sería la siguiente

#| label: fig-linechart-example-cumsum-nac-ent-year-month
df2vis_info_cumsum_ent_nac_month %>%
  filter(nombre_estado == var_ent_name) %>%
  ggplot(
    mapping = aes(
      x = n_month,
      y = cumsum_pr_mm,
      group = n_year,
      color = if_else(
        condition = n_year == "1980-2010",
        true = "#CD5C08",
        false = "#116D6E"),
      alpha = if_else(
        condition = n_year %in% c(var_n_year, "1980-2010"),
        true = 1,
        false = 0.3),
      linewidth = if_else(
        condition = n_year %in% c(var_n_year, "1980-2010"),
        true = 1.2,
        false = 0.3))) +
  geom_line() +
  geom_line() +
  scale_color_identity() +
  scale_alpha_identity() +
  scale_linewidth_identity() +
  scale_x_continuous(
    breaks = 1:12,
    labels = month.abb) +
  scale_y_continuous(labels = scales::label_comma(suffix = " mm")) +
  coord_cartesian(xlim = c(1, 12)) +
  labs(
    title = paste0("Was there enough rain in ", var_ent_name, " during ",
                   "<span style='color:#116D6E;'>", var_n_year, "</span>?" ),
    subtitle = paste0("Monthly precipitation accumulation ",
                      "compared to the <b style='color:#CD5C08;'>",
                      "1980-2010 period</b>."),
    caption = paste("Data: Climate Hazards Center InfraRed Precipitation",
                    "With Station Data (CHIRPS).<br>",
                    "Latest update:", var_latest_update_info,".<br>",
                    "Chart: Isaac Arroyo (@isaacarroyov)")) +
  theme_void() +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = ggtext::element_textbox(
      face = "bold",
      width = unit(x = 5.5, units = "in")),
    plot.subtitle = ggtext::element_textbox(
      width = unit(x = 5.5, units = "in")),
    plot.caption = ggtext::element_textbox(
      width = unit(x = 5.5, units = "in")),
    axis.line.x = element_line(color = "#000000"),
    axis.ticks.length.x = unit(x = 0.05, units = "in"),
    axis.ticks.x = element_line(color = "#000000"),
    axis.text = element_text(),
    panel.grid.major.y = element_line(color = "#000000", linewidth = 0.05)
  )

# tgutil::ggpreview(width = 5.5, height = 5.5 * 0.75, unit = "in", bg = "#F1EFE3")

#' La principal idea, es que el valor de **`var_ent_name`** y 
#' **`var_n_year`** puedan ser seleccionados a través de un menú 
#' desplegable (cada uno). Gracias a los menús el título también cambia.
#' 
#' # Creación de visualizaciones con ObservablePlot
#' 
#' ## Transformación a objetos para ObservablePlot
#' 
#' Para poder crear todas las visualizaciones, hace falta hacer la 
#' conversión de datos _tidy_ al formato usado por ObservablePlot. Esta 
#' tarea se hará con la función **`ojs_define`**^[Función para la 
#' transformación de `pandas.DataFrame` de **Python** y `tibble` de **R** a 
#' datos para ObservablePlot. Solo funciona cuando se renderiza el script].

#| code-summary: "Transform data"
#| label: create-observable-objects-data2vis
ojs_define(data2vis_year = df2vis_info_ent_nac_year)
ojs_define(data2vis_month = df2vis_info_ent_nac_month)
ojs_define(data2vis_cumsum_month = df2vis_info_cumsum_ent_nac_month)

#' También es importante poder importar todos los parámetros que serán 
#' necesario para los menús, así como para mostar la más reciente 
#' actualización de los datos.

#| code-summary: "Create elements"
#| label: create-observable-objects-arrays4menus-and-strings
ojs_define(array_ent_name = pull(
    .data = distinct(
      .data = df2vis_info_cumsum_ent_nac_month,
      nombre_estado)))

ojs_define(array_n_year = pull(
    .data = distinct(
      .data = df2vis_info_ent_nac_month,
      n_year)))

ojs_define(string_latest_update = format(
    x = max(db_pr_ent_month$date_year_month),
    format = "%B %Y"))

#' ## Creación de menús desplegables
#' 
#' Con las transformaciones hechas, ahora podemos crear los menús 
#' desplegables
#' 
#' **Menú de nombre de entidades**

#' ```{ojs}
#' // label: create-select_ent_name
#' viewof select_ent_name = Inputs.select(
#'     array_ent_name,
#'     {value: 'Yucatán',
#'     label: "State"})
#' ```
#' 
#' **Menú de años**
#' 
#' ```{ojs}
#' // label: create-select_n_year
#' viewof select_n_year = Inputs.select(
#'     array_n_year,
#'     {value: "2023",
#'     label: "Year"})
#' ```
#' 
#' ```{ojs}
#' viewof select_n_year = Inputs.select(
#'     array_n_year,
#'     {value: "2023",
#'     label: "Año"})
#' ```
#' 
#' ---
#' 
#' ```{ojs}
#' html`
#' <div>
#'   <span style:'font-size:1.5em;font-weight:600'>${select_ent_name}: Anomaly precipitation during ${select_n_year}</span>
#'   <br>
#'   <span><>
#' </div>`
#' ```
#' 
#' ```{ojs}
#' data2vis_filtered = transpose(data2vis).filter(
#'   function(d) {return d.nombre_estado === select_ent_name})
#' ```
#' 
#' ```{ojs}
#' Plot.plot({
#'   // Axis config
#'   y: {grid: true, percent: true},
#'   x: {grid: false,
#'       label: null,
#'       type: "point",
#'       fontFamily: "Georgia",
#'       tickFormat: (d) => {
#'         const mes = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
#'                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
#'         return mes[d - 1]}},
#' 
#'   // Colour Enconding
#'   color: {
#'     domain: [false, true],
#'     range: ["#D4BDAC", "#AF1740"]},
#'   
#'   marks: [
#'     // Y-Axis to the right
#'     Plot.axisY({
#'       anchor: "right",
#'       labelAnchor: "top",
#'       textAnchor: "start",
#'       tickSize: 0,
#'       marginRight: 50,
#'       tickFormat: (d) => d + "%",
#'       label: null}),
#'     // Línea de 0
#'     Plot.ruleY([0]),
#'     // Line Chart
#'     Plot.line(data2vis_filtered, {
#'       x: "n_month",
#'       // y: "cumsum_pr_mm",
#'       y: "anomaly_pr_prop",
#'       z: "n_year",
#'       curve: "catmull-rom",
#'       stroke: (d) => d.n_year === select_n_year ? true : false,
#'       strokeWidth: (d) => d.n_year === select_n_year ? 3 : 0.5,
#'       sort: {channel: "stroke"}
#'       })
#'   ]
#' })
#' ```
#' 
#' <div style='font-size:0.7em'>
#'   Data: Climate Hazards Center InfraRed Precipitation With Station Data (CHIRPS)
#'   <br>
#'   Chart: Isaac Arroyo (@isaacarroyov)
#' </div>

#' Donec ut imperdiet felis, vitae ultricies diam. Mauris non risus 
#' ligula. Nam ultricies imperdiet quam, sed vestibulum nisi sodales 
#' nec. Integer vehicula, ex sit amet ornare volutpat, nulla diam posuere 
#' nibh, quis maximus ex ante id ante. Morbi massa nunc, tempus vel tortor 
#' ac, vulputate lacinia sapien. Quisque dapibus sodales orci, eget porta 
#' metus commodo sed. Cras blandit rutrum elementum. Vivamus tempus, lorem 
#' ut accumsan porta, libero magna facilisis felis, in viverra mauris urna 
#' id quam. In id molestie sem. Suspendisse potenti. Duis sit amet quam eu 
#' diam porttitor iaculis ut sed libero.
