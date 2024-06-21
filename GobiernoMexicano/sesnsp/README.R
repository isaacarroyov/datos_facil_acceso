#' ---
#' title: 'Procesamiento de datos: Incidencia Delictiva del Fuero Común'
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
url_victimas_delitos_ent <- "https://drive.google.com/file/d/1MeLHOZnPQ7kyxRg2JSQvnDh_2U5gjR2i/view"
id_file_victimas_delitos_ent <- str_extract(
    string = url_victimas_delitos_ent,
    pattern = "(?<=d/)(.*?)(?=/view)")

db_victimas_delitos_ent <- read_csv(
    file = paste0("https://drive.google.com/uc?export=download&id=",
                  id_file_victimas_delitos_ent),
    col_types = cols(.default = "c"),
    locale = locale(encoding = "latin1")) %>%
  janitor::clean_names()

#' **Muestra de `db_incidencia_mun`**

#| label: sample-db_incidencia_mun
#| echo: false

set.seed(11)
db_incidencia_mun %>%
  slice_sample(n = 5)

#' **Muestra de `db_victimas_delitos_ent`**

#| label: sample-db_victimas_delitos_ent
#| echo: false

set.seed(11)
db_victimas_delitos_ent %>%
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
#' ### Cambios específicos 
#' 
#' Los siguientes cambios se hacen de manera específica a cada una de las 
#' bases de datos originales.
#' 
#' **Base de datos de Incidencia Delictiva del Fuero Común anual a 
#' nivel municipal** (`db_incidencia_mun`):
#' 
#' 1. Agrupar por año, estado, municipio y (sub)tipo el número de delitos 
#' y sumar el número de delitos.
#' 2. Adjuntar el valor de la población del municipio (los que tengan dicha 
#' información) para el tasado de delitos por 100 mil habitantes.
#' 
#' **Base de datos de Incidencia Delictiva del Fuero Común anual a 
#' nivel estatal y nacional** (`db_incidencia_mun`):
#' 
#' 1. Agrupar por año, estado y (sub)tipo el número de delitos y sumar el 
#' número de delitos.
#' 2. Agrupar por año y (sub)tipo el número de delitos y sumar el 
#' número de delitos para obtener el valor Nacional.
#' 3. Adjuntar el valor de la población del estado y país para el tasado de 
#' delitos por 100 mil habitantes.
#'  
#' **Base de datos de Víctimas de Delitos del Fuero Común anual, por 
#' género a nivel estatal** (`db_victimas_delitos_ent`):
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
#' género y rango de edad a nivel estatal** (`db_victimas_delitos_ent`):
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
#' de **Otros Municipios**. Estos valores son los que tienen un 999 como 
#' últimos dígitos de `cve_municipio`. Es por eso, que para conservar la 
#' información del estado se crea la variable `cve_ent` a partir de los 
#' primeros dos dígitos de `cve_municipio` (después renombrado a `cve_geo`)

#| label: tbl-otros-municipios
#| echo: false

db_incidencia_mun %>%
  filter(str_detect(municipio, "tros")) %>%
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

#| label: join-cve_nom_ent_mun-db_victimas_delitos_ent

# - - Número de víctimas (estados) - - #
db_victimas_delitos_ent_renamed <- db_victimas_delitos_ent %>%
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

#| label: show_sample-db_victimas_delitos_ent_renamed
#| echo: false

set.seed(1)
db_victimas_delitos_ent_renamed %>%
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

#| label: wide2long-db_victimas_delitos_ent_renamed

db_victimas_delitos_ent_long <- db_victimas_delitos_ent_renamed %>%
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

#| label: show_sample-db_victimas_delitos_ent_long
#| echo: false

set.seed(1)
db_victimas_delitos_ent_long %>%
  slice_sample(n = 5)

#' ## Bases de datos con `db_incidencia_mun_long`
#' 
#' ### Número anual de delitos a nivel municipal
#' 
#' #### Agrupar por año, municipio y (sub)tipo el número de delitos
#'
#' El enfoque de los proyectos donde uso estos conjuntos de datos 
#' normalmente uso los datos de los años completos, esto no significa 
#' que no uso el dato meses por mes solo que no es tan común.

#| label: create-df_incidencia_mun_year

df_incidencia_mun_year <- db_incidencia_mun_long %>%
  # El conjunto de datos tiene muchas columnas por las cuales se 
  # hará la agrupación, por lo que es más fácil seleccionar 
  # aquellas variables que NO se usarán en la agrupación
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
  group_by(across(-c(cve_ent, nombre_estado))) %>%
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

#' ## Bases de datos con `db_victimas_delitos_ent_long`
#' 
#' <!--TODO: Empezar a partir de aqui-->
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

#| label: create-df_victimas_delitos_gender

df_victimas_delitos_gender <- bind_rows(
  # Víctimas a nivel estatal (divididas por género)
  db_victimas_delitos_ent_long %>%
    group_by(across(-c(date_year_month,
                       n_month,
                       rango_de_edad,
                       n_victimas))) %>%
    summarise(n_victimas = sum(n_victimas)) %>%
    ungroup(),
  # Víctimas a nivel nacional (divididas por género)
  db_victimas_delitos_ent_long %>%
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
    relocate(nombre_estado, .after = cve_ent)) %>%
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
# Eliminar los datos que son etiquetados con genero == "Hombre" en 
# el subtipo_de_delito == "Feminicidio"
filter(!(genero == "Hombre" & subtipo_de_delito == "Feminicidio"))

#'

#| label: show_sample-df_victimas_delitos_gender
#| echo: false

set.seed(1)
df_victimas_delitos_gender %>%
  group_by(genero) %>%
  slice_sample(n = 2)

#' #### Adjuntar el valor de la población del estado para el tasado de víctimas por 100 mil habitantes.
#' 
#' Similar al caso del los tasados de delitos a nivel municipal y estatal, 
#' se tiene que agregar información específica de la población de mujeres 
#' para el tasado del tasado del delito de Feminicidio.

#| label: create-db_victimas_delitos_ent_nac_x100khab

db_victimas_delitos_ent_nac_x100khab <- df_victimas_delitos_gender %>%
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
      condition = subtipo_de_delito == "Feminicidio",
      true = pob_mid_year_mujeres,
      false = NA_integer_)) %>%
  mutate(n_victimas_x100kmujeres = (n_victimas / pob_mid_year_mujeres) 
                                    * 100000) %>%
  select(!c(pob_mid_year, pob_mid_year_mujeres))

#'

#| label: show_sample-db_victimas_delitos_ent_nac_x100khab
#| echo: false

set.seed(1)
db_victimas_delitos_ent_nac_x100khab %>%
  slice_sample(n = 3) %>%
  bind_rows(
    db_victimas_delitos_ent_nac_x100khab %>%
      filter(subtipo_de_delito == "Feminicidio", n_victimas > 0) %>%
      slice_sample(n = 2))

#' 
#' ### Número anual de víctimas de delitos por género y rango de edad
#' 
#' #### Agrupar por año, estado, género, rango de edad y (sub)tipo el número 
#' 
#' Cras vestibulum lacinia felis et gravida. Etiam tempus lorem et dictum 
#' iaculis. Etiam dapibus magna nisl, eget eleifend quam auctor quis. 
#' Maecenas semper nunc nec nunc tempus, non egestas purus porttitor. 
#' Nullam nisi felis, suscipit vel ullamcorper vitae, lobortis euismod 
#' lacus. Aenean molestie faucibus libero at efficitur. Sed suscipit a eros 
#' at eleifend. In quis ante commodo, tempus nisl a, elementum neque. 
#' Nullam convallis fermentum tortor. Nunc scelerisque, nunc vel 
#' scelerisque tempor, metus justo dictum augue, et luctus ante sapien eu 
#' tellus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
#' Vestibulum non tristique ante. Curabitur a risus non justo varius dictum 
#' sed sit amet magna. Curabitur rhoncus, diam eget commodo finibus, metus 
#' mi feugiat tellus, eu vestibulum lacus massa quis arcu.

#| eval: false

# Crear una tercera categoría en género llamado `Todos`, este sería el 
# resultado de la suma de victimas clasificadas como Hombre, Mujer y 
# No identificado.

# Crear una tercera categoría en rango de edad llamado `Todos`, este 
# seria el resultado de la suma de victimas clasificadas como Menores de 
# edad, Adultos, No especificado y No identificado.

# Tener las nuevas categorías implica tener diversas combinaciones de 
# la información como _número de víctimas de X delito hombres menores de 
# edad_. No todas las combinaciones son relevantes, por lo que se tendrán 
# que eliminar aquellas que contengan los valores `No identificad`o o `No 
# especificado`

#' #### Adjuntar el valor de la población estatal correspondiente a la combinación de género y rango de edad para el tasado de víctimas por 100 mil habitantes.
#' 
#' Cras vestibulum lacinia felis et gravida. Etiam tempus lorem et dictum 
#' iaculis. Etiam dapibus magna nisl, eget eleifend quam auctor quis. 
#' Maecenas semper nunc nec nunc tempus, non egestas purus porttitor. 
#' Nullam nisi felis, suscipit vel ullamcorper vitae, lobortis euismod 
#' lacus. Aenean molestie faucibus libero at efficitur. Sed suscipit a eros 
#' at eleifend. In quis ante commodo, tempus nisl a, elementum neque. 
#' Nullam convallis fermentum tortor. Nunc scelerisque, nunc vel 
#' scelerisque tempor, metus justo dictum augue, et luctus ante sapien eu 
#' tellus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
#' Vestibulum non tristique ante. Curabitur a risus non justo varius dictum 
#' sed sit amet magna. Curabitur rhoncus, diam eget commodo finibus, metus 
#' mi feugiat tellus, eu vestibulum lacus massa quis arcu.
#' 
#' ## Pendiente 7
#' 
#' Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat 
#' hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus 
#' viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet 
#' tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero. 
#' Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et, 
#' aliquet facilisis mauris.
#' 
#' ## Pendiente 8
#' 
#' Duis ac ex venenatis turpis vulputate porttitor ut euismod libero. 
#' Fusce sem neque, volutpat mattis sapien id, ultrices porta elit. Sed 
#' consequat risus eu diam vehicula aliquet. Sed in mi posuere risus 
#' sollicitudin rutrum ut id odio. In hac habitasse platea dictumst. Duis 
#' tincidunt interdum pellentesque. In blandit vulputate dui, nec iaculis 
#' diam ullamcorper quis.