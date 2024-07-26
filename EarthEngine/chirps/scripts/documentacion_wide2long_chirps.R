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
#' 
#' > [!NOTE]
#' > 
#' > Se puede observar que se cambia el directorio de trabajo a la carpeta 
#' **`/EarthEngine/chirps/scripts`** para después agregar `/../../..` en la 
#' variable **`path2main`**. Este cambio se hace para que al renderizar, el 
#' código se pueda ejecutar correctamente, ya que el archivo toma como 
#' directorio de trabajo la carpeta en la que se encuentra el script en el 
#' que se esta haciendo el código.

#| label: setworkingdir
#| eval: false

setwd("./EarthEngine/chirps/scripts")

#' ## Introducción y objetivos
#' 
#' La extracción de la Precipitación en milímetros (mm) través de Google 
#' Earth Engine se hizo para todos los estados y municipios de manera 
#' mensual, semanal y anual. Esto quiere decir que se tiene un total 
#' de 264 CSVs:
#' 
#' * Precipitación en milímtros:
#'   * Semanal en los estados: 44 archivos (1 archivo por cada año, de 1981 a 2024)
#'   * Mensual en los estados: 44 archivos 
#'   * Anual en los estados: 44 archivos
#'   * Semanal en los municipios: 44 archivos
#'   * Mensual en los municipios: 44 archivos
#'   * Anual en los municipios: 44 archivos
#' 
#' El siguiente paso es poder unir todos en 6 archivos
#' 
#' * Precipitación en milímetros, anomalía (de precipitación) en 
#' milímetros (con respecto de la normal) y anomalía en porcentaje semanal 
#' de los estados, de 1981 a 2024.
#' * Precipitación en milímetros, anomalía (de precipitación) en 
#' milímetros (con respecto de la normal) y anomalía en porcentaje mensual 
#' de los estados, de 1981 a 2024.
#' * Precipitación en milímetros, anomalía (de precipitación) en 
#' milímetros (con respecto de la normal) y anomalía en porcentaje anual 
#' de los estados, de 1981 a 2024.
#' * Precipitación en milímetros, anomalía (de precipitación) en 
#' milímetros (con respecto de la normal) y anomalía en porcentaje semanal 
#' de los municipios, de 1981 a 2024.
#' * Precipitación en milímetros, anomalía (de precipitación) en 
#' milímetros (con respecto de la normal) y anomalía en porcentaje mensual 
#' de los municipios, de 1981 a 2024.
#' * Precipitación en milímetros, anomalía (de precipitación) en 
#' milímetros (con respecto de la normal) y anomalía en porcentaje anual 
#' de los municipios, de 1981 a 2024.

#| label: load-necesarios
#| output: false
Sys.setlocale(locale = "es_ES")
library(tidyverse)

path2main <- paste0(getwd(), "/../../..")
path2ee <- paste0(path2main, "/EarthEngine")
path2chirps <- paste0(path2ee, "/chirps")
path2data <- paste0(path2chirps, "/data")

#' ## Los conjuntos de datos
#' 
#' ### Ubicación de los archivos
#' 
#' Todos los archivos se encuentran en una misma carpeta, lo que los 
#' distingue es el nombre del archivo. El nombre tiene la estructura 
#' de `METRICA_GEOMETRIA_PERIODO_AAAA.csv`, donde:
#' 
#' * `METRICA`: El valor `pr` (Precipitación en milímetros)
#' * `GEOMETRIA`: Indica las geometrías de la información, tales como 
#' `ent` (Estados) y `mun` (Municipios)
#' * `PERIODO`: Tiene los valores de los periodos de extracción, tales 
#' como  `week` (semanala), `month` (mensual) y `year` (anual)
#' * `AAAA`: Indica el año de la información, de 1981 a 2024
#' 
#' Para dividir en 6 grupos a todos los archivos, se usarán las primeras 
#' 3 partes del nombre: `METRICA_GEOMETRIA_PERIODO`

#| label: load_chirp_files
# Obtener el nombre (path incluido) de todos los archivos que se 
# importaron de Google Earth Engine 
all_csv_chirps <- list.files(
    path = paste0(path2data, "/ee_imports"),
    pattern = "*.csv",
    full.names = TRUE)

# - - Entidades - - #
# ~ Semanal ~ #
idx_ent_week <- str_detect(all_csv_chirps, "pr_ent_week")
# ~ Mensual ~ #
idx_ent_month <- str_detect(all_csv_chirps, "pr_ent_month")
# ~ Anual ~ #
idx_ent_year <- str_detect(all_csv_chirps, "pr_ent_year")

# - - Municipios - - #
# ~ Semanal ~ #
idx_mun_week <- str_detect(all_csv_chirps, "pr_mun_week")
# ~ Mensual ~ #
idx_mun_month <- str_detect(all_csv_chirps, "pr_mun_month")
# ~ Anual ~ #
idx_mun_year <- str_detect(all_csv_chirps, "pr_mun_year")

#' Las variables `idx_` son vectores booleanos que indican la posición 
#' en la que se encuentra un archivo que coincide con el patron de 
#' caracteres deseado. Cada uno de esos vectores tiene 
#' `{r} length(all_csv_chirps[idx_ent_week])` elementos, los cuales tienen 
#' que ser leeidos como `tibbles` y concatenados. De esta manera se tiene 
#' en un `tibble`, la información de 44 años de precipitación (divididos 
#' semanal, mensual o anualmente).
#' 
#' ### Carga de los archivos
#' 
#' Para poder leer y unir 44 archivos en uno solo, se usa `purrr::map`. 
#' `purrr` es una librería que forma parte del `{tidyverse}`, por lo que ya 
#' se encuentra cargada en el ambiante. Con `map` se leeran los paths de los 
#' archivos de interés (dados por `idx_`).

#| label: concat_all_files

# - - Entidades - - #
# ~ Semanal ~ #
chirps_ent_week <- map(
    .x = all_csv_chirps[idx_ent_week], # <1> 
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>% # <2>
  bind_rows() %>% # <3>
  janitor::clean_names() %>% # <4>
  select(c(cvegeo, n_year, starts_with("x"))) # <5>

# ~ Mensual ~ #
chirps_ent_month <- map(
    .x = all_csv_chirps[idx_ent_month],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Anual ~ #
chirps_ent_year <- map(
    .x = all_csv_chirps[idx_ent_year],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean) # <6>

# - - Municipios - - #
# ~ Semanal ~ #
chirps_mun_week <- map(
    .x = all_csv_chirps[idx_mun_week],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Mensual ~ #
chirps_mun_month <- map(
    .x = all_csv_chirps[idx_mun_month],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Anual ~ #
chirps_mun_year <- map(
    .x = all_csv_chirps[idx_mun_year],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean)

#' 1. Seleccionar los paths de los archivos de interes
#' 2. Usar una función anónima para poder dar valor a más argumentos 
#' (como que todas las columnas sean leídas como _strings_) de la 
#' función `read_csv`
#' 3. Todos los `tibbles` se guardan en una lista, por lo que para unirlos 
#' en un solo `tibble` se concatenan por las filas
#' 4. Limpieza de nombres de columnas
#' 5. Las columnas de interés son las que tienen el código del estado o 
#' municipio (`cvegeo`), el año de la información (`n_year`) y el número de 
#' semana o mes (después de usar `janitor::clean_names`, todas inician con 
#' `x`).
#' 6. Para el caso de la precipitación anual, como el reductor principal 
#' fue 'mean', ese es el nombre de la columna de información
#' 
#' **Muestra de datos: Precipitación en milímetros semanal a nivel estatal**

#| label: show_sample-chirps_ent_week 
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_week, n = 5)

#' **Muestra de datos: Precipitación en milímetros mensual a nivel estatal**

#| label: show_sample-chirps_ent_month
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_month, n = 5)

#' **Muestra de datos: Precipitación en milímetros anual a nivel estatal**

#| label: show_sample-chirps_ent_year
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_year, n = 5)

#' ### Decisiones sobre los datos
#' 
#' > [!NOTE]
#' > Como lo indican los objetivos, no solo estará la Precipitación en 
#' milímetros, también se contará con las anomalías, por lo que se tendrá 
#' que incorporar este cálculo en el flujo de trabajo.
#' > 
#' > Esta es una solución temporal, en lo que se arregla el código de la 
#' extracción de las anomalías directamente de Google Earth Engine. 
#' 
#' 1. Transformar el formato _wide_ a _long_, para tener el número de 
#' semanas y meses como una columna. Para el caso de los datos anuales, 
#' únicamente renombrar la columna `mean` a `pr`
#' 2. Cambiar a número el valor de la precipitación.
#' 3. Crear los respectivos `tibble`s de promedio normal de precipitación 
#' para cada uno de los archivos.
#' 4. Crear las columnas de las anomalías de precipitación en milímetros 
#' (`anomaly_pr_mm`) y porcentaje (`anomaly_pr_prop`).
#' 
#' ## _Wide to Long_
#' 
#' Para facilitar la transformación se va crear una función que haga el 
#' pivote dependiendo del número de columnas en el `tibble`.

#| label: create-func_wide2long
func_wide2long <- function(df) {
  
  n_cols = ncol(df) # <1>

  if (n_cols >= 4) { # <2>
    df_pivoted <- df %>% # <2>
      pivot_longer( # <2>
        cols = starts_with("x"), # <2>
        names_to = "period", # <2>
        values_to = "pr_mm") %>% # <2>
      mutate( # <3>
        pr_mm = as.numeric(pr_mm), # <3>
        period = str_remove(string = period, pattern = "x")) # <3>
    
    if(n_cols >= 15) {df_transformed <- rename( # <4>
                          .data = df_pivoted, # <4>
                          n_week = period) # <4>
    } else { df_transformed <- rename( # <5>
               .data = df_pivoted, # <5>
               n_month = period)} # <5>
  
  } else { # <6>
    df_transformed <- df %>% # <6>
      rename(pr_mm = mean) %>% # <6>
      mutate(pr_mm = as.numeric(pr_mm))} # <6>

  return(df_transformed)} # <7>

#' 1. Identificar el número de columnas
#' 2. Si son más de 4 columnas, entonces son los periodos semanales y 
#' mensuales y se hace el `pivot_longer`
#' 3. Se cambia el valor de la precipitación a numérico y se eliminan las 
#' `x` del numero de las semanas y meses.
#' 4. Si `df` es de semanas (+15 columnas), se renombra `period` a `n_week` 
#' 5. Si `df` es de meses, se renombra `period` a `n_month`
#' 6. Si `df` no es de más de 4 columnas, es porque el periodo es anual y 
#' solamente se renombra la columna `mean` a `pr_mm` y se comvierte a valor 
#' numérico
#' 7. Se regresa el conjunto de datos con los cambios

#| label: create-long_chirps
# - - Estados - - #
chirps_ent_week_long <- func_wide2long(df = chirps_ent_week)
chirps_ent_month_long <- func_wide2long(df = chirps_ent_month)
chirps_ent_year_long <- func_wide2long(df = chirps_ent_year)

# - - Municipios - - #
chirps_mun_week_long <- func_wide2long(df = chirps_mun_week)
chirps_mun_month_long <- func_wide2long(df = chirps_mun_month)
chirps_mun_year_long <- func_wide2long(df = chirps_mun_year)

#' **Muestra de datos de `chirps_mun_week_long`**

#| label: show_sample-chirps_mun_week_long
#| echo: false
set.seed(1)
slice_sample(.data = chirps_mun_week_long, n = 5)

#' ## Precipitación normal (1981 - 2010)
#' 
#' Para facilitar el cálculo se va crear una función que la precipitación 
#' normal dependiendo del periodo de la información.

#| label: create-func_normal_pr_mm
func_normal_pr_mm <- function(df) {
  
  df_base <- filter(.data = df, n_year %in% 1981:2010) # <1>

  if ("n_week" %in% colnames(df)) { # <2>
    df_normal_pr_mm <- df_base %>% # <2>
      group_by(cvegeo, n_week) %>% # <2>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <2>
      ungroup() # <2>

  } else if ("n_month" %in% colnames(df)) { # <3>
    df_normal_pr_mm <- df_base %>% # <3>
      group_by(cvegeo, n_month) %>% # <3>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <3>
      ungroup() # <3>

  } else { # <3>
    df_normal_pr_mm <- df_base %>% # <4>
      group_by(cvegeo) %>% # <4>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <4>
      ungroup()} # <4>
  
  return(df_normal_pr_mm)} # <5>

#' 1. Filtro de los 30 años _base_
#' 2. Agrupación si `df` es de periodo semanal
#' 3. Agrupación si `df` es de periodo mensual
#' 4. Agrupación si `df` es de periodo anual
#' 5. `tibble` de precipitación normal para cada región

#| label: create-normal_pr_mm

# - - Estados - - #
normal_pr_mm_ent_week <- func_normal_pr_mm(df = chirps_ent_week_long)
normal_pr_mm_ent_month <- func_normal_pr_mm(df = chirps_ent_month_long)
normal_pr_mm_ent_year <- func_normal_pr_mm(df = chirps_ent_year_long)

# - - Municipio - - #
normal_pr_mm_mun_week <- func_normal_pr_mm(df = chirps_mun_week_long)
normal_pr_mm_mun_month <- func_normal_pr_mm(df = chirps_mun_month_long)
normal_pr_mm_mun_year <- func_normal_pr_mm(df = chirps_mun_year_long)

#' **Muestra de `normal_pr_mm_ent_year`**

#| label: show_sample-normal_pr_mm_ent_year
#| echo: false

set.seed(1)
slice_sample(.data = normal_pr_mm_ent_year, n = 5)
 
#' ## Cálculo de anomalías
#' 
#' ### Anomalía en milimetros
#' 
#' Es la diferencia en milimetros, de la precipitación de un determinado 
#' mes $\left( \overline{x}_{i} \right)$ y el promedio histórico o la normal 
#' $\left( \mu_{\text{normal}} \right)$ de ese mes
#' 
#' $$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$
#' 
#' ### Anomalía en porcentaje
#' 
#' Es el resultado de dividir la diferencia de la precipitación de un 
#' determinado mes $\left( \overline{x}_{i} \right)$ y el promedio 
#' histórico o la normal $\left( \mu_{\text{normal}} \right)$ entre la normal 
#' de ese mismo mes.
#' 
#' $$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$
#' 
#' ### Función para cálculo de anomalías
#' 
#' La función tomará dos `tibble`s, el de la información de precipitación 
#' y el de la precipitación normal.

#| label: create-func_anomaly_pr
func_anomaly_pr <- function(df, df_normal) {

  if ("n_week" %in% colnames(df)) { 
    df_anomaly_pr <- left_join( # <1>
      x = df, # <1>
      y = df_normal, # <1>
      by = join_by(cvegeo, n_week)) %>% # <1>
    mutate( # <2>
      anomaly_pr_mm = pr_mm - normal_pr_mm, # <2>
      anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>% # <2>
    select(-normal_pr_mm) # <3>

  } else if ("n_month" %in% colnames(df)) { # <4>
    df_anomaly_pr <- left_join( # <4>
      x = df, # <4>
      y = df_normal, # <4>
      by = join_by(cvegeo, n_month)) %>% # <4>
    mutate( # <4>
      anomaly_pr_mm = pr_mm - normal_pr_mm, # <4>
      anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>% # <4>
    select(-normal_pr_mm) # <4>

  } else { # <5>
    df_anomaly_pr <- left_join( # <5>
      x = df, # <5>
      y = df_normal, # <5>
      by = join_by(cvegeo)) %>% # <5>
    mutate( # <5>
      anomaly_pr_mm = pr_mm - normal_pr_mm, # <5>
      anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>% # <5>
    select(-normal_pr_mm)} # <5>
  
  return(df_anomaly_pr)} # <6>

#' 1. Se usa un `lef_join` para unir los datos de precipitación con la 
#' precipitación normal. Se unen por región y periodo (este caso, semanal)
#' 2. Se hace el cálculo de las anomalías
#' 3. Se _elimina_ la columna que indica el valor de la precipitación normal
#' 4. Proceso 1-3 para periodo mensual
#' 5. Proceso para periodo anual. Para este caso se une por el periodo, 
#' únicamente por la región
#' 6. Se regresa el conjunto de datos con las anomalías integradas

#| label: create-anomalies_df
# - - Estados - - #
chirps_ent_week_anomalies <- func_anomaly_pr(
    df = chirps_ent_week_long,
    df_normal = normal_pr_mm_ent_week)

chirps_ent_month_anomalies <- func_anomaly_pr(
    df = chirps_ent_month_long,
    df_normal = normal_pr_mm_ent_month)

chirps_ent_year_anomalies <- func_anomaly_pr(
    df = chirps_ent_year_long,
    df_normal = normal_pr_mm_ent_year)

# - - Municipios - - #
chirps_mun_week_anomalies <- func_anomaly_pr(
    df = chirps_mun_week_long,
    df_normal = normal_pr_mm_mun_week)

chirps_mun_month_anomalies <- func_anomaly_pr(
    df = chirps_mun_month_long,
    df_normal = normal_pr_mm_mun_month)

chirps_mun_year_anomalies <- func_anomaly_pr(
    df = chirps_mun_year_long,
    df_normal = normal_pr_mm_mun_year)

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
    file = paste0(path2main, "/GobiernoMexicano/cve_nom_municipios.csv")) # <1>

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
  if ("n_week" %in% colnames(df)) {
    df_detalles_finales <- df %>%
      mutate(
        across(
          .cols = c(n_year, n_week),
          .fns = as.integer))

  } else if ("n_month" %in% colnames(df)) {
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
db_pr_ent_week <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_week_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_month_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_year_anomalies,
    region = "ent") %>%
  func_string2numberdate()

# - - Municipios - - #
db_pr_mun_week <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_week_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_month_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_year_anomalies,
    region = "mun") %>%
  func_string2numberdate()

#' ## Guardar bases de datos de métricas de precipitación
#' 
#' En la carpeta de `data` existen 3 carpetas:
#'   * `ee_imports`
#'   * `estados`
#'   * `municipios`
#' 
#' La carpeta `ee_imports` son los archivos creados a partir de Google 
#' Earth Engine, y los conjuntos de datos creados por este script, se 
#' encuentran en las otras dos carpetas, `estados` y `municipios`
#' 
#' ### Estados
#' 
#' **Base de datos de métrias de precipitación semanal a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_ent_week.csv`**

#| label: save-db_pr_ent_week
write_csv(
    x = db_pr_ent_week,
    file = paste0(path2data, "/estados/db_pr_ent_week.csv"),
    na = "")

#'

#| label: show_sample-db_pr_ent_week
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_ent_week, n = 5)

#' **Base de datos de métrias de precipitación mensual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_ent_month.csv`**

#| label: save-db_pr_ent_month
write_csv(
    x = db_pr_ent_month,
    file = paste0(path2data, "/estados/db_pr_ent_month.csv"),
    na = "")

#' 

#| label: show_sample-db_pr_ent_month
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_ent_month, n = 5)

#' **Base de datos de métrias de precipitación anual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_ent_year.csv`**

#| label: save-db_pr_ent_year
write_csv(
    x = db_pr_ent_year,
    file = paste0(path2data, "/estados/db_pr_ent_year.csv"),
    na = "")

#'

#| label: show_sample-db_pr_ent_year
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_ent_year, n = 5)


#' ### Municipios
#' 
#' **Base de datos de métrias de precipitación semanal a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_week.csv.bz2`**

#| label: save-db_pr_mun_week
write_csv(
    x = db_pr_mun_week,
    file = paste0(path2data, "/municipios/db_pr_mun_week.csv.bz2"),
    na = "")

#'

#| label: show_sample-db_pr_mun_week
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_mun_week, n = 5)

#' **Base de datos de métrias de precipitación mensual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_month.csv.bz2`**

#| label: save-db_pr_mun_month
write_csv(
    x = db_pr_mun_month,
    file = paste0(path2data, "/municipios/db_pr_mun_month.csv.bz2"),
    na = "")

#' 

#| label: show_sample-db_pr_mun_month
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_mun_month, n = 5)

#' **Base de datos de métrias de precipitación anual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_year.csv`**

#| label: save-db_pr_mun_year
write_csv(
    x = db_pr_ent_year,
    file = paste0(path2data, "/municipios/db_pr_mun_year.csv"),
    na = "")

#'

#| label: show_sample-db_pr_mun_year
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_mun_year, n = 5)