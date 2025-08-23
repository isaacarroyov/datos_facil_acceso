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
#'   echo: true
#'   eval: true
#'   warning: false
#' ---

#| label: here_i_am
here::i_am("EarthEngine/chirps/scripts/documentacion_wide2long_chirps.R") 

#' ## Introducción y objetivos
#' 
#' La extracción de la **precipitación en milímetros (mm)** fue a través 
#' de Google Earth Engine. El periodo de extracción de los datos fue de 
#' 45 años, iniciando en 1981 hasta 2025. En total se tienen 176 archivos 
#' CSV en la carpeta **`EarthEngine/chirps/data/ee_imports`**
#' 
#' |**Tipo de archivo CSV**|**Número de archivos**|
#' |---|---|
#' |Precipitación anual de los estados|1 archivo por cada año :arrow_right: 45 archivos|
#' |Precipitación mensual de los estados|1 archivo por cada año :arrow_right: 45 archivos|
#' |Precipitación anual de los municipios|1 archivo por cada año :arrow_right: 45 archivos|
#' |Precipitación mensual de los municipios|1 archivo por cada año :arrow_right: 45 archivos|
#' 
#' El siguiente paso es poder unir todo en 8 archivos
#' 
#' * Anual: 
#'   * Métricas de precipitación a nivel estatal en el periodo 1981 a 2025.
#'   * Métricas de precipitación a nivel municipal en el periodo 1981 a 2025.
#'   * Precipitación normal (promedio histórico) a nivel estatal.
#'   * Precipitación normal (promedio histórico) a nivel municipal.
#' * Mensual: 
#'   * Métricas de precipitación a nivel estatal en el periodo 1981 a 2025.
#'   * Métricas de precipitación a nivel municipal en el periodo 1981 a 2025.
#'   * Precipitación normal (promedio histórico) a nivel estatal.
#'   * Precipitación normal (promedio histórico) a nivel municipal.

#| label: load-necesarios
#| output: false
Sys.setlocale(locale = "es_ES")
library(tidyverse)

path2repo <- here::here()
path2ee <- here::here("EarthEngine")
path2chirps <- here::here("EarthEngine", "chirps")
path2chirpsdata <- here::here("EarthEngine", "chirps", "data")

#' ## Los conjuntos de datos
#' 
#' ### Ubicación de los archivos
#' 
#' Todos los archivos se encuentran en una misma carpeta, lo que los 
#' distingue es el nombre del archivo. El nombre tiene la estructura 
#' de `chirps_pr_mm_GEOMETRIA_PERIODO_AAAA.csv`, donde:
#' 
#' * `GEOMETRIA`: Indica las geometrías de la información, tales como 
#' `ent` (Estados) y `mun` (Municipios).
#' * `PERIODO`: Tiene los valores de los periodos de extracción, tales 
#' como `year` (anual) y `month` (mensual).
#' * `AAAA`: Indica el año de la información, de 1981 a 2025.
#' 
#' Para dividir en 8 grupos a todos los archivos, se usarán 2 partes del 
#' nombre: `_GEOMETRIA_PERIODO_`

#| label: load_chirp_files
# Obtener el nombre (path incluido) de todos los archivos que se 
# importaron de Google Earth Engine 
all_csv_chirps <- list.files(
    path = paste0(path2chirpsdata, "/ee_imports"),
    pattern = "*.csv",
    full.names = TRUE)

# - - Entidades - - #
# ~ Mensual ~ #
csvs_chirps_ent_month <- str_subset(string = all_csv_chirps, pattern = "_ent_month_")
# ~ Anual ~ #
csvs_chirps_ent_year <- str_subset(string = all_csv_chirps, pattern = "_ent_year_")

# - - Municipios - - #
# ~ Mensual ~ #
csvs_chirps_mun_month <- str_subset(string = all_csv_chirps, pattern = "_mun_month_")
# ~ Anual ~ #
csvs_chirps_mun_year <- str_subset(string = all_csv_chirps, pattern = "_mun_year_")
 
#' ### Carga de los archivos
#' 
#' Para poder leer y unir 44 archivos en uno solo, se usa `purrr::map`. 
#' `purrr` es una librería que forma parte del `{tidyverse}`, por lo que ya 
#' se encuentra cargada en el ambiante. Con `map` se leeran los paths de los 
#' archivos de interés (dados por `idx_`).

#| label: concat_all_files

# - - Entidades - - #
# ~ Anual ~ #
chirps_ent_year <- map(
    .x = csvs_chirps_ent_year,  # <1> 
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>% # <2>
  bind_rows() %>% # <3>
  janitor::clean_names() %>% # <4>
  select(cvegeo, n_year, mean) # <5>

# ~ Mensual ~ #
chirps_ent_month <- map(
    .x = csvs_chirps_ent_month,
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x"))) # <6>

# - - Municipios - - #
# ~ Anual ~ #
chirps_mun_year <- map(
    .x = csvs_chirps_mun_year,
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean)

# ~ Mensual ~ #
chirps_mun_month <- map(
    .x = csvs_chirps_mun_month,
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

#' 1. Seleccionar archivos CSVS
#' 2. Usar una función anónima para poder dar valor a más argumentos 
#' (como que todas las columnas sean leídas como _strings_) de la 
#' función `read_csv`
#' 3. Todos los `tibbles` se guardan en una lista, por lo que para unirlos 
#' en un solo `tibble` se concatenan por las filas
#' 4. Limpieza de nombres de columnas
#' 5. **Caso del periodo anual**: Las columnas de interés son las que tienen 
#' código de estado o municipio (`cvegeo`), el año de la información 
#' (`n_year`) y el nombre de la columna de información (`mean`)
#' 6. Las columnas de interés son las que tienen el código del estado o 
#' municipio (`cvegeo`), el año de la información (`n_year`) y el número de 
#' mes (después de usar `janitor::clean_names`, todas inician con 
#' `x`).

#' **Muestra de datos: Precipitación en milímetros anual a nivel estatal**

#| label: show_sample-chirps_ent_year
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_year, n = 5)

#' **Muestra de datos: Precipitación en milímetros mensual a nivel estatal**

#| label: show_sample-chirps_ent_month
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_month, n = 5)

#' ### Decisiones sobre los datos
#' 
#' > [!NOTE] 
#' > 
#' > Como lo indican los objetivos, no solo estará la **precipitación (mm)**, 
#' también se contará con las anomalías, por lo que se tendrá 
#' que incorporar este cálculo en el flujo de trabajo.
#' > 
#' > Esta es una solución temporal, en lo que se encuentra la manera 
#' **óptima** de hacer este proceso en el código de la extracción de las 
#' anomalías directamente de Google Earth Engine. 
#' 
#' 1. Transformar el formato _wide_ a _long_, para tener el número de 
#' meses como una columna. Para el caso de los datos anuales, 
#' únicamente renombrar la columna `mean` a `pr`
#' 2. Cambiar a número el valor de la precipitación.
#' 3. Crear los respectivos `tibble`s de la normal de precipitación 
#' para cada uno de los archivos.
#' 4. Crear columnas de otras métricas de la precipitación, tales como:
#'   * Acumulación mensual de la precipitación en milímetros (`cumsum_pr_mm`)
#'   * Anomalía de precipitación en milímetros (`anomaly_pr_mm`)
#'   * Anomalía de precipitación en proporción a la normal (`anomaly_pr_mm`)
#'   * Anomalía de precipitación en milímetros (`anomaly_pr_mm`)
#'   * Anomalía de acumulación mensual de la precipitación en milímetros (`cumulative_anomaly_pr_mm`)
#'   * Anomalía de acumulación mensual de la precipitación en proporción a la normal (`cumulative_anomaly_pr_prop`)
#' 
#' ## _Wide to Long_
#' 
#' Para facilitar la transformación se va crear una función que haga el 
#' pivote dependiendo si los datos son mensuales o anuales.

#| label: create-func_wide2long
func_wide2long <- function(df, periodo = "month") {
  if (periodo %in% c("month")) { # <1>
    df_pivoted <- df %>% # <1>
      pivot_longer( # <1>
        cols = starts_with("x"), # <1>
        names_to = "period", # <1>
        values_to = "pr_mm") %>% # <1>
      mutate( # <2>
        pr_mm = as.numeric(pr_mm), # <2>
        period = str_remove_all( # <2>
          string = period, # <2>
          pattern = "x|_precipitation")) # <2>
    
    df_transformed <- rename(.data = df_pivoted, n_month = period) # <3>

  } else { # <4>
    df_transformed <- df %>% # <4>
      rename(pr_mm = mean) %>% # <4>
      mutate(pr_mm = as.numeric(pr_mm))} # <4>

  return(df_transformed)} # <5>

#' 1. Si el periodo es mensual se usa `pivot_longer`
#' 2. Se cambia el valor de la precipitación a numérico y se eliminan las 
#' `x` + `_precipitation` del número de meses.
#' 3. Se renombra `period` a `n_month`, para el caso de precipitación mensual.
#' 4. Si `periodo` no es `'month'` es porque el periodo es anual y 
#' solamente se renombra la columna `mean` a `pr_mm` y se convierte a valor 
#' numérico
#' 5. Se regresa el conjunto de datos con los cambios
#' 
#' ### Sobre la precipitación acumulada a través del año en milímetros
#' 
#' Con el nombre corto de "Precipitación acumulada", es la suma acumulada 
#' continua de la precipitación mensual de los meses. Por ejemplo si en el 
#' mes de Enero la precipitación es 10, en Febrero 15 y en Marzo 40, la 
#' precipitación acumulada para cada uno será: 
#' 
#' |Mes|Precipitación|Precipitación acumulada|
#' |Enero|10|10|
#' |Febrero|15|25|
#' |Marzo|40|65|
#' 
#' La precipitación acumulada es la suma de todos los meses hasta el mes 
#' de interés

#| label: create-long_chirps
# - - Estados - - #
chirps_ent_year_long <- func_wide2long(df = chirps_ent_year, periodo = "year")
chirps_ent_month_long <- func_wide2long(df = chirps_ent_month, periodo = "month") %>%
  group_by(cvegeo, n_year) %>%
  arrange(as.integer(n_month), .by_group = TRUE) %>%
  # Cálculo de la precipitación acumulada
  mutate(cumsum_pr_mm = cumsum(pr_mm)) %>%
  ungroup()

# - - Municipios - - #
chirps_mun_year_long <- func_wide2long(df = chirps_mun_year, periodo = "year")
chirps_mun_month_long <- func_wide2long(df = chirps_mun_month, periodo = "month") %>%
  group_by(cvegeo, n_year) %>%
  arrange(as.integer(n_month), .by_group = TRUE) %>%
  # Cálculo de la precipitación acumulada
  mutate(cumsum_pr_mm = cumsum(pr_mm)) %>%
  ungroup()

#' **Muestra de `chirps_ent_month_long`**

#| label: show_sample-chirps_ent_month_long
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_month_long, n = 5)

#' ## Precipitación normal (1981 - 2010)
#' 
#' En palabras sencillas y directas, **la normal** es el promedio de una 
#' variable climatológica durante un periodo largo, usualmente de 30 años.
#' 
#' _También le llamo "promedio histórico", para mayor claridad_
#' 
#' Para facilitar el cálculo se va crear una función para tener la normal 
#' anual o mensual.

#| label: create-func_normal_pr_mm
func_normal_pr_mm <- function(df) {
  if ("n_month" %in% colnames(df)) { # <1>
    df_normal_pr_mm <- df %>% # <1>
      filter(n_year %in% 1981:2010) %>% # <1>
      group_by(cvegeo, n_month) %>% # <1>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <1>
      ungroup() # <1>

  } else { 
    df_normal_pr_mm <- df %>% # <2>
      filter(n_year %in% 1981:2010) %>% # <2>
      group_by(cvegeo) %>% # <2>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <2>
      ungroup() # <2>
  }
  
  return(df_normal_pr_mm)} # <3>

#' 1. Filtro de los 30 años _base_ y agrupación si `df` es de periodo mensual
#' 2. Filtro de los 30 años _base_ y agrupación si `df` es de periodo anual
#' 3. Se regresa el conjunto de valores normales

#| label: create-normal_pr_mm
# - - Estados - - #
normal_pr_mm_ent_year <- func_normal_pr_mm(df = chirps_ent_year_long)
normal_pr_mm_ent_month <- func_normal_pr_mm(df = chirps_ent_month_long) %>%
  group_by(cvegeo) %>%
  arrange(as.integer(n_month), .by_group = TRUE) %>%
  # Cálculo de la precipitación acumulada
  mutate(normal_cumsum_pr_mm = cumsum(normal_pr_mm)) %>%
  ungroup()

# - - Municipio - - #
normal_pr_mm_mun_year <- func_normal_pr_mm(df = chirps_mun_year_long)
normal_pr_mm_mun_month <- func_normal_pr_mm(df = chirps_mun_month_long) %>%
  group_by(cvegeo) %>%
  arrange(as.integer(n_month), .by_group = TRUE) %>%
  # Cálculo de la precipitación acumulada
  mutate(normal_cumsum_pr_mm = cumsum(normal_pr_mm)) %>%
  ungroup()

#' **Muestra de `normal_pr_mm_mun_month`**

#| label: show_sample-normal_pr_mm_ent_month
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_mun_month, n = 5)
 
#' ## Cálculo de métricas
#' 
#' ### Anomalía en milimetros
#' 
#' Es la diferencia en milimetros, de la precipitación de un determinado 
#' mes $\left( \overline{x}_{i} \right)$ y la normal 
#' $\left( \mu_{\text{normal}} \right)$ de ese mes
#' 
#' $$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$
#' 
#' ### Anomalía en proporción de la normal
#' 
#' Es el resultado de dividir la diferencia de la precipitación de un 
#' determinado mes $\left( \overline{x}_{i} \right)$ y la normal 
#' $\left( \mu_{\text{normal}} \right)$ entre la normal de ese mismo mes.
#' 
#' $$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$
#' 
#' ### Anomalía de la precipitación acumulada en milimetros
#' 
#' Similar al caso de la **anomalía en milimetros**, pero la diferencia es
#' con la precipitación acumulada normal
#' 
#' ### Anomalía de la precipitación acumulada en proporción de la normal
#' 
#' Similar al caso de la **anomalía en proporción de la normal**, pero la 
#' diferencia escon la precipitación acumulada normal
#' 
#' ### Función para cálculo de anomalías
#' 
#' La función tomará dos `tibble`s, el de la información de precipitación 
#' y el de la precipitación normal.

#| label: create-func_anomaly_pr
func_anomaly_pr <- function(df, df_normal) {
  if ("n_month" %in% colnames(df)) {
    df_anomaly_pr <- left_join( # <1>
        x = df, # <1>
        y = df_normal, # <1>
        by = join_by(cvegeo, n_month)) %>% # <1>
      mutate( # <2>
        anomaly_pr_mm = pr_mm - normal_pr_mm, # <2>
        anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm, # <2>
        cumulative_anomaly_pr_mm = cumsum_pr_mm - normal_cumsum_pr_mm, # <2>
        cumulative_anomaly_pr_prop = cumulative_anomaly_pr_mm / normal_cumsum_pr_mm) %>% # <2>
      select(!c(normal_pr_mm, normal_cumsum_pr_mm)) # <3>

  } else { # <4>
    df_anomaly_pr <- left_join( # <4>
      x = df, # <4>
      y = df_normal, # <4>
      by = join_by(cvegeo)) %>% # <4>
    mutate( # <4>
      anomaly_pr_mm = pr_mm - normal_pr_mm, # <4>
      anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>% # <4>
    select(-normal_pr_mm)} # <4>
  
  return(df_anomaly_pr)} # <5>

#' 1. Se usa un `lef_join` para unir los datos de precipitación con la 
#' precipitación normal. Se unen por región y mes
#' 2. Se hace el cálculo de las anomalías
#' 3. Se _elimina_ la columna que indica el valor de la precipitación normal
#' 4. Proceso para periodo anual. Para este caso se une por el periodo, 
#' únicamente por la región
#' 5. Se regresa el conjunto de datos con las anomalías integradas

#| label: create-anomalies_df
# - - Estados - - #
chirps_ent_year_anomalies <- func_anomaly_pr(
    df = chirps_ent_year_long,
    df_normal = normal_pr_mm_ent_year)

chirps_ent_month_anomalies <- func_anomaly_pr(
    df = chirps_ent_month_long,
    df_normal = normal_pr_mm_ent_month)

# - - Municipios - - #
chirps_mun_year_anomalies <- func_anomaly_pr(
    df = chirps_mun_year_long,
    df_normal = normal_pr_mm_mun_year)

chirps_mun_month_anomalies <- func_anomaly_pr(
    df = chirps_mun_month_long,
    df_normal = normal_pr_mm_mun_month)

#' **Muestra de `chirps_mun_month_anomalies`**

#| label: show_sample-chirps_mun_month_anomalies
#| echo: false
set.seed(1)
slice_sample(.data = chirps_mun_month_anomalies, n = 5)

#' ## Detalles finales
#' 
#' Como últimos pasos:
#'   * Se agregan los nombres de los estados y municipios
#'   * Para los conjuntos de datos de periodo mensual, se crea una columna 
#' en formato de fecha. Para todos los datos, el año, meses y semana se 
#' vuelve valor numérico
#' 
#' ### Adjuntar nombre de estados y municipios

#| label: create-func_adjuntar_cve_nom_ent_mun
db_cve_nom_ent_mun <- read_csv( # <1>
    file = here::here("GobiernoMexicano", "cve_nom_municipios.csv")) # <1>

func_adjuntar_cve_nom_ent_mun <- function(df, region) {
  if (region == "ent") { # <2>
    df_con_nombres <- left_join( # <2>
        x = df, # <2>
        y = distinct(.data = db_cve_nom_ent_mun, cve_ent, nombre_estado), # <2>
        by = join_by(cvegeo == cve_ent)) %>% # <2>
      rename(cve_ent = cvegeo) %>% # <2>
      relocate(nombre_estado, .after = cve_ent) # <2>
  } else { # <3>
    df_con_nombres <- left_join( # <3>
        x = df, # <3>
        y = db_cve_nom_ent_mun, # <3>
        by = join_by(cvegeo == cve_geo)) %>% # <3>
      select(-cve_mun) %>% # <3>
      rename(cve_geo = cvegeo) %>% # <3>
      relocate(cve_ent, .before = cve_geo) %>% # <3>
      relocate(nombre_estado, .after = cve_ent) %>% # <3>
      relocate(nombre_municipio, .after = cve_geo)} # <3>
  
  return(df_con_nombres)} # <4>

#' 1. Carga de base de datos de nombres y claves de estados y municipios
#' 2. Asignación y orden de nombres para estados
#' 3. Asignación y orden de nombres para municipios
#' 4. Se regresa el conjunto de datos con los nombres de las regiones
#' 
#' ### Formato numérico y de fecha para periodos

#| label: create-func_string2numberdate
func_string2numberdate <- function(df) {
  if ("n_month" %in% colnames(df)) {
    df_detalles_finales <- df %>%
      mutate(date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
      relocate(date_year_month, .before = n_year) %>%
      mutate(across(.cols = c(n_year, n_month), .fns = as.integer))
  } else {
    df_detalles_finales <- mutate(.data = df, n_year = as.integer(n_year))}
  
  return(df_detalles_finales)}

#' ### Creación de bases de datos de métricas de precipitación

#| label: create-dbs_finales
# - - Estados - - #
db_pr_ent_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_year_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_month_anomalies,
    region = "ent") %>%
  func_string2numberdate()

# - - Municipios - - #
db_pr_mun_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_year_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_month_anomalies,
    region = "mun") %>%
  func_string2numberdate()

#' ## Guardar bases de datos de métricas de precipitación
#' 
#' En la carpeta de `data` existen 3 carpetas:
#'   * `ee_imports`
#'   * `estados`
#'   * `municipios`
#'   * `normal`
#' 
#' La carpeta `ee_imports` son los archivos creados a partir de Google 
#' Earth Engine, y los conjuntos de datos creados por este script, se 
#' encuentran en las otras dos carpetas, `estados` y `municipios`
#' 
#' ### Estados
#' 
#' **Base de datos de métricas de precipitación anual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_ent_year.csv`**

#| label: save-db_pr_ent_year
write_csv(
  x = db_pr_ent_year,
  file = here::here(path2chirpsdata, "estados", "db_pr_ent_year.csv"),
  na = "")

#'

#| label: show_sample-db_pr_ent_year
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_ent_year, n = 5)

#' **Base de datos de métricas de precipitación mensual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_ent_month.csv`**

#| label: save-db_pr_ent_month
write_csv(
  x = db_pr_ent_month,
  file = here::here(path2chirpsdata, "estados", "db_pr_ent_month.csv"),
  na = "")

#' 

#| label: show_sample-db_pr_ent_month
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_ent_month, n = 5)

#' ### Municipios
#' 
#' **Base de datos de métricas de precipitación anual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_year.csv`**

#| label: save-db_pr_mun_year
write_csv(
  x = db_pr_mun_year,
  file = here::here(path2chirpsdata, "municipios", "db_pr_mun_year.csv"),
  na = "")

#'

#| label: show_sample-db_pr_mun_year
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_mun_year, n = 5)

#' **Base de datos de métricas de precipitación mensual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_month.csv.bz2`**

#| label: save-db_pr_mun_month
write_csv(
  x = db_pr_mun_month,
  file = here::here(path2chirpsdata, "municipios", "db_pr_mun_month.csv.bz2"),
  na = "")

#' ### Precipitaciones normales
#' 
#' **Base de datos de métricas de precipitación normal anual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_ent_year.csv`**

#| label: save-normal_pr_mm_ent_year
db_pr_normal_ent_year <- normal_pr_mm_ent_year %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

write_csv(
  x = db_pr_normal_ent_year,
  file = here::here(path2chirpsdata, "normal", "db_pr_normal_ent_year.csv"),
  na = "")

#'

#| label: show_sample_final-db_pr_normal_ent_year
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_normal_ent_year, n = 5)

#' **Base de datos de métricas de precipitación normal mensual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_ent_month.csv`**

#| label: save-db_pr_normal_ent_month
db_pr_normal_ent_month <- normal_pr_mm_ent_month %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

write_csv(
  x = db_pr_normal_ent_month
  file = here::here(path2chirpsdata, "normal", "db_pr_normal_ent_month.csv"),
  na = "")

#' 

#| label: show_sample_final-normal_pr_mm_ent_month
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_normal_ent_month, n = 5)

#' **Base de datos de métricas de precipitación normal anual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_mun_year.csv`**

#| label: save-db_pr_normal_mun_year
db_pr_normal_mun_year <- normal_pr_mm_mun_year %>%
  left_join(
    y = distinct(.data = db_cve_nom_ent_mun,
                 cve_geo,
                 nombre_estado,
                 cve_ent,
                 nombre_municipio),
    by = join_by(cvegeo == cve_geo)) %>%
  rename(cve_geo = cvegeo) %>%
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .after = nombre_estado) %>%
  relocate(nombre_municipio, .before = cve_geo)

write_csv(
  x = db_pr_normal_mun_year,
  file = here::here(path2chirpsdata, "normal", "db_pr_normal_mun_year.csv"),
  na = "")

#'

#| label: show_sample-db_pr_normal_mun_year
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_normal_mun_year, n = 5)

#' **Base de datos de métricas de precipitación normal mensual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_mun_month.csv`**

#| label: save-db_pr_normal_mun_month
db_pr_normal_mun_month <- normal_pr_mm_mun_month %>%
  left_join(
    y = distinct(.data = db_cve_nom_ent_mun,
                 cve_geo,
                 nombre_estado,
                 cve_ent,
                 nombre_municipio),
    by = join_by(cvegeo == cve_geo)) %>%
  rename(cve_geo = cvegeo) %>%
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .after = nombre_estado) %>%
  relocate(nombre_municipio, .before = cve_geo) %>%
  mutate(n_month = as.integer(n_month))

write_csv(
  x = db_pr_normal_mun_month,
  file = here::here(path2chirpsdata, "normal", "db_pr_normal_mun_month.csv"),
  na = "")

#' 

#| label: show_sample_final-db_pr_normal_mun_month
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_normal_mun_month, n = 5)
