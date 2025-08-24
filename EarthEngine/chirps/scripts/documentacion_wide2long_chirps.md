# CHIRPS: Extracción y procesamiento de datos de lluvia II


- [<span class="toc-section-number">1</span> Introducción y objetivos](#introducción-y-objetivos)
- [<span class="toc-section-number">2</span> Los conjuntos de datos](#los-conjuntos-de-datos)
  - [<span class="toc-section-number">2.1</span> Ubicación de los archivos](#ubicación-de-los-archivos)
  - [<span class="toc-section-number">2.2</span> Carga de los archivos](#carga-de-los-archivos)
  - [<span class="toc-section-number">2.3</span> Decisiones sobre los datos](#decisiones-sobre-los-datos)
- [<span class="toc-section-number">3</span> Agregar el promedio nacional a `chirps_ent_month` y `chirps_ent_year`](#agregar-el-promedio-nacional-a-chirps_ent_month-y-chirps_ent_year)
- [<span class="toc-section-number">4</span> *Wide to Long*](#wide-to-long)
  - [<span class="toc-section-number">4.1</span> Sobre la precipitación acumulada a través del año en milímetros](#sobre-la-precipitación-acumulada-a-través-del-año-en-milímetros)
- [<span class="toc-section-number">5</span> Precipitación normal (1981 - 2010)](#precipitación-normal-1981---2010)
- [<span class="toc-section-number">6</span> Cálculo de métricas](#cálculo-de-métricas)
  - [<span class="toc-section-number">6.1</span> Anomalía en milimetros](#anomalía-en-milimetros)
  - [<span class="toc-section-number">6.2</span> Anomalía en proporción de la normal](#anomalía-en-proporción-de-la-normal)
  - [<span class="toc-section-number">6.3</span> Anomalía de la precipitación acumulada en milimetros](#anomalía-de-la-precipitación-acumulada-en-milimetros)
  - [<span class="toc-section-number">6.4</span> Anomalía de la precipitación acumulada en proporción de la normal](#anomalía-de-la-precipitación-acumulada-en-proporción-de-la-normal)
  - [<span class="toc-section-number">6.5</span> Función para cálculo de anomalías](#función-para-cálculo-de-anomalías)
- [<span class="toc-section-number">7</span> Detalles finales](#detalles-finales)
  - [<span class="toc-section-number">7.1</span> Adjuntar nombre de estados y municipios](#adjuntar-nombre-de-estados-y-municipios)
  - [<span class="toc-section-number">7.2</span> Formato numérico y de fecha para periodos](#formato-numérico-y-de-fecha-para-periodos)
  - [<span class="toc-section-number">7.3</span> Creación de bases de datos de métricas de precipitación](#creación-de-bases-de-datos-de-métricas-de-precipitación)
- [<span class="toc-section-number">8</span> Guardar bases de datos de métricas de precipitación](#guardar-bases-de-datos-de-métricas-de-precipitación)
  - [<span class="toc-section-number">8.1</span> Estados](#estados)
  - [<span class="toc-section-number">8.2</span> Municipios](#municipios)
  - [<span class="toc-section-number">8.3</span> Precipitaciones normales](#precipitaciones-normales)

``` r
here::i_am("EarthEngine/chirps/scripts/documentacion_wide2long_chirps.R")
```

## Introducción y objetivos

La extracción de la **precipitación en milímetros (mm)** fue a través de Google Earth Engine. El periodo de extracción de los datos fue de 45 años, iniciando en 1981 hasta 2025. En total se tienen 180 archivos CSV en la carpeta **`EarthEngine/chirps/data/ee_imports`**

| **Tipo de archivo CSV** | **Número de archivos** |
|----|----|
| Precipitación anual de los estados | 1 archivo por cada año :arrow_right: 45 archivos |
| Precipitación mensual de los estados | 1 archivo por cada año :arrow_right: 45 archivos |
| Precipitación anual de los municipios | 1 archivo por cada año :arrow_right: 45 archivos |
| Precipitación mensual de los municipios | 1 archivo por cada año :arrow_right: 45 archivos |

El siguiente paso es poder unir todo en 8 archivos

- Anual:
  - Métricas de precipitación a nivel estatal en el periodo 1981 a 2025.
  - Métricas de precipitación a nivel municipal en el periodo 1981 a 2025.
  - Precipitación normal (promedio histórico) a nivel estatal.
  - Precipitación normal (promedio histórico) a nivel municipal.
- Mensual:
  - Métricas de precipitación a nivel estatal en el periodo 1981 a 2025.
  - Métricas de precipitación a nivel municipal en el periodo 1981 a 2025.
  - Precipitación normal (promedio histórico) a nivel estatal.
  - Precipitación normal (promedio histórico) a nivel municipal.

``` r
Sys.setlocale(locale = "es_ES")
library(tidyverse)

path2repo <- here::here()
path2ee <- here::here("EarthEngine")
path2chirps <- here::here("EarthEngine", "chirps")
path2chirpsdata <- here::here("EarthEngine", "chirps", "data")
```

## Los conjuntos de datos

### Ubicación de los archivos

Todos los archivos se encuentran en una misma carpeta, lo que los distingue es el nombre del archivo. El nombre tiene la estructura de `chirps_pr_mm_GEOMETRIA_PERIODO_AAAA.csv`, donde:

- `GEOMETRIA`: Indica las geometrías de la información, tales como `ent` (Estados) y `mun` (Municipios).
- `PERIODO`: Tiene los valores de los periodos de extracción, tales como `year` (anual) y `month` (mensual).
- `AAAA`: Indica el año de la información, de 1981 a 2025.

Para dividir en 8 grupos a todos los archivos, se usarán 2 partes del nombre: `_GEOMETRIA_PERIODO_`

``` r
# Obtener el nombre (path incluido) de todos los archivos que se 
# importaron de Google Earth Engine 
all_csv_chirps <- list.files(
    path = here::here(path2chirpsdata, "ee_imports"),
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
```

### Carga de los archivos

Para poder leer y unir 44 archivos en uno solo, se usa `purrr::map`. `purrr` es una librería que forma parte del `{tidyverse}`, por lo que ya se encuentra cargada en el ambiante. Con `map` se leeran los paths de los archivos de interés (dados por `idx_`).

``` r
# - - Entidades - - #
# ~ Anual ~ #
chirps_ent_year <- map(
    .x = csvs_chirps_ent_year,
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean) %>%
  mutate(mean = as.numeric(mean))

# ~ Mensual ~ #
chirps_ent_month <- map(
    .x = csvs_chirps_ent_month,
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))  %>%
  mutate(
    across(
      .cols = starts_with("x"),
      .fns = as.numeric))

# - - Municipios - - #
# ~ Anual ~ #
chirps_mun_year <- map(
    .x = csvs_chirps_mun_year,
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean) %>%
  mutate(mean = as.numeric(mean))

# ~ Mensual ~ #
chirps_mun_month <- map(
    .x = csvs_chirps_mun_month,
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x"))) %>%
  mutate(across(.cols = starts_with("x"), .fns = as.numeric))
```

Línea 4  
Seleccionar archivos CSVS

Línea 5  
Usar una función anónima para poder dar valor a más argumentos (como que todas las columnas sean leídas como *strings*) de la función `read_csv`

Línea 6  
Todos los `tibbles` se guardan en una lista, por lo que para unirlos en un solo `tibble` se concatenan por las filas

Línea 7  
Limpieza de nombres de columnas

Línea 8  
**Caso del periodo anual**: Las columnas de interés son las que tienen código de estado o municipio (`cvegeo`), el año de la información (`n_year`) y el nombre de la columna de información (`mean`)

Línea 17  
Las columnas de interés son las que tienen el código del estado o municipio (`cvegeo`), el año de la información (`n_year`) y el número de mes (después de usar `janitor::clean_names`, todas inician con `x`).

Líneas 9,18-21  
Las columnas de precipitación (`mean` y los meses) se convierten a numéricas **Muestra de datos: Precipitación en milímetros anual a nivel estatal**

| cvegeo | n_year |      mean |
|:-------|:-------|----------:|
| 25     | 2012   |  715.0738 |
| 07     | 2002   | 1890.8176 |
| 01     | 1985   |  554.5302 |
| 02     | 2010   |  161.1825 |
| 23     | 1995   | 1452.6003 |

**Muestra de datos: Precipitación en milímetros mensual a nivel estatal**

| cvegeo | n_year | x01 | x02 | x03 | x04 | x05 | x06 | x07 | x08 | x09 | x10 | x11 | x12 |
|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 25 | 2012 | 8.002082 | 9.078194 | 4.245432 | 0.8111924 | 0.4805015 | 45.8284704 | 190.168542 | 231.224290 | 130.509703 | 44.50962 | 7.114725 | 43.10105 |
| 07 | 2002 | 38.996641 | 66.951474 | 33.701111 | 25.3432067 | 118.4235838 | 322.6953956 | 238.400810 | 232.717630 | 445.561534 | 190.59085 | 123.028135 | 54.40720 |
| 01 | 1985 | 9.558769 | 3.828289 | 4.465417 | 8.7873926 | 20.1019975 | 152.7658437 | 115.626456 | 96.154847 | 58.183201 | 58.29825 | 7.853042 | 18.90671 |
| 02 | 2010 | 38.997025 | 28.909910 | 21.022839 | 12.6145800 | 0.3671345 | 0.0133551 | 2.093101 | 5.015777 | 4.319624 | 12.63896 | 6.912177 | 28.27807 |
| 23 | 1995 | 35.742716 | 18.746463 | 37.483082 | 57.2776538 | 47.0822832 | 195.7905451 | 173.862948 | 154.995527 | 286.911040 | 306.97030 | 52.001306 | 85.73642 |

### Decisiones sobre los datos

> \[!NOTE\]
>
> Como lo indican los objetivos, no solo estará la **precipitación (mm)**, también se contará con las anomalías, por lo que se tendrá que incorporar este cálculo en el flujo de trabajo.
>
> Esta es una solución temporal, en lo que se encuentra la manera **óptima** de hacer este proceso en el código de la extracción de las anomalías directamente de Google Earth Engine.

1.  Al conjunto de datos de entidades se le agregará el valor nacional
2.  Transformar el formato *wide* a *long*, para tener el número de meses como una columna. Para el caso de los datos anuales, únicamente renombrar la columna `mean` a `pr`
3.  Crear los respectivos `tibble`s de la normal de precipitación para cada uno de los archivos.
4.  Crear columnas de otras métricas de la precipitación, tales como:

- Acumulación mensual de la precipitación en milímetros (`cumsum_pr_mm`)
- Anomalía de precipitación en milímetros (`anomaly_pr_mm`)
- Anomalía de precipitación en proporción a la normal (`anomaly_pr_mm`)
- Anomalía de precipitación en milímetros (`anomaly_pr_mm`)
- Anomalía de acumulación mensual de la precipitación en milímetros (`cumulative_anomaly_pr_mm`)
- Anomalía de acumulación mensual de la precipitación en proporción a la normal (`cumulative_anomaly_pr_prop`)

## Agregar el promedio nacional a `chirps_ent_month` y `chirps_ent_year`

Se va a tratar la precipitación nacional como un estado extra

``` r
chirps_nac_month <- chirps_ent_month %>%
  group_by(n_year) %>%
  summarise(across(.cols = starts_with("x"), .fns = mean)) %>%
  ungroup() %>%
  mutate(cvegeo = "00") %>%
  relocate(cvegeo, .before = n_year)

chirps_nac_year <- chirps_ent_year %>%
  group_by(n_year) %>%
  summarise(mean = mean(mean)) %>%
  ungroup() %>%
  mutate(cvegeo = "00") %>%
  relocate(cvegeo, .before = n_year)

chirps_ent_nac_month <- bind_rows(chirps_nac_month, chirps_ent_month)
chirps_ent_nac_year <- bind_rows(chirps_nac_year, chirps_ent_year)
```

## *Wide to Long*

Para facilitar la transformación se va crear una función que haga el pivote dependiendo si los datos son mensuales o anuales.

``` r
func_wide2long <- function(df, periodo = "month") {
  if (periodo %in% c("month")) {
    df_pivoted <- df %>%
      pivot_longer(
        cols = starts_with("x"),
        names_to = "period",
        values_to = "pr_mm") %>%
      mutate(
        period = str_remove_all(
          string = period,
          pattern = "x|_precipitation"))
    
    df_transformed <- rename(.data = df_pivoted, n_month = period)

  } else {df_transformed <- rename(.data = df, pr_mm = mean)}

  return(df_transformed)}
```

Líneas 2-7  
Si el periodo es mensual se usa `pivot_longer`

Líneas 8-11  
Se eliminan las `x` + `_precipitation` del número de meses

Línea 13  
Se renombra `period` a `n_month`, para el caso de precipitación mensual

Línea 15  
Si `periodo` no es `'month'` es porque el periodo es anual y solamente se renombra la columna `mean` a `pr_mm`

Línea 17  
Se regresa el conjunto de datos con los cambios

### Sobre la precipitación acumulada a través del año en milímetros

Con el nombre corto de “Precipitación acumulada”, es la suma acumulada continua de la precipitación mensual de los meses. Por ejemplo si en el mes de Enero la precipitación es 10, en Febrero 15 y en Marzo 40, la precipitación acumulada para cada uno será:

\|Mes\|Precipitación\|Precipitación acumulada\| \|Enero\|10\|10\| \|Febrero\|15\|25\| \|Marzo\|40\|65\|

La precipitación acumulada es la suma de todos los meses hasta el mes de interés

``` r
# - - Estados - - #
chirps_ent_nac_year_long <- func_wide2long(df = chirps_ent_nac_year, periodo = "year")
chirps_ent_nac_month_long <- func_wide2long(df = chirps_ent_nac_month, periodo = "month") %>%
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
```

**Muestra de `chirps_ent_nac_month_long`**

| cvegeo | n_year | n_month |      pr_mm | cumsum_pr_mm |
|:-------|:-------|:--------|-----------:|-------------:|
| 32     | 1991   | 01      |  3.9955261 |     3.995526 |
| 08     | 2018   | 11      |  8.2679125 |   440.885548 |
| 24     | 2002   | 06      | 93.2840896 |   171.375414 |
| 19     | 2004   | 03      | 45.9968598 |    80.093369 |
| 15     | 2011   | 02      |  0.7355626 |     2.970850 |

## Precipitación normal (1981 - 2010)

En palabras sencillas y directas, **la normal** es el promedio de una variable climatológica durante un periodo largo, usualmente de 30 años.

> *También le llamo “promedio histórico”, para mayor claridad*

Para facilitar el cálculo se va crear una función para tener la normal anual o mensual.

``` r
func_normal_pr_mm <- function(df) {
  if ("n_month" %in% colnames(df)) {
    df_normal_pr_mm <- df %>%
      filter(n_year %in% 1981:2010) %>%
      group_by(cvegeo, n_month) %>%
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
      ungroup()

  } else { 
    df_normal_pr_mm <- df %>%
      filter(n_year %in% 1981:2010) %>%
      group_by(cvegeo) %>%
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
      ungroup()
  }
  
  return(df_normal_pr_mm)}
```

Líneas 2-7  
Filtro de los 30 años *base* y agrupación si `df` es de periodo mensual

Líneas 10-14  
Filtro de los 30 años *base* y agrupación si `df` es de periodo anual

Línea 17  
Se regresa el conjunto de valores normales

``` r
# - - Estados - - #
normal_pr_mm_ent_nac_year <- func_normal_pr_mm(df = chirps_ent_nac_year_long)
normal_pr_mm_ent_nac_month <- func_normal_pr_mm(df = chirps_ent_nac_month_long) %>%
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
```

**Muestra de `normal_pr_mm_mun_month`**

| cvegeo | n_month | normal_pr_mm | normal_cumsum_pr_mm |
|:-------|:--------|-------------:|--------------------:|
| 20436  | 01      |     6.998389 |            6.998389 |
| 28037  | 04      |    34.954641 |           98.654178 |
| 12022  | 11      |    16.597458 |         1255.506504 |
| 30131  | 05      |    68.533040 |          236.263532 |
| 20087  | 06      |   168.384020 |          269.401264 |

## Cálculo de métricas

### Anomalía en milimetros

Es la diferencia en milimetros, de la precipitación de un determinado mes $\left( \overline{x}_{i} \right)$ y la normal $\left( \mu_{\text{normal}} \right)$ de ese mes

$$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$

### Anomalía en proporción de la normal

Es el resultado de dividir la diferencia de la precipitación de un determinado mes $\left( \overline{x}_{i} \right)$ y la normal $\left( \mu_{\text{normal}} \right)$ entre la normal de ese mismo mes.

$$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$

### Anomalía de la precipitación acumulada en milimetros

Similar al caso de la **anomalía en milimetros**, pero la diferencia es con la precipitación acumulada normal

### Anomalía de la precipitación acumulada en proporción de la normal

Similar al caso de la **anomalía en proporción de la normal**, pero la diferencia escon la precipitación acumulada normal

### Función para cálculo de anomalías

La función tomará dos `tibble`s, el de la información de precipitación y el de la precipitación normal.

``` r
func_anomaly_pr <- function(df, df_normal) {
  if ("n_month" %in% colnames(df)) {
    df_anomaly_pr <- left_join(
        x = df,
        y = df_normal,
        by = join_by(cvegeo, n_month)) %>%
      mutate(
        anomaly_pr_mm = pr_mm - normal_pr_mm,
        anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm,
        cumulative_anomaly_pr_mm = cumsum_pr_mm - normal_cumsum_pr_mm,
        cumulative_anomaly_pr_prop = cumulative_anomaly_pr_mm / normal_cumsum_pr_mm) %>%
      select(!c(normal_pr_mm, normal_cumsum_pr_mm))

  } else {
    df_anomaly_pr <- left_join(
      x = df,
      y = df_normal,
      by = join_by(cvegeo)) %>%
    mutate(
      anomaly_pr_mm = pr_mm - normal_pr_mm,
      anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
    select(-normal_pr_mm)}
  
  return(df_anomaly_pr)}
```

Líneas 3-6  
Se usa un `lef_join` para unir los datos de precipitación con la precipitación normal. Se unen por región y mes

Líneas 7-11  
Se hace el cálculo de las anomalías

Línea 12  
Se *elimina* la columna que indica el valor de la precipitación normal

Líneas 14-22  
Proceso para periodo anual. Para este caso se une por el periodo, únicamente por la región

Línea 24  
Se regresa el conjunto de datos con las anomalías integradas

``` r
# - - Estados - - #
chirps_ent_nac_year_anomalies <- func_anomaly_pr(
    df = chirps_ent_nac_year_long,
    df_normal = normal_pr_mm_ent_nac_year)

chirps_ent_nac_month_anomalies <- func_anomaly_pr(
    df = chirps_ent_nac_month_long,
    df_normal = normal_pr_mm_ent_nac_month)

# - - Municipios - - #
chirps_mun_year_anomalies <- func_anomaly_pr(
    df = chirps_mun_year_long,
    df_normal = normal_pr_mm_mun_year)

chirps_mun_month_anomalies <- func_anomaly_pr(
    df = chirps_mun_month_long,
    df_normal = normal_pr_mm_mun_month)
```

**Muestra de `chirps_mun_month_anomalies`**

| cvegeo | n_year | n_month | pr_mm | cumsum_pr_mm | anomaly_pr_mm | anomaly_pr_prop | cumulative_anomaly_pr_mm | cumulative_anomaly_pr_prop |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|
| 16044 | 1999 | 01 | 3.483830 | 3.48383 | -10.250953 | -0.7463498 | -10.25095 | -0.7463498 |
| 08023 | 1998 | 09 | 26.246990 | 216.33189 | -21.871277 | -0.4545317 | -65.47042 | -0.2323275 |
| 21001 | 1990 | 10 | 70.853869 | 707.18026 | 9.184644 | 0.1489340 | -20.37182 | -0.0280005 |
| 05011 | 2008 | 09 | 57.531007 | 346.30815 | -1.097176 | -0.0187141 | 40.82665 | 0.1336469 |
| 20172 | 2008 | 11 | 9.211882 | 842.37945 | -4.522744 | -0.3292950 | 60.36479 | 0.0771914 |

## Detalles finales

Como últimos pasos: \* Se agregan los nombres de los estados y municipios \* Para los conjuntos de datos de periodo mensual, se crea una columna en formato de fecha. Para todos los datos, el año, meses y semana se vuelve valor numérico

### Adjuntar nombre de estados y municipios

``` r
db_cve_nom_ent_mun <- read_csv(
    file = here::here("GobiernoMexicano", "cve_nom_municipios.csv")) %>%
  bind_rows(
    tribble(
      ~cve_geo, ~nombre_estado, ~cve_ent, ~nombre_municipio, ~cve_mun,
      "00000", "Nacional", "00", "Nacional", "000"))

func_adjuntar_cve_nom_ent_mun <- function(df, region) {
  if (region == "ent") {
    df_con_nombres <- left_join(
        x = df,
        y = distinct(.data = db_cve_nom_ent_mun, cve_ent, nombre_estado),
        by = join_by(cvegeo == cve_ent)) %>%
      rename(cve_ent = cvegeo) %>%
      relocate(nombre_estado, .after = cve_ent)
  } else {
    df_con_nombres <- left_join(
        x = df,
        y = db_cve_nom_ent_mun,
        by = join_by(cvegeo == cve_geo)) %>%
      select(-cve_mun) %>%
      rename(cve_geo = cvegeo) %>%
      relocate(cve_ent, .before = cve_geo) %>%
      relocate(nombre_estado, .after = cve_ent) %>%
      relocate(nombre_municipio, .after = cve_geo)}
  
  return(df_con_nombres)}
```

Líneas 1-2  
Carga de base de datos de nombres y claves de estados y municipios

Líneas 3-6  
Agregar los codigos de “Nacional”

Líneas 9-15  
Asignación y orden de nombres para estados

Líneas 16-25  
Asignación y orden de nombres para municipios

Línea 27  
Se regresa el conjunto de datos con los nombres de las regiones

### Formato numérico y de fecha para periodos

``` r
func_string2numberdate <- function(df) {
  if ("n_month" %in% colnames(df)) {
    df_detalles_finales <- df %>%
      mutate(date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
      relocate(date_year_month, .before = n_year) %>%
      mutate(across(.cols = c(n_year, n_month), .fns = as.integer))
  } else {
    df_detalles_finales <- mutate(.data = df, n_year = as.integer(n_year))}
  
  return(df_detalles_finales)}
```

### Creación de bases de datos de métricas de precipitación

``` r
# - - Estados - - #
db_pr_ent_nac_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_nac_year_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_nac_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_nac_month_anomalies,
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
```

## Guardar bases de datos de métricas de precipitación

En la carpeta de `data` existen 3 carpetas: \* `ee_imports` \* `estados` \* `municipios` \* `normal`

La carpeta `ee_imports` son los archivos creados a partir de Google Earth Engine, y los conjuntos de datos creados por este script, se encuentran en las otras dos carpetas, `estados` y `municipios`

### Estados

**Base de datos de métricas de precipitación anual a nivel estatal**

Se guarda bajo el nombre **`db_mex_pr_ent_nac_year.csv`**

``` r
write_csv(
  x = db_pr_ent_nac_year,
  file = here::here(path2chirpsdata, "estados", "db_mex_pr_ent_nac_year.csv"),
  na = "")
```

| cve_ent | nombre_estado | n_year |     pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:--------|:--------------|-------:|----------:|--------------:|----------------:|
| 12      | Guerrero      |   2011 | 1197.3495 |    -34.028199 |      -0.0276342 |
| 26      | Sonora        |   2000 |  377.7181 |      2.225883 |       0.0059279 |
| 20      | Oaxaca        |   1983 | 1314.8241 |   -111.629814 |      -0.0782569 |
| 21      | Puebla        |   2008 | 1008.4133 |     40.582300 |       0.0419312 |
| 10      | Durango       |   1994 |  555.5389 |    -54.224882 |      -0.0889277 |

**Base de datos de métricas de precipitación mensual a nivel estatal**

Se guarda bajo el nombre **`db_mex_pr_ent_nac_month.csv`**

``` r
write_csv(
  x = db_pr_ent_nac_month,
  file = here::here(path2chirpsdata, "estados", "db_mex_pr_ent_nac_month.csv"),
  na = "")
```

| cve_ent | nombre_estado | date_year_month | n_year | n_month | pr_mm | cumsum_pr_mm | anomaly_pr_mm | anomaly_pr_prop | cumulative_anomaly_pr_mm | cumulative_anomaly_pr_prop |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| 32 | Zacatecas | 1991-01-15 | 1991 | 1 | 3.9955261 | 3.995526 | -10.666570 | -0.7274928 | -10.66657 | -0.7274928 |
| 08 | Chihuahua | 2018-11-15 | 2018 | 11 | 8.2679125 | 440.885548 | -4.424353 | -0.3485866 | 15.88713 | 0.0373816 |
| 24 | San Luis Potosí | 2002-06-15 | 2002 | 6 | 93.2840896 | 171.375414 | -1.835543 | -0.0192972 | -35.53158 | -0.1717273 |
| 19 | Nuevo León | 2004-03-15 | 2004 | 3 | 45.9968598 | 80.093369 | 30.966427 | 2.0602484 | 28.49894 | 0.5523646 |
| 15 | Estado de México | 2011-02-15 | 2011 | 2 | 0.7355626 | 2.970850 | -5.209193 | -0.8762670 | -15.68362 | -0.8407432 |

### Municipios

**Base de datos de métricas de precipitación anual a nivel municipal**

Se guarda bajo el nombre **`db_mex_pr_mun_year.csv`**

``` r
write_csv(
  x = db_pr_mun_year,
  file = here::here(path2chirpsdata, "municipios", "db_mex_pr_mun_year.csv"),
  na = "")
```

| cve_ent | nombre_estado | cve_geo | nombre_municipio | n_year | pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:---|:---|:---|:---|---:|---:|---:|---:|
| 30 | Veracruz | 30108 | Minatitlán | 1990 | 2233.4879 | -536.47491 | -0.1936759 |
| 07 | Chiapas | 07062 | Ostuacán | 2005 | 2826.5362 | -463.78120 | -0.1409533 |
| 20 | Oaxaca | 20089 | San Andrés Dinicuiti | 1998 | 627.0260 | -20.07578 | -0.0310241 |
| 09 | Ciudad de México | 09010 | Álvaro Obregón | 2009 | 962.0613 | -158.41321 | -0.1413805 |
| 21 | Puebla | 21201 | Xochiltepec | 1985 | 857.3468 | 28.84472 | 0.0348155 |

**Base de datos de métricas de precipitación mensual a nivel municipal**

Se guarda bajo el nombre **`db_mex_pr_mun_month.csv.bz2`**

``` r
write_csv(
  x = db_pr_mun_month,
  file = here::here(path2chirpsdata, "municipios", "db_mex_pr_mun_month.csv.bz2"),
  na = "")
```

### Precipitaciones normales

**Base de datos de métricas de precipitación normal anual a nivel estatal**

Se guarda bajo el nombre **`db_mex_pr_normal_ent_nac_year.csv`**

``` r
db_pr_normal_ent_nac_year <- normal_pr_mm_ent_nac_year %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

write_csv(
  x = db_pr_normal_ent_nac_year,
  file = here::here(path2chirpsdata, "normal", "db_mex_pr_normal_ent_nac_year.csv"),
  na = "")
```

| nombre_estado       | cve_ent | normal_pr_mm |
|:--------------------|:--------|-------------:|
| Baja California Sur | 03      |     150.2270 |
| Colima              | 06      |     890.7951 |
| Nacional            | 00      |     877.6157 |
| Aguascalientes      | 01      |     529.2339 |
| Tamaulipas          | 28      |     702.0985 |

**Base de datos de métricas de precipitación normal mensual a nivel estatal**

Se guarda bajo el nombre **`db_mex_pr_normal_ent_nac_month.csv`**

``` r
db_pr_normal_ent_nac_month <- normal_pr_mm_ent_nac_month %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent)

write_csv(
  x = db_pr_normal_ent_nac_month,
  file = here::here(path2chirpsdata, "normal", "db_mex_pr_normal_ent_nac_month.csv"),
  na = "")
```

| nombre_estado   | cve_ent | n_month | normal_pr_mm | normal_cumsum_pr_mm |
|:----------------|:--------|:--------|-------------:|--------------------:|
| Sonora          | 26      | 12      |     30.92021 |            375.4922 |
| Hidalgo         | 13      | 11      |     30.51419 |            803.6003 |
| Durango         | 10      | 09      |    111.96207 |            536.1041 |
| San Luis Potosí | 24      | 11      |     17.31390 |            590.1351 |
| Querétaro       | 22      | 06      |    100.20587 |            201.7392 |

**Base de datos de métricas de precipitación normal anual a nivel municipal**

Se guarda bajo el nombre **`db_mex_pr_normal_mun_year.csv`**

``` r
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
  file = here::here(path2chirpsdata, "normal", "db_mex_pr_normal_mun_year.csv"),
  na = "")
```

| nombre_estado    | cve_ent | nombre_municipio          | cve_geo | normal_pr_mm |
|:-----------------|:--------|:--------------------------|:--------|-------------:|
| Oaxaca           | 20      | Acatlán de Pérez Figueroa | 20002   |    2177.4551 |
| Estado de México | 15      | Amecameca                 | 15009   |     848.0109 |
| Veracruz         | 30      | Ixcatepec                 | 30078   |    1259.6317 |
| Morelos          | 17      | Tetela del Volcán         | 17022   |    1068.4810 |
| Oaxaca           | 20      | Santo Domingo Tlatayápam  | 20518   |     881.6413 |

**Base de datos de métricas de precipitación normal mensual a nivel municipal**

Se guarda bajo el nombre **`db_mex_pr_normal_mun_month.csv`**

``` r
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
  file = here::here(path2chirpsdata, "normal", "db_mex_pr_normal_mun_month.csv"),
  na = "")
```

| nombre_estado | cve_ent | nombre_municipio | cve_geo | n_month | normal_pr_mm | normal_cumsum_pr_mm |
|:---|:---|:---|:---|---:|---:|---:|
| Oaxaca | 20 | Santa María Texcatitlán | 20436 | 1 | 6.998389 | 6.998389 |
| Tamaulipas | 28 | Soto la Marina | 28037 | 4 | 34.954641 | 98.654178 |
| Guerrero | 12 | Coyuca de Catalán | 12022 | 11 | 16.597458 | 1255.506504 |
| Veracruz | 30 | Poza Rica de Hidalgo | 30131 | 5 | 68.533040 | 236.263532 |
| Oaxaca | 20 | San Agustín Yatareni | 20087 | 6 | 168.384020 | 269.401264 |
