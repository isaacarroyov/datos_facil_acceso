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

setwd("./ignored_files")

#' Para esta prueba se harán 3 visualizaciones 
#' con [**ObservablePlot**](https://observablehq.com/plot):
#' 
#' 1. Anomalía de la precipitación anual: incluye valor nacional
#' 3. Anomalía de la precipitación mensual: incluye valor nacional
#' 2. Acumulación de la precipitación mensual: incluye el valor normal

#| label: load_all_necesario
library(tidyverse)

path2main <- paste0(getwd(),"/.." )
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

#' ---

#| label: create-df2vis_anomaly_pr_prop_year
df2vis_anomaly_pr_prop_year <- db_pr_ent_year %>%
  group_by(n_year) %>%
  summarise(pr_mm = mean(pr_mm)) %>%
  ungroup() %>%
  mutate(
    cve_ent = "00",
    nombre_estado = "Nacional",
    normal_pr_mm = mean(db_pr_normal_ent_year$normal_pr_mm),
    anomaly_pr_mm = pr_mm - normal_pr_mm,
    anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
  select(!normal_pr_mm) %>%
  bind_rows(db_pr_ent_year)

#' 

#| label: create-df2vis_info_ent_nac_month
df2vis_info_ent_nac_month <- db_pr_ent_month %>%
  group_by(
    n_year,
    n_month) %>%
  summarise(pr_mm = mean(pr_mm)) %>%
  ungroup() %>%
  mutate(
    cve_ent = "00",
    nombre_estado = "Nacional") %>%
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
  select(!c(normal_pr_mm))


#' 


#| label: create-observable-objects-data2vis
#| echo: true
ojs_define(data2vis = datos_interes)
ojs_define(latest_info = format(max(datos_interes$date_year_month), format = "%B %Y"))

#' 

#| label: create-observable-objects-array_ent_name
#| echo: true
ojs_define(array_ent_name = pull(distinct(datos_interes, nombre_estado)))


#' ```{ojs}
#' viewof select_ent_name = Inputs.select(
#'     array_ent_name,
#'     {value: 'Yucatán',
#'     label: "Estado"})
#' ```

#| label: create-observable-objects-array_n_year
#| echo: true
ojs_define(array_n_year = pull(distinct(datos_interes, n_year)))


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