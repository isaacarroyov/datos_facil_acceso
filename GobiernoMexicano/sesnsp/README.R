#' ---
#' title: 'Procesamiento de datos: Incidencia Delictiva y Víctimas del Fuero Común'
#' author: Isaac Arroyo
#' date-format: long
#' date: last-modified
#' lang: es
#' format:
#'   gfm:
#'     html-math-method: katex
#'     fig-width: 5
#'     fig-asp: 0.75
#'     fig-dpi: 300
#'     code-annotations: below
#'     df-print: kable
#' execute:
#'   echo: true
#'   eval: true
#'   warning: false
#' ---
 
#| label: setwd-to-path2README_R
#| eval: false
#| echo: false

setwd("./GobiernoMexicano/sesnsp/")

#' ## Introducción y objetivos
#'
#' De acuerdo con la página del Secretariado Ejecutivo del Sistema Nacional 
#' de Seguridad Pública (SESNSP):
#' 
#' > La incidencia delictiva se refiere a la presunta ocurrencia de delitos 
#' registrados en averiguaciones previas iniciadas o carpetas de 
#' investigación, reportadas por las Procuradurías de Justicia y Fiscalías 
#' Generales de las entidades federativas 

#| label: load-libraries-paths

library(tidyverse)
library(gt)

path2main <- paste0(getwd(), "/../..")
path2gobmex <- paste0(path2main, "/GobiernoMexicano")
path2sesnsp <- paste0(path2gobmex, "/sesnsp")
path2ogdatasesnsp <- paste0(path2sesnsp,
                            "/og_incidencia_delitos_fuero_comun")

#' En este documento se usan los datos de la Incidencia Delicitiva del 
#' Fuero Común (nivel municipal), así como el número de víctimas (nivel 
#' estatal), ambos encontrados en el portal [Datos Abiertos de 
#' Incidencia Delictiva](https://www.gob.mx/sesnsp/acciones-y-programas/datos-abiertos-de-incidencia-delictiva?state=published) 
#' del SESNSP.

#| label: load-csv_incidencia-victimas_delictiva_nivel_ent-mun
#| output: false

# TODO: Encontrar la manera de hacer la descarga directa con el URL del 
#       archivo de Google Drive (INCIDENCIA EN MUNICIPIOS)

# - - Número de delitos - - #
path2dataincidenciamun <- list.files(
  path = path2ogdatasesnsp,
  pattern = ".csv",
  full.names = TRUE)

db_incidencia_mun <- read_csv(
    file = path2dataincidenciamun,
    locale = locale(encoding = "latin1"),
    col_types = cols(.default = "c")) %>%
  janitor::clean_names()

# - - Número de víctimas de delitos - - #
url_victimas_ent <- "https://drive.google.com/file/d/1B3g8u3qI7l7bw8lTDil417K9ZYYyv3KJ/view"
id_file_victimas_ent <- str_extract(
    string = url_victimas_ent,
    pattern = "(?<=d/)(.*?)(?=/view)")

db_victimas_ent <- read_csv(
    file = paste0("https://drive.google.com/uc?export=download&id=",
                  id_file_victimas_ent),
    col_types = cols(.default = "c"),
    locale = locale(encoding = "latin1")) %>%
  janitor::clean_names()

#' **Muestra de `db_incidencia_mun`**

#| label: sample-db_incidencia_mun
#| echo: false

set.seed(11)
db_incidencia_mun %>%
  slice_sample(n = 5)

#' **Muestra de `db_victimas_ent`**

#| label: sample-db_victimas_ent
#| echo: false

set.seed(11)
db_victimas_ent %>%
  slice_sample(n = 5)

#' ## Objetivos
#' 
#' El objetivo con ambos conjuntos es crear nuevos conjuntos, con 
#' información extra que es de interés general. Los 
#' conjuntos de datos contemplados son los siguientes:
#' 
#' * **Incidencia Delictiva del Fuero Común mensual a nivel municipal**:
#'   * Es la misma información que la base original pero en _long format_
#' * **Incidencia Delicitva del fuero Común mensual a nivel estatal**:
#'   * Es la misma información que la base original de municipios pero 
#' agrupada por estado y en _long format_
#' * **Incidencia Delictiva del Fuero Común anual a nivel municipal**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad y municipio)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Número de delitos
#'   * Número de delitos por cada 100 mil habitantes
#' * **Incidencia Delicitva del fuero Común anual a nivel estatal**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Número de delitos
#'   * Número de delitos por cada 100 mil habitantes
#' * **Víctimas de Delitos del Fuero Común mensual a nivel estatal (general)**:
#'   * Es la misma información que la base original pero en _long format_.
#' * **Víctimas de Delitos del Fuero Común anual, por género a nivel estatal**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Número de víctimas por género
#'   * Número de víctimas por cada 100 mil habitantes: Con respecto al 
#' total de cada género.
#' * **Víctimas de Delitos del Fuero Común anual, por género y rango de edad a nivel estatal**:
#'   * Año
#'   * Ubicación (Codigo y nombre de la entidad)
#'   * Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
#'   * Género
#'   * Rango de edad
#'   * Número de delitos
#'   * Número de delitos por cada 100 mil habitantes: Con respecto al 
#' total de la población de cada género-rango de edad
#' 
#' > [!NOTE]
#' > 
#' > Los conjuntos de datos propuestos y el procesamiento de datos están 
#' sujetos cambios dependiendo del desarrollo de los proyectos que se harán 
#' con ellos o conforme se avance en la documentación.
#' 
#' ## Lista de cambios 
#' 
#' ### Cambios generales
#' 
#' Existen tipos de cambios que se usarán en las dos bases de 
#' datos originales, estos son:
#' 
#' * Renombramiento de municipios y estados
#' * Renombrar la columna de Año (por la función `clean_names` se renombró 
#' a `ano`)
#' * Cambio de _long format_ a _wide format_: Esto para crear una variable 
#' de fecha, de esta manera la base de datos original como una serie 
#' de tiempo.
#' 
#' ## Cambios generales
#' 
#' ### Renombramiento de valores (nombre de municipios y estados) y de columnas
#' 
#' Muchas veces (si no es que en todas las ocasiones) el nombre de los 
#' estados y municipios son los que dicta el INEGI. La _desventaja_ de esto 
#' es que muchas veces los nombres son demasiado largos o no son como 
#' estan _popularmente_ conocidos. Por ejemplo, el municipio que comúnmente 
#' se le conoce como **Dolores Hidalgo**, cuenta como nombre oficial 
#' **Dolores Hidalgo, Cuna de la Independencia Nacional**, haciendo que la 
#' búsqueda y el nombre en una visualización (mapa, gráfica o tabla) sea un 
#' poco más _complicada_.
#' 
#' Afortunadamente, en el repositorio se cuenta con un conjunto de datos que 
#' facilita el renombramiento.

#| label: load-cve_nom_ent_mun

cve_nom_ent_mun <- read_csv(paste0(path2gobmex, "/cve_nom_municipios.csv"))

#'

#| label: show_sample_cve_nom_ent_mun
#| echo: false

set.seed(1)
cve_nom_ent_mun %>%
  slice_sample(n = 5)

#' Con este conjunto en el ambiente, se hace el renombramiento. Los pasos 
#' para cada conjunto de datos son similares, obviamente adaptados al las 
#' columnas disponibles en cada uno.
#' 
#' > [!WARNING]
#' > 
#' > En la base de datos de incidencia delictiva del SESNSP existe el valor 
#' de **Otros Municipios**. Estos valores son los que tienen un 999 o 998 
#' como últimos dígitos de `cve_municipio`. Es por eso, que para conservar 
#' la información del estado se crea la variable `cve_ent` a partir de los 
#' primeros dos dígitos de `cve_municipio` (después renombrado a `cve_geo`)

#| label: tbl-otros-municipios
#| echo: false

db_incidencia_mun %>%
  filter(str_ends(cve_municipio, "998|999")) %>% 
  distinct(entidad, municipio, cve_municipio)

#'

#| label: join-cve_nom_ent_mun-db_incidencia_mun

# - - Incidencia delictiva (municipios) - - #
db_incidencia_mun_renamed <- db_incidencia_mun %>%
  # Quitar las columnas de clave de entidad y nombres (entidad y municipios)
  select(!c(entidad, clave_ent, municipio))  %>%
  # Renombrar la clave del municipio a `cve_geo`
  rename(cve_geo = cve_municipio) %>%
  # Completar con el 0' al inicio de `cve_geo`
  mutate(
    cve_geo = if_else(
      condition = as.integer(cve_geo) >= 10000,
      true = cve_geo,
      false = paste0("0", cve_geo)),
    cve_ent = substr(x = cve_geo, start = 1, stop = 2)) %>%
  # Unir claves-nombres de los municipios
  left_join(
    y = select(.data = cve_nom_ent_mun, cve_geo, nombre_municipio),
    by = join_by(cve_geo)) %>%
  # Unir claves-nombres de los estados
  left_join(
    y = distinct(.data = cve_nom_ent_mun, cve_ent, nombre_estado),
    by = join_by(cve_ent)) %>%
  # Reordenar las columnas
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .before = nombre_estado) %>%
  relocate(nombre_municipio, .after = cve_geo) %>%
  # Renombrar `ano`
  rename(n_year = ano)

#'

#| label: show_sample-db_incidencia_mun_renamed
#| echo: false

set.seed(1)
db_incidencia_mun_renamed %>%
  slice_sample(n = 5)

#'

#| label: join-cve_nom_ent_mun-db_victimas_ent

# - - Número de víctimas (estados) - - #
db_victimas_ent_renamed <- db_victimas_ent %>%
  select(!c(entidad))  %>%
  rename(cve_ent = clave_ent) %>%
  mutate(
    cve_ent = if_else(
      condition = as.integer(cve_ent) >= 10,
      true = cve_ent,
      false = paste0("0", cve_ent))) %>%
  left_join(
    y = distinct(.data = cve_nom_ent_mun, cve_ent, nombre_estado),
    by = join_by(cve_ent)) %>%
  relocate(nombre_estado, .after = cve_ent) %>%
  rename(n_year = ano)

#' 

#| label: show_sample-db_victimas_ent_renamed
#| echo: false

set.seed(1)
db_victimas_ent_renamed %>%
  slice_sample(n = 5)

#' ### Transformación de _wide format_ a _long format_
#' 
#' Esta tarea se hace para que se pueda tener la base de datos como 
#' normalmente se encuentran los datos de series de tiempo.
#' 
#' Este cambio tambien implica sustituir los nombres de los meses por 
#' el número de mes para crear la columna de tiempo.

#| label: wide2long-db_incidencia_mun_renamed

db_incidencia_mun_long <- db_incidencia_mun_renamed %>%
  pivot_longer(
    cols = enero:diciembre,
    names_to = "n_month",
    values_to = "n_delitos") %>%
  mutate(
    # Cambiar a valores numéricos el número de delitos
    n_delitos = as.numeric(n_delitos),
    # Cambiar nombres a número de mes
    n_month = case_when(
      n_month == "enero" ~ "01",
      n_month == "febrero" ~ "02",
      n_month == "marzo" ~ "03",
      n_month == "abril" ~ "04",
      n_month == "mayo" ~ "05",
      n_month == "junio" ~ "06",
      n_month == "julio" ~ "07",
      n_month == "agosto" ~ "08",
      n_month == "septiembre" ~ "09",
      n_month == "octubre" ~ "10",
      n_month == "noviembre" ~ "11",
      n_month == "diciembre" ~ "12",
      .default = NA_character_),
  date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
  relocate(date_year_month, .before = n_year) %>%
  relocate(n_month, .after = n_year) %>%
  # Asegurar que solo se cuenten con los datos del último mes 
  # de actualizacion
  filter(!is.na(n_delitos))

#'

#| label: show_sample-db_incidencia_mun_long
#| echo: false

set.seed(1)
db_incidencia_mun_long %>%
  slice_sample(n = 5)

#'

#| label: wide2long-db_victimas_ent_renamed

db_victimas_ent_long <- db_victimas_ent_renamed %>%
  pivot_longer(
    cols = enero:diciembre,
    names_to = "n_month",
    values_to = "n_victimas") %>%
  mutate(
    n_victimas = as.numeric(n_victimas),
    n_month = case_when(
      n_month == "enero" ~ "01",
      n_month == "febrero" ~ "02",
      n_month == "marzo" ~ "03",
      n_month == "abril" ~ "04",
      n_month == "mayo" ~ "05",
      n_month == "junio" ~ "06",
      n_month == "julio" ~ "07",
      n_month == "agosto" ~ "08",
      n_month == "septiembre" ~ "09",
      n_month == "octubre" ~ "10",
      n_month == "noviembre" ~ "11",
      n_month == "diciembre" ~ "12",
      .default = NA_character_),
  date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
  relocate(date_year_month, .before = n_year) %>%
  relocate(n_month, .after = n_year) %>%
  rename(genero = sexo) %>%
  filter(!is.na(n_victimas))

#'

#| label: show_sample-db_victimas_ent_long
#| echo: false

set.seed(1)
db_victimas_ent_long %>%
  slice_sample(n = 5)

#' ### Cambios específicos 
#' 
#' Los siguientes cambios se hacen de manera específica a cada una de las 
#' bases de datos originales.
#' 
#' **Base de datos de Incidencia Delictiva del Fuero Común anual a 
#' nivel municipal** (Fuente: `db_incidencia_mun_long`):
#' 
#' 1. Agrupar por año, estado, municipio y (sub)tipo el número de delitos 
#' y sumar el número de delitos.
#' 2. Adjuntar el valor de la población del municipio (los que tengan dicha 
#' información) para el tasado de delitos por 100 mil habitantes.
#' 
#' **Base de datos de Incidencia Delictiva del Fuero Común anual a 
#' nivel estatal y nacional** (Fuente: `db_incidencia_mun_long`):
#' 
#' 1. Agrupar por año, estado y (sub)tipo el número de delitos y sumar el 
#' número de delitos.
#' 2. Agrupar por año y (sub)tipo el número de delitos y sumar el 
#' número de delitos para obtener el valor Nacional.
#' 3. Adjuntar el valor de la población del estado y país para el tasado de 
#' delitos por 100 mil habitantes.
#'  
#' **Base de datos de Víctimas de Delitos del Fuero Común anual, por 
#' género a nivel estatal** 
#' (Fuete: `db_victimas_ent_long`):
#' 
#' 1. Agrupar por año, estado, género y (sub)tipo el número de delitos y 
#' sumar el número de victimas.
#' 2. Crear una tercera categoría en género llamado `Todos`, este seria el 
#' resultado de la suma de victimas clasificadas como Hombre, Mujer y 
#' No identificado.
#' 3. Eliminar la categoría `No identificado`
#' 4. Adjuntar el valor de la población del estado para el tasado de 
#' víctimas por 100 mil habitantes.
#' 
#' **Base de datos de Víctimas de Delitos del Fuero Común anual, por 
#' género y rango de edad a nivel estatal** 
#' (Fuente: `db_victimas_ent_long`):
#' 
#' 1. Agrupar por año, estado, género, rango de edad y (sub)tipo el número 
#' de delitos y sumar el número de victimas.
#' 2. Crear una tercera categoría en género llamado `Todos`, este sería el 
#' resultado de la suma de victimas clasificadas como Hombre, Mujer y 
#' No identificado.
#' 3. Crear una tercera categoría en rango de edad llamado `Todos`, este 
#' seria el resultado de la suma de victimas clasificadas como Menores de 
#' edad, Adultos, No especificado y No identificado.
#' 4. Tener las nuevas categorías implica tener diversas combinaciones de 
#' la información como _número de víctimas de X delito hombres menores de 
#' edad_. No todas las combinaciones son relevantes, por lo que se tendrán 
#' que eliminar aquellas que contengan los valores `No identificad`o o `No 
#' especificado`
#' 4. Adjuntar el valor de la población estatal correspondiente a la 
#' combinación de género y rango de edad para el tasado de víctimas por 
#' 100 mil habitantes.
#' 
#' ## Bases de datos con `db_incidencia_mun_long`
#' 
#' ### Número anual de delitos a nivel municipal
#' 
#' #### Agrupar por año, municipio y (sub)tipo el número de delitos
#'
#' El enfoque de los proyectos donde uso estos conjuntos de datos 
#' normalmente uso los datos de los años completos, esto no significa 
#' que no uso el dato meses por mes solo que no es tan común.
#' 
#' > [!NOTE]
#' > 
#' > **Sobre el `group_by`**: Al contar con _muchas_ columnas, se opta 
#' por escribir las columnas **que no son parte de la agrupación** dentro 
#' de la función 
#' [`across`](https://dplyr.tidyverse.org/reference/across.html). Para 
#' indicar que no se tomarán en cuenta, las columnas que **no forman parte 
#' de la agrupación** se escriben dentro de un vector que será negado con 
#' el símbolo `-`. Esta acción se hace en gran mayoría de las agrupaciones.
#' > 
#' > Ejemplo: `df %>% group_by(across(-c(col1, col2, col3)))`, donde 
#' `col1`, `col2` y `col3` son las columnas que no se toman en cuenta 
#' para la agrupación.

#| label: create-df_incidencia_mun_year

df_incidencia_mun_year <- db_incidencia_mun_long %>%
  group_by(across(-c(date_year_month, n_month, n_delitos))) %>%
  summarise(n_delitos = sum(n_delitos, na.rm = TRUE)) %>%
  ungroup()

#'

#| label: show_sample-df_incidencia_mun_year
#| echo: false

set.seed(1)
df_incidencia_mun_year %>%
  slice_sample(n = 5)

#' #### Adjuntar el valor de la población del municipio para el tasado de delitos por 100 mil habitantes.
#' 
#' Los datos de la población serán los que publicó la CONAPO, la 
#' **Proyección de población municipal, 2015-2030**^[Para mayor información 
#' sobre conjunto de datos, visitar: [Procesamiento y transformación de 
#' datos: Proyecciones de población](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano/conapo_proyecciones)]

#| label: load-db_pob_mun_conapo

db_pob_mun_conapo <- read_csv(
    file = paste0(path2gobmex,
                  "/conapo_proyecciones",
                  "/conapo_pob_mun_gender_2015_2030.csv"),
    col_types = cols(.default = "c")) %>%
  mutate(pob_mid_year = as.numeric(pob_mid_year))

#' 

#| label: show_sample-db_pob_mun_conapo
#| echo: false

n_mun_mg_inegi <- nrow(cve_nom_ent_mun)
n_mun_sesnsp <- nrow(distinct(.data = df_incidencia_mun_year, cve_geo))
n_mun_conapo <- nrow(distinct(.data = db_pob_mun_conapo, cve_mun))

set.seed(1)
db_pob_mun_conapo %>%
  slice_sample(n = 5)

#' > [!NOTE]
#' >
#' > Al paso del tiempo se fueron integrando más municipios a México, 
#' por lo que existen los casos donde no se tienen datos de la población 
#' proyectada. Los datos de proyección de población municipal tienen 
#' `{r} format(x = n_mun_conapo, big.mark = ',')` municipios, el INEGI 
#' tiene registro de `{r} format(x = n_mun_mg_inegi, big.mark = ',')` y 
#' los datos del SESNSP cuenta con 
#' `{r} format(x = n_mun_sesnsp, big.mark = ',')` municipios (este último 
#' es porque tiene valores como **Otros municipios**)
#' 
#' El tasado para el delito de **Feminicidio** es con respecto al número 
#' de mujeres por cada 100 mil habitantes. Es por ello que se crea la 
#' columna específica. En la columna `n_delitos_100khab` se hace con respecto 
#' a la población de ambos géneros, esto para cuando se hagan agregaciones 
#' por modalidad (por ejemplo: agrupar por delitos hechos con arma de fuego) 
#' se haga la sumatoria y todo quede con respecto a la población del 
#' municipio o estado. Sin embargo, para el estudio específico del delito 
#' de **Feminicidio**, se usa la información de la columna 
#' `n_delitos_100kmujeres`

#| label: create-db_incidencia_mun_year_x100khab

db_incidencia_mun_year_x100khab <- df_incidencia_mun_year %>%
  left_join(
    y = db_pob_mun_conapo %>% 
          filter(genero == "Total") %>%
          select(n_year, cve_mun, pob_mid_year),
    by = join_by(n_year, cve_geo == cve_mun)) %>%
  mutate(n_delitos_x100khab = (n_delitos / pob_mid_year) * 100000) %>%
  # Adjuntar población femenina
  left_join(
    y = db_pob_mun_conapo %>%
          filter(genero == "Mujeres") %>%
          rename(pob_mid_year_mujeres = pob_mid_year) %>%
          select(n_year, cve_mun, pob_mid_year_mujeres),
    by = join_by(n_year, cve_geo == cve_mun)) %>%
  # Eliminar el valor de celdas que NO sean Feminicidio
  mutate(
    pob_mid_year_mujeres = if_else(
      condition = subtipo_de_delito == "Feminicidio",
      true = pob_mid_year_mujeres,
      false = NA_integer_)) %>%
  # Cálculo de delitos de feminicidio por cada 100 mil mujeres
  mutate(
    n_delitos_x100kmujeres = (n_delitos / pob_mid_year_mujeres) * 100000) %>%
  select(!c(pob_mid_year, pob_mid_year_mujeres))

#'   

#| label: show_sample-db_incidencia_mun_year_x100khab
#| echo: false

set.seed(1)
db_incidencia_mun_year_x100khab %>%
  slice_sample(n = 3) %>%
  bind_rows(
    db_incidencia_mun_year_x100khab %>%
      filter(subtipo_de_delito == "Feminicidio", n_delitos > 0) %>%
      slice_sample(n = 2))

#' ### Número anual de delitos a nivel estatal
#' 
#' #### Agrupar por año, estado y (sub)tipo el número de delitos.
#' 
#' El enfoque de los proyectos donde uso estos conjuntos de datos 
#' normalmente uso los datos de los años completos, esto no significa 
#' que no uso el dato meses por mes solo que no es tan común.

#| label: create-df_incidencia_ent_year

df_incidencia_ent_year <- db_incidencia_mun_long %>%
  group_by(across(-c(date_year_month, n_month, n_delitos,
                     nombre_municipio, cve_geo))) %>%
  summarise(n_delitos = sum(n_delitos, na.rm = TRUE)) %>%
  ungroup()

#'

#| label: show_sample-df_incidencia_ent_year
#| echo: false

set.seed(1)
df_incidencia_ent_year %>%
  slice_sample(n = 5)

#' #### Adjuntar el valor de la población del estado para el tasado de delitos por 100 mil habitantes.
#' 
#' Los datos de la población serán los que publicó la CONAPO, la **Población 
#' a mitad e inicio de año de los estados de México (1950-2070)**^[Para 
#' mayor información sobre conjunto de datos, visitar: [Procesamiento y 
#' transformación de datos: Proyecciones de población](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano/conapo_proyecciones)]

#| label: load-db_pob_ent_conapo

db_pob_ent_conapo <- read_csv(
    file = paste0(path2gobmex,
                  "/conapo_proyecciones",
                  "/conapo_pob_ent_gender_1950_2070.csv"),
    col_types = cols(.default = "c")) %>%
  select(-pob_start_year) %>%
  mutate(pob_mid_year = as.numeric(pob_mid_year))

#' 

#| label: show_sample-db_pob_ent_conapo
#| echo: false

set.seed(1)
db_pob_ent_conapo %>%
  slice_sample(n = 5)
 
#' Un agregado extra es también el número de delitos y tasado a nivel 
#' nacional

#| label: create-df_incidencia_nac_year

df_incidencia_nac_year <- df_incidencia_ent_year %>%
  group_by(across(-c(cve_ent, nombre_estado, n_delitos))) %>%
  summarise(n_delitos = sum(n_delitos, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(
    cve_ent = "00",
    nombre_estado = "Nacional") %>%
  relocate(cve_ent, .after = n_year) %>%
  relocate(nombre_estado, .after = cve_ent)

#'

#| label: show_sample-df_incidencia_nac_year
#| echo: false

set.seed(3)
df_incidencia_nac_year %>%
  slice_sample(n = 5)

#' Similar al caso del tasado de delitos a nivel municipal, se tiene que 
#' agregar información específica de la población de mujeres para el 
#' tasado del tasado del delito de Feminicidio.

#| label: create-db_incidencia_ent_nac_year_x100khab

db_incidencia_ent_nac_year_x100khab <- bind_rows(
    df_incidencia_ent_year,
    df_incidencia_nac_year) %>%
  left_join(
    y = db_pob_ent_conapo %>%
          filter(genero == "Total") %>%
          select(n_year, cve_ent, pob_mid_year),
    by = join_by(n_year, cve_ent)) %>%
  mutate(n_delitos_x100khab = (n_delitos / pob_mid_year) * 100000) %>%
  left_join(
    y = db_pob_ent_conapo %>%
          filter(genero == "Mujeres") %>%
          rename(pob_mid_year_mujeres = pob_mid_year) %>%
          select(n_year, cve_ent, pob_mid_year_mujeres),
    by = join_by(n_year, cve_ent)) %>%
  mutate(
    pob_mid_year_mujeres = if_else(
      condition = subtipo_de_delito == "Feminicidio",
      true = pob_mid_year_mujeres,
      false = NA_integer_)) %>%
  mutate(
    n_delitos_x100kmujeres = (n_delitos / pob_mid_year_mujeres) * 100000) %>%
  select(!c(pob_mid_year, pob_mid_year_mujeres))

#'

#| label: show_sample-db_incidencia_ent_nac_year_x100khab
#| echo: false

set.seed(2)
db_incidencia_ent_nac_year_x100khab %>%
  slice_sample(n = 3) %>%
  bind_rows(
    db_incidencia_ent_nac_year_x100khab %>%
      filter(subtipo_de_delito == "Feminicidio", n_delitos > 0) %>%
      slice_sample(n = 2))

#' ## Bases de datos con `db_victimas_ent_long`
#' 
#' ### Número anual de víctimas de delitos por género
#' 
#' #### Agrupación por año, estado, género y (sub)tipo el número de delitos
#' 
#' El enfoque de los proyectos donde uso estos conjuntos de datos 
#' normalmente uso los datos de los años completos, esto no significa que 
#' no uso el dato meses por mes solo que no es tan común.
#' 
#' También es importante agregar el valor nacional para comparaciones.

#| label: create-df_victimas_ent_nac_gender_year

# Víctimas a nivel estatal (divididas por género)
df_victimas_ent_gender_year <- db_victimas_ent_long %>%
    group_by(across(-c(date_year_month,
                       n_month,
                       rango_de_edad,
                       n_victimas))) %>%
    summarise(n_victimas = sum(n_victimas)) %>%
    ungroup()

# Víctimas a nivel nacional (divididas por género)
df_victimas_nac_gender_year <- db_victimas_ent_long %>%
    group_by(across(-c(date_year_month,
                       cve_ent,
                       nombre_estado,
                       n_month,
                       rango_de_edad,
                       n_victimas))) %>%
    summarise(n_victimas = sum(n_victimas)) %>%
    ungroup() %>%
    mutate(cve_ent = "00", nombre_estado = "Nacional") %>%
    relocate(cve_ent, .after = n_year) %>%
    relocate(nombre_estado, .after = cve_ent)

df_victimas_ent_nac_gender_year <- bind_rows(
  df_victimas_ent_gender_year,
  df_victimas_nac_gender_year) %>%
  group_by(across(-c(genero, n_victimas))) %>%
  mutate(`Total` = sum(n_victimas)) %>%
  ungroup() %>%
  pivot_wider(
    names_from = genero,
    values_from = n_victimas) %>%
  # Eliminar la categoría `No identificado`
  select(-`No identificado`) %>%
  pivot_longer(
    cols = c(`Total`, `Hombre`, `Mujer`),
    names_to = "genero",
    values_to = "n_victimas") %>%
# Eliminar los datos que son etiquetados con genero "Hombre" o "Total" en 
# el subtipo_de_delito == "Feminicidio"
  filter(!(genero %in% c("Total", "Hombre") &
           subtipo_de_delito == "Feminicidio")) %>%
# Eliminar los datos que son etiquetados con genero "Hombre" o "Mujer" en 
# el subtipo_de_delito == "Aborto"
  filter(!(genero %in% c("Hombre", "Mujer") & 
           modalidad == "Aborto"))

#'

#| label: show_sample-df_victimas_ent_nac_gender_year
#| echo: false

set.seed(1)
df_victimas_ent_nac_gender_year %>%
  group_by(genero) %>%
  slice_sample(n = 2)

#' #### Adjuntar el valor de la población del estado para el tasado de víctimas por 100 mil habitantes.
#' 
#' Similar al caso del los tasados de delitos a nivel municipal y estatal, 
#' se tiene que agregar información específica de la población de mujeres 
#' para el tasado del delito de Feminicidio.

#| label: create-db_victimas_ent_nac_x100khab

db_victimas_ent_nac_x100khab <- df_victimas_ent_nac_gender_year %>%
  left_join(
    y = db_pob_ent_conapo %>%
          filter(genero == "Total") %>%
          select(!c(nombre_estado, genero)),
    by = join_by(n_year, cve_ent)) %>%
  mutate(n_victimas_x100khab = (n_victimas / pob_mid_year) * 100000) %>%
  # Agregar población de mujeres
  left_join(
    y = db_pob_ent_conapo %>%
          filter(genero == "Mujeres") %>%
          rename(pob_mid_year_mujeres = pob_mid_year) %>%
          select(!c(nombre_estado, genero)),
    by = join_by(n_year, cve_ent)) %>%
  mutate(
    pob_mid_year_mujeres = if_else(
      condition = genero == "Mujer",
      true = pob_mid_year_mujeres,
      false = NA_integer_)) %>%
  mutate(n_victimas_x100kmujeres = (n_victimas / pob_mid_year_mujeres) 
                                    * 100000) %>%
  select(!c(pob_mid_year, pob_mid_year_mujeres))

#'

#| label: show_sample-db_victimas_ent_nac_x100khab
#| echo: false

set.seed(1)
db_victimas_ent_nac_x100khab %>%
  slice_sample(n = 3) %>%
  bind_rows(
    db_victimas_ent_nac_x100khab %>%
      filter(subtipo_de_delito == "Feminicidio", n_victimas > 0) %>%
      slice_sample(n = 2))

#' ### Número anual de víctimas de delitos por género y rango de edad
#' 
#' #### Agrupar por año, estado, género, rango de edad y (sub)tipo el número 
#' 
#' El objetivo de la agrupación de las diferentes categorías de género y 
#' rango de edad es para poder desagregar la información de acuerdo a 
#' diferentes necesidades del proyecto.
#' 
#' Primero se agrupan los datos a nivel estatal, después nacional y 
#' finalmente se unen en un solo `DataFrame`

#| label: create-df_victimas_ent_nac_gender_age_year

# - - Conteo de víctimas a nivel estatal - - #
df_victimas_ent_gender_age <- db_victimas_ent_long %>%
  group_by(across(-c(date_year_month, n_month, n_victimas))) %>%
  summarise(n_victimas = sum(n_victimas, na.rm = TRUE)) %>%
  ungroup() %>%
  # Crear una tercera categoría en género llamado `Todos`, este sería el 
  # resultado de la suma de victimas clasificadas como Hombre, Mujer y 
  # No identificado.
  group_by(across(-c(n_victimas, genero))) %>%
  mutate(total_genero = sum(n_victimas, na.rm = TRUE)) %>%
  ungroup() %>%
  pivot_wider(
    names_from = genero,
    values_from = n_victimas,
    values_fill = 0) %>%
  janitor::clean_names() %>%
  pivot_longer(
    cols = total_genero:no_identificado,
    names_to = "genero",
    values_to = "n_victimas") %>%
  # Crear una tercera categoría en rango de edad llamado `Todos`, este 
  # seria el resultado de la suma de victimas clasificadas como Menores de 
  # edad, Adultos, No especificado y No identificado.
  group_by(across(-c(n_victimas, rango_de_edad))) %>%
  mutate(total_edad = sum(n_victimas, na.rm = TRUE)) %>%
  ungroup() %>% 
  pivot_wider(
    names_from = rango_de_edad,
    values_from = n_victimas,
    values_fill = 0) %>%
  janitor::clean_names() %>% 
  # Renombrar rangos de edad
  rename(
    adultos = adultos_18_y_mas,
    # NNA = Niñas, niños y adolescentes
    nna = menores_de_edad_0_17) %>%
  # Tener las nuevas categorías implica tener diversas combinaciones de 
  # la información como _número de víctimas de X delito hombres menores de 
  # edad_. No todas las combinaciones son relevantes, por lo que se tendrán 
  # que eliminar aquellas que contengan los valores `No identificado` o `No 
  # especificado`
  filter(genero != "no_identificado") %>%
  select(!starts_with("no_")) %>%
  pivot_longer(
    cols = total_edad:nna,
    names_to = "rango_de_edad",
    values_to = "n_victimas") %>%
  # Eliminar registros de hombre y total_genero 
  # en el subtipo_de_delito "Feminicidio"
  filter(
    !(genero %in% c("hombre", "total_genero") &
      subtipo_de_delito == "Feminicidio")) %>%
  # Eliminar registros de genero `hombre` y `mujer` & 
  # rango_de_edad `adultos` y `nna` en el subtipo_de_delito == Aborto 
  # ya que originalmente todas las victimas son 
  # etiquetadas con categorias No identificado, por lo que solo 
  # se tiene la info en las categorias `total_genero` y `total_edad`
  filter(
    !(modalidad == "Aborto" & 
      (genero %in% c("hombre", "mujer") |
       rango_de_edad %in% c("adultos", "nna"))))


# - - Conteo de víctimas a nivel nacional - - #
df_victimas_nac_gender_age <- df_victimas_ent_gender_age %>%
  group_by(across(-c(cve_ent, nombre_estado, n_victimas))) %>%
  summarise(n_victimas = sum(n_victimas, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(cve_ent = "00", nombre_estado = "Nacional") %>%
  relocate(cve_ent, .after = n_year) %>%
  relocate(nombre_estado, .after = cve_ent)

# - - Unión del conteo de víctimas a nivel estatal + nacional - - #
df_victimas_ent_nac_gender_age_year <- bind_rows(
  df_victimas_ent_gender_age,
  df_victimas_nac_gender_age)

#'

#| label: show_sample-df_victimas_ent_nac_gender_age_year
#| echo: false

set.seed(2)
df_victimas_ent_nac_gender_age_year %>%
  slice_sample(n = 5)

#' Como resultado se tienen 9 diferentes combinaciones de 
#' `genero`-`rango_de_edad`
#' 
#' > **NNA** = **N**iñas, **N**iños y **A**dolescentes

#| label: show-combinations_genero_edad
#| echo: false

df_victimas_ent_nac_gender_age_year %>%
  distinct(genero, rango_de_edad) %>%
  bind_cols(
    tibble(
      descripcion = c("Total de víctimas de todos los géneros y todas las edades",
                      "Total de víctimas de todos los géneros, adultas",
                      "Total de víctimas de todos los géneros, NNA",
                      "Total de víctimas hombres de todas las edades",
                      "Total de víctimas hombres adultos",
                      "Total de víctimas hombres NNA",
                      "Total de víctimas mujeres de todas las edades",
                      "Total de víctimas mujeres adultas",
                      "Total de víctimas mujeres NNA")))

#' #### Adjuntar el valor de la población estatal correspondiente a la combinación de género y rango de edad para el tasado de víctimas por 100 mil habitantes.
#' 
#' El conjunto de datos `df_victimas_ent_nac_gender_age_year` tiene 
#' `{r} ncol(df_victimas_ent_nac_gender_age_year)` columnas, a lo que se 
#' agregarán 3 columnas extra:
#' 
#' * Tasado con respecto a la población total (ambos genero y todas 
#' las edades): Para todas las observaciones
#' * Tasado con respecto a la población total de mujeres (todas las 
#' edades): Únicamente para el género `mujer`
#' * Tasado con respecto a su combinación de `genero`-`rango_de_edad`: Para 
#' realizar este tipo de tasado, se modifica la forma del conjunto de datos 
#' de la proyección de problación, de tal manera en que se tenga la 
#' información de las dos columnas que tiene 
#' `df_victimas_ent_nac_gender_age_year`

#| label: create-db_pob_ent_conapo_gender_age

db_pob_ent_conapo_gender_age <- read_csv(
    file = paste0(path2gobmex,
                  "/conapo_proyecciones",
                  "/conapo_pob_ent_gender_age_1950_2070.csv.bz2"),
    col_types = cols(.default = "c")) %>%
  select(-pob_start_year) %>%
  mutate(
    pob_mid_year = as.numeric(pob_mid_year),
    edad = as.numeric(edad),
    rango_de_edad = if_else(
      condition = edad < 18,
      true = "nna",
      false = "adultos")) %>%
  group_by(across(-c(pob_mid_year, edad))) %>%
  summarise(pob_mid_year = sum(pob_mid_year)) %>%
  ungroup() %>%
  pivot_wider(
    names_from = rango_de_edad,
    values_from = pob_mid_year) %>%
  mutate(total_edad = adultos + nna) %>%
  pivot_longer(
    cols = c(adultos, nna, total_edad),
    names_to = "rango_de_edad",
    values_to = "pob_mid_year") %>%
  pivot_wider(
    names_from = genero,
    values_from = pob_mid_year) %>%
  janitor::clean_names() %>%
  mutate(total_genero = hombres + mujeres) %>%
  rename(hombre = hombres, mujer = mujeres) %>%
  pivot_longer(
    cols = c(hombre, mujer, total_genero),
    names_to = "genero",
    values_to = "pob_mid_year")

#' La creación de las primeras dos columnas resulta similar a como se ha 
#' estado haciendo previamente. La tercera columna tomará en cuenta como 
#' llaves (para la unión) la categoría de rango de edad y genero

#| label: create-db_victimas_ent_nac_gender_age_100khab

db_victimas_ent_nac_gender_age_100khab <- df_victimas_ent_nac_gender_age_year %>%
  # ~ Creación 1a columna: Tasado con respecto a la pob total ~ #
  # Unión de información de población total
  left_join(
    y = db_pob_ent_conapo_gender_age %>% 
          filter(
            genero == "total_genero",
            rango_de_edad == "total_edad") %>%
        select(n_year, cve_ent, pob_mid_year),
    by = join_by(n_year, cve_ent)) %>%
  # [1] Cálculo de victimas por 100 mil hab (total_genero-total_edad)
  mutate(n_victimas_x100khab = (n_victimas / pob_mid_year) * 100000) %>%
  # ~ Creación 2a columna: Tasado con respecto a la pob total de mujeres ~ #
  # Unión de información de población total de mujeres
  left_join(
    y = db_pob_ent_conapo_gender_age %>% 
          filter(
            genero == "mujer",
            rango_de_edad == "total_edad") %>%
        rename(pob_mid_year_mujeres = pob_mid_year) %>%
        select(n_year, cve_ent, pob_mid_year_mujeres),
    by = join_by(n_year, cve_ent)) %>%
  # [2] Cálculo de victimas por 100 mil mujeres (total_edad)
  mutate(n_victimas_x100kmujeres = (n_victimas / pob_mid_year_mujeres) 
                                    * 100000) %>%
  # ~ Creación 3a columna: Tasado con respecto a la pob 
  #   de cada par genero-rango_de_edad ~ #
  # Unión de información de población de cada par genero-rango_de_edad
  left_join(
    y = db_pob_ent_conapo_gender_age %>% 
        rename(pob_mid_year_par = pob_mid_year) %>%
        select(!c(nombre_estado)),
    by = join_by(n_year, cve_ent, rango_de_edad, genero)) %>%
  # [3] Cálculo de victimas por 100 mil mujeres (total_edad)
  mutate(n_victimas_x100kpar = (n_victimas / pob_mid_year_par) * 100000) %>%
  # Eliminar las columnas de población
  select(!starts_with("pob_mid")) %>%
  # Eliminar datos de las celdas de la columna n_victimas_x100kmujeres
  # en aquellas observaciones que NO sean mujer
  mutate(
    n_victimas_x100kmujeres = if_else(
      condition = genero == "mujer",
      true = n_victimas_x100kmujeres,
      false = NA_real_))

#' 

#| label: fact-check_db_victimas_ent_nac_gender_age_100khab-vs-db_victimas_ent_nac_x100khab
#| echo: false
#| eval: false

db_victimas_ent_nac_gender_age_100khab %>%
  filter(
    genero == "total_genero",
    rango_de_edad == "total_edad",
    cve_ent == "00") %>% 
  select(!c(n_victimas_x100khab,
            genero, rango_de_edad)) %>%
  rename(
    n_victimas_x100kmujeres_par = n_victimas_x100kmujeres,
    n_victimas_par = n_victimas) %>%
  left_join(
    y = db_victimas_ent_nac_x100khab %>% 
        filter(
          cve_ent == "00",
          genero == "Total") %>%
        select(-genero),
    by = join_by(n_year,
                 cve_ent,
                 nombre_estado,
                 bien_juridico_afectado,
                 tipo_de_delito,
                 subtipo_de_delito,
                 modalidad))

#' 

#| label: show_sample-db_victimas_ent_nac_gender_age_100khab
#| echo: false

set.seed(3)
db_victimas_ent_nac_gender_age_100khab %>%
  slice_sample(n = 3) %>%
  bind_rows(
    db_victimas_ent_nac_gender_age_100khab %>%
      filter(subtipo_de_delito == "Feminicidio") %>%
      slice_sample(n = 2))

#' <!--TODO: Terminar de escribir las descripciones de delitos del fuero comun en los diccionarios -->
#' ## Guardar bases de datos
#' 
#' Se cuenta con un total de 7 bases de datos, de las cuales 3 son 
#' únicamente las versiones oficiales en _long format_. El resto de las 
#' bases de datos son agrupaciones anuales por genéro o rango de edad, 
#' además estas cuentan con los valores escalados a la proporción de 
#' 100 mil habitantes.
#' 
#' ### Bases de datos _long format_
#' 
#' #### Incidencia Delictiva del Fuero Común mensual a nivel municipal
#' 
#' Se guarda bajo el nombre de **`db_incidencia_mun_long.csv.bz2`**

#| label: save-db_incidencia_mun_long

db_incidencia_mun_long %>%
  write_csv(file = paste0(path2sesnsp, "/db_incidencia_mun_long.csv.bz2"))

#' |**Variable**|**Tipo de dato**|**Descripción**|
#' |---|---|---|
#' |`date_year_month`|Fecha|Mes del año escrito en formato "YYYY-MM-DD". En todos los casos el día siempre es 15|
#' |`n_year`|Número entero o categeórico|Número del año, puede ser tratado tanto como número entero o como categoria, depende del objetivo del proyecto|
#' |`n_month`|Número entero o (de preferencia) categórico|Número del mes (1-12), sin embargo también puede ser tratato como categoría. En la base de datos se le da preferencia al segunto tipo de dato|
#' |`cve_ent`|Categórico|Clave INEGI del estado|
#' |`nombre_estado`|Categórico|Nombre del estado|
#' |`cve_geo`|Categórico|Clave INEGI del municipio (resultado de la concatenación del código del estado y del municipio en el estado)|
#' |`nombre_municipio`|Categórico|Nombre del municipio|
#' |`bien_juridico_afectado`|Categórico|...|
#' |`tipo_de_delito`|Categórico|...|
#' |`subtipo_de_delito`|Categórico|...|
#' |`modalidad`|Categórico|...|
#' |`n_delitos`|Número entero|Número de delitos|

#| label: tabla_final-db_incidencia_mun_long
#| echo: false

set.seed(123)
db_incidencia_mun_long %>%
  slice_sample(n = 5)

#' #### Incidencia Delictiva del Fuero Común mensual a nivel estatal
#' 
#' Se guarda bajo el nombre de **`db_incidencia_ent_long.csv`**

#| label: save-db_incidencia_ent_long

db_incidencia_ent_long <- db_incidencia_mun_long %>%
  group_by(across(-c(date_year_month,
                     n_delitos,
                     cve_geo,
                     nombre_municipio))) %>%
  summarise(n_delitos = sum(n_delitos, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
  relocate(date_year_month, .before = n_year)

db_incidencia_ent_long %>%
  write_csv(file = paste0(path2sesnsp, "/db_incidencia_ent_long.csv"))

#' |**Variable**|**Tipo de dato**|**Descripción**|
#' |---|---|---|
#' |`date_year_month`|Fecha|Mes del año escrito en formato "YYYY-MM-DD". En todos los casos el día siempre es 15|
#' |`n_year`|Número entero o categeórico|Número del año, puede ser tratado tanto como número entero o como categoria, depende del objetivo del proyecto|
#' |`n_month`|Número entero o (de preferencia) categórico|Número del mes (1-12), sin embargo también puede ser tratato como categoría. En la base de datos se le da preferencia al segunto tipo de dato|
#' |`cve_ent`|Categórico|Clave INEGI del estado|
#' |`nombre_estado`|Categórico|Nombre del estado|
#' |`bien_juridico_afectado`|Categórico|...|
#' |`tipo_de_delito`|Categórico|...|
#' |`subtipo_de_delito`|Categórico|...|
#' |`modalidad`|Categórico|...|
#' |`n_delitos`|Número entero|Número de delitos|

#| label: tabla_final-db_incidencia_ent_long
#| echo: false

set.seed(123)
db_incidencia_ent_long %>%
  slice_sample(n = 5)

#' #### Víctimas de Delitos del Fuero Común mensual a nivel estatal
#' 
#' Se guarda bajo el nombre de **`db_victimas_delitos_ent_long.csv.bz2`**

#| label: save-db_victimas_ent_long

db_victimas_ent_long %>%
  write_csv(file = paste0(path2sesnsp,
                          "/db_victimas_delitos_ent_long.csv.bz2"))

#' |**Variable**|**Tipo de dato**|**Descripción**|
#' |---|---|---|
#' |`date_year_month`|Fecha|Mes del año escrito en formato "YYYY-MM-DD". En todos los casos el día siempre es 15|
#' |`n_year`|Número entero o categeórico|Número del año, puede ser tratado tanto como número entero o como categoria, depende del objetivo del proyecto|
#' |`n_month`|Número entero o (de preferencia) categórico|Número del mes (1-12), sin embargo también puede ser tratato como categoría. En la base de datos se le da preferencia al segunto tipo de dato|
#' |`cve_ent`|Categórico|Clave INEGI del estado|
#' |`nombre_estado`|Categórico|Nombre del estado|
#' |`bien_juridico_afectado`|Categórico|...|
#' |`tipo_de_delito`|Categórico|...|
#' |`subtipo_de_delito`|Categórico|...|
#' |`modalidad`|Categórico|...|
#' |`genero`|Categórico|Género asignado a la víctima. Se encuentran 3: `Mujer`, `Hombre` o `No identificado`|
#' |`rango_de_edad`|Categórico|Rango de edad asignado a la víctima, se encuentran 4: `Menores de edad (0-17)`, `Adultos (18 y más)`, `No especificado` y `No identificado`|
#' |`n_victimas`|Número entero|Número de víctimas|

#| label: tabla_final-db_victimas_ent_long
#| echo: false

set.seed(123)
db_victimas_ent_long %>%
  slice_sample(n = 5)

#' ### Bases de datos con información extra y desagregaciones
#' 
#' > [!NOTE]
#' > 
#' > En las bases de datos que tengan la columna de `genero` y 
#' `rango_de_edad`, los valores `Total`, `total_genero` (para el caso de 
#' la columna `genero`) o `total_edad`, se incluyen en la suma de las 
#' categorías `No especificado` y `No identificado`
#' 
#' #### Incidencia Delictiva del Fuero Común anual a nivel municipal
#' 
#' Se guarda bajo el nombre de **`db_incidencia_mun_year_x100khab_mujeres.csv.bz2`**

#| label: save-db_incidencia_mun_year_x100khab

db_incidencia_mun_year_x100khab %>%
  write_csv(file = paste0(
    path2sesnsp, "/db_incidencia_mun_year_x100khab_mujeres.csv.bz2"))

#' |**Variable**|**Tipo de dato**|**Descripción**|
#' |---|---|---|
#' |`n_year`|Número entero o categeórico|Número del año, puede ser tratado tanto como número entero o como categoria, depende del objetivo del proyecto|
#' |`cve_ent`|Categórico|Clave INEGI del estado|
#' |`nombre_estado`|Categórico|Nombre del estado|
#' |`cve_geo`|Categórico|Clave INEGI del municipio (resultado de la concatenación del código del estado y del municipio en el estado)|
#' |`nombre_municipio`|Categórico|Nombre del municipio|
#' |`bien_juridico_afectado`|Categórico|...|
#' |`tipo_de_delito`|Categórico|...|
#' |`subtipo_de_delito`|Categórico|...|
#' |`modalidad`|Categórico|...|
#' |`n_delitos`|Número entero|Número de delitos|
#' |`n_delitos_x100khab`|Número decimal|Número de delitos por cada 100 mil habitantes. El número de habitantes es con respecto a toda la población del municipio de todas las edades y géneros|
#' |`n_delitos_x100kmujeres`|Número decimal|Número de delitos por cada 100 mil mujeres. El número de habitantes es con respecto a toda la población de mujeres en el municipio de todas las edades|

#| label: tabla_final-db_incidencia_mun_year_x100khab
#| echo: false

set.seed(123)
db_incidencia_mun_year_x100khab %>%
  slice_sample(n = 5)

#' #### Incidencia Delictiva del Fuero Común anual a nivel estatal
#' 
#' Se guarda bajo el nombre de **`db_incidencia_ent_nac_year_x100khab_mujeres.csv.bz2`**

#| label: save-db_incidencia_ent_nac_year_x100khab

db_incidencia_ent_nac_year_x100khab %>%
  write_csv(
    file = paste0(path2sesnsp,
                  "/db_incidencia_ent_nac_year_x100khab_mujeres.csv.bz2"))

#' |**Variable**|**Tipo de dato**|**Descripción**|
#' |---|---|---|
#' |`n_year`|Número entero o categeórico|Número del año, puede ser tratado tanto como número entero o como categoria, depende del objetivo del proyecto|
#' |`cve_ent`|Categórico|Clave INEGI del estado|
#' |`nombre_estado`|Categórico|Nombre del estado|
#' |`bien_juridico_afectado`|Categórico|...|
#' |`tipo_de_delito`|Categórico|...|
#' |`subtipo_de_delito`|Categórico|...|
#' |`modalidad`|Categórico|...|
#' |`n_delitos`|Número entero|Número de delitos|
#' |`n_delitos_x100khab`|Número decimal|Número de delitos por cada 100 mil habitantes. El número de habitantes es con respecto a toda la población de la entidad de todas las edades y géneros|
#' |`n_delitos_x100kmujeres`|Número decimal|Número de delitos por cada 100 mil mujeres. El número de habitantes es con respecto a toda la población de mujeres en la entidad de todas las edades|

#| label: tabla_final-db_incidencia_ent_nac_year_x100khab
#| echo: false

set.seed(123)
db_incidencia_ent_nac_year_x100khab %>%
  slice_sample(n = 5)

#' #### Víctimas de Delitos del Fuero Común anual a nivel estatal: Desagregado por genero
#' 
#' Se guarda bajo el nombre de **`db_victimas_delitos_ent_nac_x100khab_genero.csv.bz2`**

#| label: save-db_victimas_ent_nac_x100khab

db_victimas_ent_nac_x100khab %>%
  write_csv(
    file = paste0(path2sesnsp,
                  "/db_victimas_delitos_ent_nac_x100khab_genero.csv.bz2"))

#' |**Variable**|**Tipo de dato**|**Descripción**|
#' |---|---|---|
#' |`n_year`|Número entero o categeórico|Número del año, puede ser tratado tanto como número entero o como categoria, depende del objetivo del proyecto|
#' |`cve_ent`|Categórico|Clave INEGI del estado|
#' |`nombre_estado`|Categórico|Nombre del estado|
#' |`bien_juridico_afectado`|Categórico|...|
#' |`tipo_de_delito`|Categórico|...|
#' |`subtipo_de_delito`|Categórico|...|
#' |`modalidad`|Categórico|...|
#' |`genero`|Categórico|Género asignado a la víctima. Se encuentran 3: `Mujer`, `Hombre` o `Total`|
#' |`n_victimas`|Número entero|Número de víctimas|
#' |`n_victimas_x100khab`|Número decimal|Número de víctimas por cada 100 mil habitantes. El número de habitantes es con respecto a toda la población de la entidad de todas las edades y géneros|
#' |`n_victimas_x100kmujeres`|Número decimal|Número de víctimas por cada 100 mil mujeres. El número de habitantes es con respecto a toda la población de mujeres en la entidad de todas las edades|

#| label: tabla_final-db_victimas_ent_nac_x100khab
#| echo: false

set.seed(123)
db_victimas_ent_nac_x100khab %>%
  slice_sample(n = 5)

#' #### Víctimas de Delitos del Fuero Común anual a nivel estatal: Desagregado por genero y rango de edad
#' 
#' Se guarda bajo el nombre de **`db_victimas_delitos_ent_nac_100khab_genero_rango_de_edad.csv.bz2`**

#| label: save-db_victimas_ent_nac_gender_age_100khab

db_victimas_ent_nac_gender_age_100khab %>%
  write_csv(
    file = paste0(
      path2sesnsp,
      "/db_victimas_delitos_ent_nac_100khab_genero_rango_de_edad.csv.bz2"))

#' |**Variable**|**Tipo de dato**|**Descripción**|
#' |---|---|---|
#' |`n_year`|Número entero o categeórico|Número del año, puede ser tratado tanto como número entero o como categoria, depende del objetivo del proyecto|
#' |`cve_ent`|Categórico|Clave INEGI del estado|
#' |`nombre_estado`|Categórico|Nombre del estado|
#' |`bien_juridico_afectado`|Categórico|...|
#' |`tipo_de_delito`|Categórico|...|
#' |`subtipo_de_delito`|Categórico|...|
#' |`modalidad`|Categórico|...|
#' |`genero`|Categórico|Género asignado a las víctimas. Se encuentran 3: `mujer`, `hombre` o `total_genero`|
#' |`rango_de_edad`|Categórico|Rango de edad asignado a la víctima, se encuentran 3: `nna` (Niñas, Niños y Adolescentes), `adultos` y `total_edad`|
#' |`n_victimas`|Número entero|Número de víctimas|
#' |`n_victimas_x100khab`|Número decimal|Número de víctimas por cada 100 mil habitantes. El número de habitantes es con respecto a toda la población de la entidad de todas las edades y géneros|
#' |`n_victimas_x100kmujeres`|Número decimal|Número de víctimas por cada 100 mil mujeres. El número de habitantes es con respecto a toda la población de mujeres en la entidad de todas las edades. Este dato únicamente existe en las celdas cuyo género sea `mujer`|
#' |`n_victimas_x100kpar`|Número decimal|Número de víctimas por cada 100 mil habitantes. El número de habitantes es con respecto al par de categorias `genero`-`rango_de_edad` y la entidad. Por ejemplo, si la celda tiene valores `nna` y `total_genero`, significa que es el número de víctimas por cada 100 mil habitantes que sean Niñas, Niños y Adolescentes de todos los géneros|

#| label: tabla_final-db_victimas_ent_nac_gender_age_100khab
#| echo: false

set.seed(123)
db_victimas_ent_nac_gender_age_100khab %>%
  slice_sample(n = 5)