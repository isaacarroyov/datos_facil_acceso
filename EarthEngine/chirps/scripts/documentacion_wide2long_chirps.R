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
#' La extracción de la **precipitación en milímetros (mm)** fue a través 
#' de Google Earth Engine. El periodo de extracción de los datos fue de 
#' 44 años, iniciando en 1981 hasta 2024. En total se tienen 352 archivos 
#' CSV en la carpeta **`EarthEngine/chirps/data/ee_imports`**
#' 
#' |**Tipo de archivo CSV**|**Número de archivos**|
#' |---|---|
#' |Precipitación anual de los estados|1 archivo por cada año :arrow_right: 44 archivos|
#' |Precipitación mensual de los estados|1 archivo por cada año :arrow_right: 44 archivos|
#' |Precipitación semanal de los estados|1 archivo por cada año :arrow_right: 44 archivos|
#' |Precipitación diaria de los estados|1 archivo por cada año :arrow_right: 44 archivos|
#' |Precipitación anual de los municipios|1 archivo por cada año :arrow_right: 44 archivos|
#' |Precipitación mensual de los municipios|1 archivo por cada año :arrow_right: 44 archivos|
#' |Precipitación semanal de los municipios|1 archivo por cada año :arrow_right: 44 archivos|
#' |Precipitación diaria de los municipios|1 archivo por cada año :arrow_right: 44 archivos|
#' 
#' El siguiente paso es poder unir todo en 8 archivos
#' 
#' * Anual: Precipitación en milímetros, anomalía [de precipitación] en 
#' milímetros (con respecto de la normal) y anomalía en porcentaje de los 
#' estados, de 1981 a 2024.
#' * Mensual: Precipitación en milímetros, anomalía en milímetros y 
#' anomalía en porcentaje de los estados, de 1981 a 2024.
#' * Semanal: Precipitación en milímetros, anomalía en milímetros y 
#' anomalía en porcentaje de los estados, de 1981 a 2024.
#' * Diaria: Precipitación en milímetros, anomalía en milímetros y 
#' anomalía en porcentaje de los estados, de 1981 a 2024.
#' * Anual: Precipitación en milímetros, anomalía en milímetros y 
#' anomalía en porcentaje de los municipios, de 1981 a 2024.
#' * Mensual: Precipitación en milímetros, anomalía en milímetros y 
#' anomalía en porcentaje de los municipios, de 1981 a 2024.
#' * Semanal: Precipitación en milímetros, anomalía en milímetros y 
#' anomalía en porcentaje de los municipios, de 1981 a 2024.
#' * Diaria: Precipitación en milímetros, anomalía en milímetros y 
#' anomalía en porcentaje de los municipios, de 1981 a 2024.

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
#' de `chirps_pr_mm_GEOMETRIA_PERIODO_AAAA.csv`, donde:
#' 
#' * `GEOMETRIA`: Indica las geometrías de la información, tales como 
#' `ent` (Estados) y `mun` (Municipios).
#' * `PERIODO`: Tiene los valores de los periodos de extracción, tales 
#' como `year` (anual), `month` (mensual), `week` (semanala) y 
#' `day` (diaria).
#' * `AAAA`: Indica el año de la información, de 1981 a 2024.
#' 
#' Para dividir en 8 grupos a todos los archivos, se usarán 2 partes del 
#' nombre: `_GEOMETRIA_PERIODO_`

#| label: load_chirp_files
# Obtener el nombre (path incluido) de todos los archivos que se 
# importaron de Google Earth Engine 
all_csv_chirps <- list.files(
    path = paste0(path2data, "/ee_imports"),
    pattern = "*.csv",
    full.names = TRUE)

# - - Entidades - - #
# ~ Diario ~ #
idx_ent_day <- str_detect(all_csv_chirps, "_ent_day_")
# ~ Semanal ~ #
idx_ent_week <- str_detect(all_csv_chirps, "_ent_week_")
# ~ Mensual ~ #
idx_ent_month <- str_detect(all_csv_chirps, "_ent_month_")
# ~ Anual ~ #
idx_ent_year <- str_detect(all_csv_chirps, "_ent_year_")

# - - Municipios - - #
# ~ Diario ~ #
idx_mun_day <- str_detect(all_csv_chirps, "_mun_day_")
# ~ Semanal ~ #
idx_mun_week <- str_detect(all_csv_chirps, "_mun_week_")
# ~ Mensual ~ #
idx_mun_month <- str_detect(all_csv_chirps, "_mun_month_")
# ~ Anual ~ #
idx_mun_year <- str_detect(all_csv_chirps, "_mun_year_")

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
# ~ Anual ~ #
chirps_ent_year <- map(
    .x = all_csv_chirps[idx_ent_year],  # <1> 
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>% # <2>
  bind_rows() %>% # <3>
  janitor::clean_names() %>% # <4>
  select(cvegeo, n_year, mean) # <5>

# ~ Mensual ~ #
chirps_ent_month <- map(
    .x = all_csv_chirps[idx_ent_month],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x"))) # <6>

# ~ Semanal ~ #
chirps_ent_week <- map(
    .x = all_csv_chirps[idx_ent_week],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>% 
  bind_rows() %>% 
  janitor::clean_names() %>% 
  select(c(cvegeo, n_year, starts_with("x"))) 

# ~ Diario ~ #
chirps_ent_day <- map(
    .x = all_csv_chirps[idx_ent_day],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_cols() %>% # <7>
  janitor::clean_names() %>%
  select(c(tidyselect::starts_with("cvegeo"), # <8>
           tidyselect::starts_with("x"))) # <8>

# - - Municipios - - #
# ~ Anual ~ #
chirps_mun_year <- map(
    .x = all_csv_chirps[idx_mun_year],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean)

# ~ Mensual ~ #
chirps_mun_month <- map(
    .x = all_csv_chirps[idx_mun_month],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Semanal ~ #
chirps_mun_week <- map(
    .x = all_csv_chirps[idx_mun_week],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Diario ~ #
chirps_mun_day <- map(
    .x = all_csv_chirps[idx_mun_day],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_cols() %>% 
  janitor::clean_names() %>%
  select(c(tidyselect::starts_with("cvegeo"),
           tidyselect::starts_with("x")))

#' 1. Seleccionar los paths de los archivos de interes
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
#' semana o mes (después de usar `janitor::clean_names`, todas inician con 
#' `x`).
#' 7. **Caso del periodo diario**: Cada columna es un día del año, por lo 
#' que usar `dplyr::bind_rows()` no es de utilidad porque cada año habrá un 
#' gran espacio de columnas vacias, así que se usa `dplyr::bind_cols()`
#' 8. **Caso del periodo diario**: Como se repite mucho la columna `cvegeo`, 
#' entonces se seleccionan todas las que incian así. Más adelante en el 
#' procesamiento de datos se arregla este _detalle_

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

#' **Muestra de datos: Precipitación en milímetros semanal a nivel estatal**

#| label: show_sample-chirps_ent_week 
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_week, n = 5)

#' **Muestra de datos: Precipitación en milímetros diario a nivel estatal**

#| label: show_sample-chirps_ent_day 
#| echo: false
set.seed(1)
slice_sample(.data = chirps_ent_day, n = 5) %>%
  select(cvegeo_367, cvegeo_2223, tidyselect::starts_with("x2024082"))

#' ### Decisiones sobre los datos
#' 
#' > [!NOTE] 
#' > 
#' > Como lo indican los objetivos, no solo estará la Precipitación (mm), 
#' también se contará con las anomalías, por lo que se tendrá 
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
func_wide2long <- function(df, periodo) {
  
  if (periodo %in% c("day", "week", "month")) { # <1>
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
    
    if(periodo == "day") { # <3>
      df_transformed <- rename(.data = df_pivoted, # <3>
                               full_date = period) # <3>
    } else if (periodo == "week") {
      df_transformed <- rename(.data = df_pivoted, # <3>
                               n_week = period) # <3>
    } else {
      df_transformed <- rename(.data = df_pivoted, # <3>
                               n_month = period)} # <3>
  } else { # <4>
    df_transformed <- df %>% # <4>
      rename(pr_mm = mean) %>% # <4>
      mutate(pr_mm = as.numeric(pr_mm))} # <4>

  return(df_transformed)} # <5>

#' 1. Si el periodo es diario, semanal o mensual se usa `pivot_longer`
#' 2. Se cambia el valor de la precipitación a numérico y se eliminan las 
#' `x` + `_precipitation` del número de los días, semanas y meses.
#' 3. Se renombra dependiendo del tipo de periodo
#' 4. Si `df` no es de más de 4 columnas, es porque el periodo es anual y 
#' solamente se renombra la columna `mean` a `pr_mm` y se comvierte a valor 
#' numérico
#' 5. Se regresa el conjunto de datos con los cambios

#| label: create-long_chirps
# - - Estados - - #
chirps_ent_year_long <- func_wide2long(df = chirps_ent_year, periodo = "year")
chirps_ent_month_long <- func_wide2long(df = chirps_ent_month, periodo = "month")
chirps_ent_week_long <- func_wide2long(df = chirps_ent_week, periodo = "week")
chirps_ent_day_long <- func_wide2long(
    df = chirps_ent_day,
    periodo = "day") %>%
  select(1, full_date, pr_mm) %>%
  mutate(full_date = ymd(full_date)) %>%
  rename(cvegeo = cvegeo_367)
                
# - - Municipios - - #
chirps_mun_year_long <- func_wide2long(df = chirps_mun_year, periodo = "year")
chirps_mun_month_long <- func_wide2long(df = chirps_mun_month, periodo = "month")
chirps_mun_week_long <- func_wide2long(df = chirps_mun_week, periodo = "week")
chirps_mun_day_long <- func_wide2long(
    df = chirps_mun_day,
    periodo = "day") %>%
  select(1, full_date, pr_mm) %>%
  mutate(full_date = ymd(full_date)) %>%
  rename(cvegeo = cvegeo_367)

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
  
  if ("n_week" %in% colnames(df)) { # <1>
    df_normal_pr_mm <- df %>% # <1>
      filter(n_year %in% 1981:2010) %>% # <1>
      group_by(cvegeo, n_week) %>% # <1>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <1>
      ungroup() # <1>

  } else if ("n_month" %in% colnames(df)) { # <2>
    df_normal_pr_mm <- df %>% # <2>
      filter(n_year %in% 1981:2010) %>% # <2>
      group_by(cvegeo, n_month) %>% # <2>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <2>
      ungroup() # <2>

  } else if ("full_date" %in% colnames(df)){ # <3>
    df_normal_pr_mm <- df %>% # <3>
      filter(year(full_date) %in% 1981:2010) %>% # <3>
      group_by( # <3>
        cvegeo, # <3>
        n_month = month(full_date), # <3>
        n_day = day(full_date)) %>% # <3>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <3>
      ungroup() # <3>
  } else { 
    df_normal_pr_mm <- df %>% # <4>
      filter(n_year %in% 1981:2010) %>% # <4>
      group_by(cvegeo) %>% # <4>
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>% # <4>
      ungroup() # <4>
  }
  
  return(df_normal_pr_mm)} # <5>

#' 1. Filtro de los 30 años _base_ y agrupación si `df` es de periodo semanal
#' 2. Filtro de los 30 años _base_ y agrupación si `df` es de periodo mensual
#' 3. Filtro de los 30 años _base_ y agrupación si `df` es de periodo diaria
#' 4. Filtro de los 30 años _base_ y agrupación si `df` es de periodo anual
#' 5. Conjunto de valores normales

#| label: create-normal_pr_mm
# - - Estados - - #
normal_pr_mm_ent_year <- func_normal_pr_mm(df = chirps_ent_year_long)
normal_pr_mm_ent_month <- func_normal_pr_mm(df = chirps_ent_month_long)
normal_pr_mm_ent_week <- func_normal_pr_mm(df = chirps_ent_week_long)
normal_pr_mm_ent_day <- func_normal_pr_mm(df = chirps_ent_day_long)

# - - Municipio - - #
normal_pr_mm_mun_year <- func_normal_pr_mm(df = chirps_mun_year_long)
normal_pr_mm_mun_month <- func_normal_pr_mm(df = chirps_mun_month_long)
normal_pr_mm_mun_week <- func_normal_pr_mm(df = chirps_mun_week_long)
normal_pr_mm_mun_day <- func_normal_pr_mm(df = chirps_mun_day_long)

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

  } else if("full_date" %in% colnames(df)) { # <5>
    df_anomaly_pr <- left_join( # <5>
        x = df %>% # <5>
              mutate( # <5>
                n_month = month(full_date), # <5>
                n_day = day(full_date)), # <5>
        y = df_normal, # <5>
        by = join_by(cvegeo, n_month, n_day)) %>% # <5>
      mutate( # <5>
        anomaly_pr_mm = pr_mm - normal_pr_mm, # <5>
        anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>% # <5>
      select(-normal_pr_mm) # <5>
    
  } else { # <6>
    df_anomaly_pr <- left_join( # <6>
      x = df, # <6>
      y = df_normal, # <6>
      by = join_by(cvegeo)) %>% # <6>
    mutate( # <6>
      anomaly_pr_mm = pr_mm - normal_pr_mm, # <6>
      anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>% # <6>
    select(-normal_pr_mm)} # <6>
  
  return(df_anomaly_pr)} # <7>

#' 1. Se usa un `lef_join` para unir los datos de precipitación con la 
#' precipitación normal. Se unen por región y periodo (este caso, semanal)
#' 2. Se hace el cálculo de las anomalías
#' 3. Se _elimina_ la columna que indica el valor de la precipitación normal
#' 4. Proceso 1-3 para periodo mensual
#' 5. Proceso 1-3 para periodo diario
#' 6. Proceso para periodo anual. Para este caso se une por el periodo, 
#' únicamente por la región
#' 7. Se regresa el conjunto de datos con las anomalías integradas

#| label: create-anomalies_df
# - - Estados - - #
chirps_ent_year_anomalies <- func_anomaly_pr(
    df = chirps_ent_year_long,
    df_normal = normal_pr_mm_ent_year)

chirps_ent_month_anomalies <- func_anomaly_pr(
    df = chirps_ent_month_long,
    df_normal = normal_pr_mm_ent_month)

chirps_ent_week_anomalies <- func_anomaly_pr(
    df = chirps_ent_week_long,
    df_normal = normal_pr_mm_ent_week)

chirps_ent_day_anomalies <- func_anomaly_pr(
    df = chirps_ent_day_long,
    df_normal = normal_pr_mm_ent_day)

# - - Municipios - - #
chirps_mun_year_anomalies <- func_anomaly_pr(
    df = chirps_mun_year_long,
    df_normal = normal_pr_mm_mun_year)

chirps_mun_month_anomalies <- func_anomaly_pr(
    df = chirps_mun_month_long,
    df_normal = normal_pr_mm_mun_month)

chirps_mun_week_anomalies <- func_anomaly_pr(
    df = chirps_mun_week_long,
    df_normal = normal_pr_mm_mun_week)

chirps_mun_day_anomalies <- func_anomaly_pr(
    df = chirps_mun_day_long,
    df_normal = normal_pr_mm_mun_day)
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
db_pr_ent_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_year_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_month_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_week <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_week_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_day <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_day_anomalies,
    region = "ent") %>%
    mutate(n_year = year(full_date)) %>%
    relocate(n_month, .after = n_year) %>%
    relocate(n_day, .after = n_month)

# - - Municipios - - #
db_pr_mun_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_year_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_month_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_week <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_week_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_day <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_day_anomalies,
    region = "mun") %>%
    mutate(n_year = year(full_date)) %>%
    relocate(n_month, .after = n_year) %>%
    relocate(n_day, .after = n_month)

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

#' **Base de datos de métrias de precipitación diaria a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_ent_day.csv`**

#| label: save-db_pr_ent_day
write_csv(
    x = db_pr_ent_day,
    file = paste0(path2data, "/estados/db_pr_ent_day.csv.bz2"),
    na = "")

#'

#| label: show_sample-db_pr_ent_day
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_ent_day, n = 5)

#' ### Municipios
#' 
#' **Base de datos de métrias de precipitación anual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_year.csv`**

#| label: save-db_pr_mun_year
write_csv(
    x = db_pr_mun_year,
    file = paste0(path2data, "/municipios/db_pr_mun_year.csv"),
    na = "")

#'

#| label: show_sample-db_pr_mun_year
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_mun_year, n = 5)

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

#' **Base de datos de métrias de precipitación diaria a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_day.csv.bz2`**

#| label: save-db_pr_mun_day
write_csv(
    x = db_pr_mun_day,
    file = paste0(path2data, "/municipios/db_pr_mun_day.csv.bz2"),
    na = "")

#'

#| label: show_sample-db_pr_mun_day
#| echo: false
set.seed(1)
slice_sample(.data = db_pr_mun_day, n = 5)

#' ### Precipitaciones normales
#' 
#' **Base de datos de métrias de precipitación normal anual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_ent_year.csv`**

#| label: save-normal_pr_mm_ent_year
normal_pr_mm_ent_year %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_year.csv"),
    na = "")

#'

#| label: show_sample_final-normal_pr_mm_ent_year
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_ent_year, n = 5) %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

#' **Base de datos de métrias de precipitación normal mensual a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_ent_month.csv`**

#| label: save-normal_pr_mm_ent_month
normal_pr_mm_ent_month %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_month.csv"),
    na = "")

#' 

#| label: show_sample-normal_pr_mm_ent_month
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_ent_month, n = 5) %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

#' **Base de datos de métrias de precipitación normal semanal a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_ent_week.csv`**

#| label: save-normal_pr_mm_ent_week
normal_pr_mm_ent_week %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_week.csv"),
    na = "")

#'

#| label: show_sample-normal_pr_mm_ent_week
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_ent_week, n = 5) %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

#' **Base de datos de métrias de precipitación normal diaria a nivel estatal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_ent_day.csv`**

#| label: save-normal_pr_mm_ent_day
normal_pr_mm_ent_day %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_day.csv"),
    na = "")

#'

#| label: show_sample-normal_pr_mm_ent_day
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_ent_day, n = 5) %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

#' **Base de datos de métrias de precipitación normal anual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_mun_year.csv`**

#| label: save-normal_pr_mm_mun_year
normal_pr_mm_mun_year %>%
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
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_year.csv"),
    na = "")

#'

#| label: show_sample-normal_pr_mm_mun_year
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_mun_year, n = 5) %>%
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

#' **Base de datos de métrias de precipitación normal mensual a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_mun_month.csv`**

#| label: save-normal_pr_mm_mun_month
normal_pr_mm_mun_month %>%
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
  mutate(n_month = as.integer(n_month)) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_month.csv"),
    na = "")

#' 

#| label: show_sample-normal_pr_mm_mun_month
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_mun_month, n = 5) %>%
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

#' **Base de datos de métrias de precipitación semanal a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_mun_week.csv.bz2`**

#| label: save-normal_pr_mm_mun_week
normal_pr_mm_mun_week %>%
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
  mutate(n_week = as.integer(n_week)) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_week.csv"),
    na = "")

#'

#| label: show_sample-normal_pr_mm_mun_week
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_mun_week, n = 5) %>%
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
  mutate(n_week = as.integer(n_week))

#' **Base de datos de métrias de precipitación normal diaria a nivel municipal**
#' 
#' Se guarda bajo el nombre **`db_pr_normal_mun_day.csv.bz2`**

#| label: save-normal_pr_mm_mun_day
normal_pr_mm_mun_day %>%
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
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_day.csv.bz2"),
    na = "")

#'

#| label: show_sample-normal_pr_mm_mun_day
#| echo: false
set.seed(1)
slice_sample(.data = normal_pr_mm_mun_day, n = 5) %>%
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

