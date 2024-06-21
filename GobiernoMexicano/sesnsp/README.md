# Procesamiento de datos: Incidencia Delictiva del Fuero Común
Isaac Arroyo
21 de junio de 2024

## Introducción y objetivos

De acuerdo con la página del Secretariado Ejecutivo del Sistema Nacional
de Seguridad Pública (SESNSP):

> La incidencia delictiva se refiere a la presunta ocurrencia de delitos
> registrados en averiguaciones previas iniciadas o carpetas de
> investigación, reportadas por las Procuradurías de Justicia y
> Fiscalías Generales de las entidades federativas

``` r
library(tidyverse)
library(gt)

path2main <- paste0(getwd(), "/../..")
path2gobmex <- paste0(path2main, "/GobiernoMexicano")
path2sesnsp <- paste0(path2gobmex, "/sesnsp")
path2ogdatasesnsp <- paste0(path2sesnsp,
                            "/og_incidencia_delitos_fuero_comun")
```

En este documento se usan los datos de la Incidencia Delicitiva del
Fuero Común (nivel municipal), así como el número de víctimas (nivel
estatal), ambos encontrados en el portal [Datos Abiertos de Incidencia
Delictiva](https://www.gob.mx/sesnsp/acciones-y-programas/datos-abiertos-de-incidencia-delictiva?state=published)
del SESNSP.

``` r
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
```

**Muestra de `db_incidencia_mun`**

| ano  | clave_ent | entidad         | cve_municipio | municipio                | bien_juridico_afectado | tipo_de_delito     | subtipo_de_delito                               | modalidad                         | enero | febrero | marzo | abril | mayo | junio | julio | agosto | septiembre | octubre | noviembre | diciembre |
|:-----|:----------|:----------------|:--------------|:-------------------------|:-----------------------|:-------------------|:------------------------------------------------|:----------------------------------|:------|:--------|:------|:------|:-----|:------|:------|:-------|:-----------|:--------|:----------|:----------|
| 2019 | 24        | San Luis Potosí | 24048         | Villa de la Paz          | El patrimonio          | Robo               | Robo a transeúnte en espacio abierto al público | Sin violencia                     | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2020 | 31        | Yucatán         | 31093         | Tixkokob                 | El patrimonio          | Robo               | Robo de vehículo automotor                      | Robo de motocicleta Con violencia | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2020 | 31        | Yucatán         | 31019         | Chemax                   | El patrimonio          | Abuso de confianza | Abuso de confianza                              | Abuso de confianza                | 0     | 0       | 1     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2023 | 11        | Guanajuato      | 11017         | Irapuato                 | El patrimonio          | Robo               | Robo a negocio                                  | Sin violencia                     | 19    | 4       | 8     | 12    | 12   | 15    | 21    | 13     | 25         | 23      | 9         | 20        |
| 2024 | 20        | Oaxaca          | 20105         | San Antonino Monte Verde | El patrimonio          | Robo               | Robo a transeúnte en vía pública                | Sin violencia                     | 0     | 0       | 0     | 0     | 0    | NA    | NA    | NA     | NA         | NA      | NA        | NA        |

**Muestra de `db_victimas_delitos_ent`**

| ano  | clave_ent | entidad                         | bien_juridico_afectado           | tipo_de_delito                   | subtipo_de_delito                | modalidad                        | sexo            | rango_de_edad          | enero | febrero | marzo | abril | mayo | junio | julio | agosto | septiembre | octubre | noviembre | diciembre |
|:-----|:----------|:--------------------------------|:---------------------------------|:---------------------------------|:---------------------------------|:---------------------------------|:----------------|:-----------------------|:------|:--------|:------|:------|:-----|:------|:------|:-------|:-----------|:--------|:----------|:----------|
| 2023 | 30        | Veracruz de Ignacio de la Llave | La vida y la Integridad corporal | Feminicidio                      | Feminicidio                      | Con arma blanca                  | Mujer           | Menores de edad (0-17) | 0     | 0       | 0     | 1     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2024 | 1         | Aguascalientes                  | La vida y la Integridad corporal | Aborto                           | Aborto                           | Aborto                           | No identificado | No identificado        | 0     | 1       | 1     | 0     | 0    | NA    | NA    | NA     | NA         | NA      | NA        | NA        |
| 2017 | 19        | Nuevo León                      | La vida y la Integridad corporal | Homicidio                        | Homicidio culposo                | Con otro elemento                | Hombre          | Adultos (18 y más)     | 6     | 2       | 4     | 0     | 2    | 4     | 3     | 3      | 0          | 5       | 0         | 1         |
| 2018 | 30        | Veracruz de Ignacio de la Llave | La sociedad                      | Otros delitos contra la sociedad | Otros delitos contra la sociedad | Otros delitos contra la sociedad | Hombre          | Menores de edad (0-17) | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2020 | 4         | Campeche                        | La vida y la Integridad corporal | Homicidio                        | Homicidio doloso                 | Con otro elemento                | Hombre          | Menores de edad (0-17) | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |

## Objetivos

El objetivo con ambos conjuntos es crear nuevos conjuntos, con
información extra que es de interés general. Los conjuntos de datos
contemplados son los siguientes:

- **Incidencia Delictiva del Fuero Común mensual a nivel municipal**:
  - Es la misma información que la base original pero en *long format*
- **Incidencia Delicitva del fuero Común mensual a nivel estatal**:
  - Es la misma información que la base original de municipios pero
    agrupada por estado y en *long format*
- **Incidencia Delictiva del Fuero Común anual a nivel municipal**:
  - Año
  - Ubicación (Codigo y nombre de la entidad y municipio)
  - Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
  - Número de delitos
  - Número de delitos por cada 100 mil habitantes
- **Incidencia Delicitva del fuero Común anual a nivel estatal**:
  - Año
  - Ubicación (Codigo y nombre de la entidad)
  - Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
  - Número de delitos
  - Número de delitos por cada 100 mil habitantes
- **Víctimas de Delitos del Fuero Común mensual a nivel estatal
  (general)**:
  - Es la misma información que la base original pero en *long format*.
- **Víctimas de Delitos del Fuero Común anual, por género a nivel
  estatal**:
  - Año
  - Ubicación (Codigo y nombre de la entidad)
  - Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
  - Número de víctimas por género
  - Número de víctimas por cada 100 mil habitantes: Con respecto al
    total de cada género.
- **Víctimas de Delitos del Fuero Común anual, por género y rango de
  edad a nivel estatal**:
  - Año
  - Ubicación (Codigo y nombre de la entidad)
  - Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
  - Género
  - Rango de edad
  - Número de delitos
  - Número de delitos por cada 100 mil habitantes: Con respecto al total
    de la población de cada género-rango de edad

> \[!NOTE\]
>
> Los conjuntos de datos propuestos y el procesamiento de datos están
> sujetos cambios dependiendo del desarrollo de los proyectos que se
> harán con ellos o conforme se avance en la documentación.

## Lista de cambios

### Cambios generales

Existen tipos de cambios que se usarán en las dos bases de datos
originales, estos son:

- Renombramiento de municipios y estados
- Renombrar la columna de Año (por la función `clean_names` se renombró
  a `ano`)
- Cambio de *long format* a *wide format*: Esto para crear una variable
  de fecha, de esta manera la base de datos original como una serie de
  tiempo.

### Cambios específicos

Los siguientes cambios se hacen de manera específica a cada una de las
bases de datos originales.

**Base de datos de Incidencia Delictiva del Fuero Común anual a nivel
municipal** (`db_incidencia_mun`):

1.  Agrupar por año, estado, municipio y (sub)tipo el número de delitos
    y sumar el número de delitos.
2.  Adjuntar el valor de la población del municipio (los que tengan
    dicha información) para el tasado de delitos por 100 mil habitantes.

**Base de datos de Incidencia Delictiva del Fuero Común anual a nivel
estatal y nacional** (`db_incidencia_mun`):

1.  Agrupar por año, estado y (sub)tipo el número de delitos y sumar el
    número de delitos.
2.  Agrupar por año y (sub)tipo el número de delitos y sumar el número
    de delitos para obtener el valor Nacional.
3.  Adjuntar el valor de la población del estado y país para el tasado
    de delitos por 100 mil habitantes.

**Base de datos de Víctimas de Delitos del Fuero Común anual, por género
a nivel estatal** (`db_victimas_delitos_ent`):

1.  Agrupar por año, estado, género y (sub)tipo el número de delitos y
    sumar el número de victimas.
2.  Crear una tercera categoría en género llamado `Todos`, este seria el
    resultado de la suma de victimas clasificadas como Hombre, Mujer y
    No identificado.
3.  Eliminar la categoría `No identificado`
4.  Adjuntar el valor de la población del estado para el tasado de
    víctimas por 100 mil habitantes.

**Base de datos de Víctimas de Delitos del Fuero Común anual, por género
y rango de edad a nivel estatal** (`db_victimas_delitos_ent`):

1.  Agrupar por año, estado, género, rango de edad y (sub)tipo el número
    de delitos y sumar el número de victimas.
2.  Crear una tercera categoría en género llamado `Todos`, este sería el
    resultado de la suma de victimas clasificadas como Hombre, Mujer y
    No identificado.
3.  Crear una tercera categoría en rango de edad llamado `Todos`, este
    seria el resultado de la suma de victimas clasificadas como Menores
    de edad, Adultos, No especificado y No identificado.
4.  Tener las nuevas categorías implica tener diversas combinaciones de
    la información como *número de víctimas de X delito hombres menores
    de edad*. No todas las combinaciones son relevantes, por lo que se
    tendrán que eliminar aquellas que contengan los valores
    `No identificad`o o `No  especificado`
5.  Adjuntar el valor de la población estatal correspondiente a la
    combinación de género y rango de edad para el tasado de víctimas por
    100 mil habitantes.

## Cambios generales

### Renombramiento de valores (nombre de municipios y estados) y de columnas

Muchas veces (si no es que en todas las ocasiones) el nombre de los
estados y municipios son los que dicta el INEGI. La *desventaja* de esto
es que muchas veces los nombres son demasiado largos o no son como estan
*popularmente* conocidos. Por ejemplo, el municipio que comúnmente se le
conoce como **Dolores Hidalgo**, cuenta como nombre oficial **Dolores
Hidalgo, Cuna de la Independencia Nacional**, haciendo que la búsqueda y
el nombre en una visualización (mapa, gráfica o tabla) sea un poco más
*complicada*.

Afortunadamente, en el repositorio se cuenta con un conjunto de datos
que facilita el renombramiento.

``` r
cve_nom_ent_mun <- read_csv(paste0(path2gobmex, "/cve_nom_municipios.csv"))
```

| cve_geo | nombre_estado    | cve_ent | nombre_municipio        | cve_mun |
|:--------|:-----------------|:--------|:------------------------|:--------|
| 20481   | Oaxaca           | 20      | Santiago Nuyoó          | 481     |
| 15015   | Estado de México | 15      | Atlautla                | 015     |
| 30211   | Veracruz         | 30      | San Rafael              | 211     |
| 17024   | Morelos          | 17      | Tlaltizapán de Zapata   | 024     |
| 20436   | Oaxaca           | 20      | Santa María Texcatitlán | 436     |

Con este conjunto en el ambiente, se hace el renombramiento. Los pasos
para cada conjunto de datos son similares, obviamente adaptados al las
columnas disponibles en cada uno.

> \[!WARNING\]
>
> En la base de datos de incidencia delictiva del SESNSP existe el valor
> de **Otros Municipios**. Estos valores son los que tienen un 999 como
> últimos dígitos de `cve_municipio`. Es por eso, que para conservar la
> información del estado se crea la variable `cve_ent` a partir de los
> primeros dos dígitos de `cve_municipio` (después renombrado a
> `cve_geo`)

| entidad                         | municipio        | cve_municipio |
|:--------------------------------|:-----------------|:--------------|
| Oaxaca                          | Otros Municipios | 20999         |
| Sonora                          | Otros Municipios | 26999         |
| Veracruz de Ignacio de la Llave | Otros Municipios | 30999         |

``` r
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
```

| n_year | cve_ent | nombre_estado | cve_geo | nombre_municipio    | bien_juridico_afectado            | tipo_de_delito        | subtipo_de_delito                | modalidad                | enero | febrero | marzo | abril | mayo | junio | julio | agosto | septiembre | octubre | noviembre | diciembre |
|:-------|:--------|:--------------|:--------|:--------------------|:----------------------------------|:----------------------|:---------------------------------|:-------------------------|:------|:--------|:------|:------|:-----|:------|:------|:-------|:-----------|:--------|:----------|:----------|
| 2024   | 20      | Oaxaca        | 20472   | Santiago Laollaga   | La vida y la Integridad corporal  | Homicidio             | Homicidio doloso                 | Con otro elemento        | 0     | 0       | 0     | 0     | 0    | NA    | NA    | NA     | NA         | NA      | NA        | NA        |
| 2021   | 20      | Oaxaca        | 20402   | Santa María Cortijo | La vida y la Integridad corporal  | Homicidio             | Homicidio culposo                | En accidente de tránsito | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2018   | 31      | Yucatán       | 31100   | Ucú                 | La sociedad                       | Corrupción de menores | Corrupción de menores            | Corrupción de menores    | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2024   | 13      | Hidalgo       | 13014   | Calnali             | La libertad y la seguridad sexual | Violación equiparada  | Violación equiparada             | Violación equiparada     | 0     | 0       | 0     | 0     | 0    | NA    | NA    | NA     | NA         | NA      | NA        | NA        |
| 2020   | 32      | Zacatecas     | 32025   | Luis Moya           | El patrimonio                     | Robo                  | Robo a transeúnte en vía pública | Con violencia            | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |

``` r
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
```

| n_year | cve_ent | nombre_estado       | bien_juridico_afectado           | tipo_de_delito | subtipo_de_delito | modalidad                      | sexo   | rango_de_edad          | enero | febrero | marzo | abril | mayo | junio | julio | agosto | septiembre | octubre | noviembre | diciembre |
|:-------|:--------|:--------------------|:---------------------------------|:---------------|:------------------|:-------------------------------|:-------|:-----------------------|:------|:--------|:------|:------|:-----|:------|:------|:-------|:-----------|:--------|:----------|:----------|
| 2018   | 11      | Guanajuato          | La vida y la Integridad corporal | Homicidio      | Homicidio culposo | Con otro elemento              | Mujer  | Menores de edad (0-17) | 8     | 7       | 7     | 6     | 8    | 2     | 6     | 3      | 2          | 3       | 0         | 4         |
| 2023   | 03      | Baja California Sur | La vida y la Integridad corporal | Lesiones       | Lesiones culposas | Con arma de fuego              | Hombre | No especificado        | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2020   | 29      | Tlaxcala            | El patrimonio                    | Extorsión      | Extorsión         | Extorsión                      | Mujer  | Adultos (18 y más)     | 0     | 0       | 0     | 0     | 0    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |
| 2024   | 15      | Estado de México    | Libertad personal                | Secuestro      | Secuestro         | Secuestro con calidad de rehén | Hombre | Menores de edad (0-17) | 0     | 0       | 0     | 0     | 0    | NA    | NA    | NA     | NA         | NA      | NA        | NA        |
| 2016   | 19      | Nuevo León          | La vida y la Integridad corporal | Homicidio      | Homicidio doloso  | Con arma de fuego              | Mujer  | No especificado        | 1     | 1       | 0     | 0     | 1    | 0     | 0     | 0      | 0          | 0       | 0         | 0         |

### Transformación de *wide format* a *long format*

Esta tarea se hace para que se pueda tener la base de datos como
normalmente se encuentran los datos de series de tiempo.

Este cambio tambien implica sustituir los nombres de los meses por el
número de mes para crear la columna de tiempo.

``` r
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
```

| date_year_month | n_year | n_month | cve_ent | nombre_estado | cve_geo | nombre_municipio    | bien_juridico_afectado           | tipo_de_delito      | subtipo_de_delito           | modalidad                         | n_delitos |
|:----------------|:-------|:--------|:--------|:--------------|:--------|:--------------------|:---------------------------------|:--------------------|:----------------------------|:----------------------------------|----------:|
| 2019-05-15      | 2019   | 05      | 13      | Hidalgo       | 13050   | Progreso de Obregón | El patrimonio                    | Robo                | Robo de vehículo automotor  | Robo de motocicleta Con violencia |         0 |
| 2021-02-15      | 2021   | 02      | 20      | Oaxaca        | 20242   | San Martín Peras    | Libertad personal                | Secuestro           | Secuestro                   | Secuestro extorsivo               |         0 |
| 2019-03-15      | 2019   | 03      | 21      | Puebla        | 21001   | Acajete             | La vida y la Integridad corporal | Aborto              | Aborto                      | Aborto                            |         0 |
| 2021-02-15      | 2021   | 02      | 21      | Puebla        | 21085   | Izúcar de Matamoros | El patrimonio                    | Robo                | Robo a institución bancaria | Sin violencia                     |         0 |
| 2022-07-15      | 2022   | 07      | 30      | Veracruz      | 30058   | Chicontepec         | El patrimonio                    | Daño a la propiedad | Daño a la propiedad         | Daño a la propiedad               |         2 |

``` r
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
```

| date_year_month | n_year | n_month | cve_ent | nombre_estado | bien_juridico_afectado           | tipo_de_delito | subtipo_de_delito | modalidad                | genero | rango_de_edad          | n_victimas |
|:----------------|:-------|:--------|:--------|:--------------|:---------------------------------|:---------------|:------------------|:-------------------------|:-------|:-----------------------|-----------:|
| 2021-12-15      | 2021   | 12      | 07      | Chiapas       | La vida y la Integridad corporal | Lesiones       | Lesiones culposas | En accidente de tránsito | Hombre | No especificado        |          0 |
| 2020-01-15      | 2020   | 01      | 05      | Coahuila      | La vida y la Integridad corporal | Homicidio      | Homicidio culposo | No especificado          | Mujer  | Menores de edad (0-17) |          0 |
| 2016-09-15      | 2016   | 09      | 14      | Jalisco       | La vida y la Integridad corporal | Lesiones       | Lesiones culposas | No especificado          | Mujer  | Menores de edad (0-17) |          1 |
| 2019-11-15      | 2019   | 11      | 31      | Yucatán       | La vida y la Integridad corporal | Homicidio      | Homicidio doloso  | Con arma blanca          | Mujer  | Adultos (18 y más)     |          0 |
| 2022-07-15      | 2022   | 07      | 18      | Nayarit       | La vida y la Integridad corporal | Lesiones       | Lesiones dolosas  | Con otro elemento        | Hombre | Adultos (18 y más)     |          4 |

## Bases de datos con `db_incidencia_mun_long`

### Número anual de delitos a nivel municipal

#### Agrupar por año, municipio y (sub)tipo el número de delitos

El enfoque de los proyectos donde uso estos conjuntos de datos
normalmente uso los datos de los años completos, esto no significa que
no uso el dato meses por mes solo que no es tan común.

> \[!NOTE\]
>
> **Sobre el `group_by`**: Al contar con *muchas* columnas, se opta por
> escribir las columnas **que no son parte de la agrupación** dentro de
> la función
> [`across`](https://dplyr.tidyverse.org/reference/across.html). Para
> indicar que no se tomarán en cuenta, las columnas que **no forman
> parte de la agrupación** se escriben dentro de un vector que será
> negado con el símbolo `-`. Esta acción se hace en gran mayoría de las
> agrupaciones.
>
> Ejemplo: `df %>% group_by(across(-c(col1, col2, col3)))`, donde
> `col1`, `col2` y `col3` son las columnas que no se toman en cuenta
> para la agrupación.

``` r
df_incidencia_mun_year <- db_incidencia_mun_long %>%
  group_by(across(-c(date_year_month, n_month, n_delitos))) %>%
  summarise(n_delitos = sum(n_delitos, na.rm = TRUE)) %>%
  ungroup()
```

| n_year | cve_ent | nombre_estado | cve_geo | nombre_municipio    | bien_juridico_afectado            | tipo_de_delito       | subtipo_de_delito             | modalidad            | n_delitos |
|:-------|:--------|:--------------|:--------|:--------------------|:----------------------------------|:---------------------|:------------------------------|:---------------------|----------:|
| 2024   | 20      | Oaxaca        | 20472   | Santiago Laollaga   | El patrimonio                     | Despojo              | Despojo                       | Despojo              |         0 |
| 2021   | 20      | Oaxaca        | 20402   | Santa María Cortijo | El patrimonio                     | Robo                 | Otros robos                   | Con violencia        |         0 |
| 2018   | 31      | Yucatán       | 31100   | Ucú                 | Libertad personal                 | Secuestro            | Secuestro                     | Secuestro extorsivo  |         0 |
| 2024   | 13      | Hidalgo       | 13014   | Calnali             | El patrimonio                     | Robo                 | Robo en transporte individual | Con violencia        |         0 |
| 2020   | 32      | Zacatecas     | 32025   | Luis Moya           | La libertad y la seguridad sexual | Violación equiparada | Violación equiparada          | Violación equiparada |         0 |

#### Adjuntar el valor de la población del municipio para el tasado de delitos por 100 mil habitantes.

Los datos de la población serán los que publicó la CONAPO, la
**Proyección de población municipal, 2015-2030**[^1]

``` r
db_pob_mun_conapo <- read_csv(
    file = paste0(path2gobmex,
                  "/conapo_proyecciones",
                  "/conapo_pob_mun_gender_2015_2030.csv"),
    col_types = cols(.default = "c")) %>%
  mutate(pob_mid_year = as.numeric(pob_mid_year))
```

| n_year | nombre_estado | cve_ent | nombre_municipio     | cve_mun | genero  | pob_mid_year |
|:-------|:--------------|:--------|:---------------------|:--------|:--------|-------------:|
| 2024   | Veracruz      | 30      | Tuxpan               | 30189   | Hombres |        85011 |
| 2023   | Guerrero      | 12      | Taxco de Alarcón     | 12055   | Mujeres |        59219 |
| 2016   | Oaxaca        | 20      | Tataltepec de Valdés | 20543   | Mujeres |         3014 |
| 2027   | Michoacán     | 16      | Arteaga              | 16010   | Mujeres |        11922 |
| 2019   | Puebla        | 21      | Tianguismanalco      | 21175   | Hombres |         6339 |

> \[!NOTE\]
>
> Al paso del tiempo se fueron integrando más municipios a México, por
> lo que existen los casos donde no se tienen datos de la población
> proyectada. Los datos de proyección de población municipal tienen
> 2,457 municipios, el INEGI tiene registro de 2,475 y los datos del
> SESNSP cuenta con 2,483 municipios (este último es porque tiene
> valores como **Otros municipios**)

El tasado para el delito de **Feminicidio** es con respecto al número de
mujeres por cada 100 mil habitantes. Es por ello que se crea la columna
específica. En la columna `n_delitos_100khab` se hace con respecto a la
población de ambos géneros, esto para cuando se hagan agregaciones por
modalidad (por ejemplo: agrupar por delitos hechos con arma de fuego) se
haga la sumatoria y todo quede con respecto a la población del municipio
o estado. Sin embargo, para el estudio específico del delito de
**Feminicidio**, se usa la información de la columna
`n_delitos_100kmujeres`

``` r
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
```

| n_year | cve_ent | nombre_estado | cve_geo | nombre_municipio    | bien_juridico_afectado           | tipo_de_delito | subtipo_de_delito | modalidad           | n_delitos | n_delitos_x100khab | n_delitos_x100kmujeres |
|:-------|:--------|:--------------|:--------|:--------------------|:---------------------------------|:---------------|:------------------|:--------------------|----------:|-------------------:|-----------------------:|
| 2024   | 20      | Oaxaca        | 20472   | Santiago Laollaga   | El patrimonio                    | Despojo        | Despojo           | Despojo             |         0 |          0.0000000 |                     NA |
| 2021   | 20      | Oaxaca        | 20402   | Santa María Cortijo | El patrimonio                    | Robo           | Otros robos       | Con violencia       |         0 |          0.0000000 |                     NA |
| 2018   | 31      | Yucatán       | 31100   | Ucú                 | Libertad personal                | Secuestro      | Secuestro         | Secuestro extorsivo |         0 |          0.0000000 |                     NA |
| 2021   | 27      | Tabasco       | 27017   | Tenosique           | La vida y la Integridad corporal | Feminicidio    | Feminicidio       | Con arma de fuego   |         1 |          1.5550165 |              3.0270925 |
| 2022   | 32      | Zacatecas     | 32017   | Guadalupe           | La vida y la Integridad corporal | Feminicidio    | Feminicidio       | Con arma blanca     |         1 |          0.4899895 |              0.9580288 |

### Número anual de delitos a nivel estatal

#### Agrupar por año, estado y (sub)tipo el número de delitos.

El enfoque de los proyectos donde uso estos conjuntos de datos
normalmente uso los datos de los años completos, esto no significa que
no uso el dato meses por mes solo que no es tan común.

``` r
df_incidencia_ent_year <- db_incidencia_mun_long %>%
  group_by(across(-c(date_year_month, n_month, n_delitos,
                     nombre_municipio, cve_geo))) %>%
  summarise(n_delitos = sum(n_delitos, na.rm = TRUE)) %>%
  ungroup()
```

| n_year | cve_ent | nombre_estado | bien_juridico_afectado                             | tipo_de_delito                   | subtipo_de_delito                | modalidad                        | n_delitos |
|:-------|:--------|:--------------|:---------------------------------------------------|:---------------------------------|:---------------------------------|:---------------------------------|----------:|
| 2020   | 18      | Nayarit       | La sociedad                                        | Otros delitos contra la sociedad | Otros delitos contra la sociedad | Otros delitos contra la sociedad |         5 |
| 2022   | 25      | Sinaloa       | Libertad personal                                  | Secuestro                        | Secuestro                        | Secuestro con calidad de rehén   |         0 |
| 2016   | 17      | Morelos       | La vida y la Integridad corporal                   | Lesiones                         | Lesiones culposas                | Con arma blanca                  |         0 |
| 2023   | 17      | Morelos       | Otros bienes jurídicos afectados (del fuero común) | Narcomenudeo                     | Narcomenudeo                     | Narcomenudeo                     |       531 |
| 2019   | 07      | Chiapas       | Libertad personal                                  | Secuestro                        | Secuestro                        | Secuestro extorsivo              |        16 |

#### Adjuntar el valor de la población del estado para el tasado de delitos por 100 mil habitantes.

Los datos de la población serán los que publicó la CONAPO, la
**Población a mitad e inicio de año de los estados de México
(1950-2070)**[^2]

``` r
db_pob_ent_conapo <- read_csv(
    file = paste0(path2gobmex,
                  "/conapo_proyecciones",
                  "/conapo_pob_ent_gender_1950_2070.csv"),
    col_types = cols(.default = "c")) %>%
  select(-pob_start_year) %>%
  mutate(pob_mid_year = as.numeric(pob_mid_year))
```

| n_year | nombre_estado | cve_ent | genero  | pob_mid_year |
|:-------|:--------------|:--------|:--------|-------------:|
| 1979   | Puebla        | 21      | Total   |      3376487 |
| 2050   | Coahuila      | 05      | Total   |      4090838 |
| 2017   | Oaxaca        | 20      | Mujeres |      2143863 |
| 2067   | Oaxaca        | 20      | Mujeres |      2489994 |
| 2054   | Tamaulipas    | 28      | Mujeres |      2032292 |

Un agregado extra es también el número de delitos y tasado a nivel
nacional

``` r
df_incidencia_nac_year <- df_incidencia_ent_year %>%
  group_by(across(-c(cve_ent, nombre_estado))) %>%
  summarise(n_delitos = sum(n_delitos, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(
    cve_ent = "00",
    nombre_estado = "Nacional") %>%
  relocate(cve_ent, .after = n_year) %>%
  relocate(nombre_estado, .after = cve_ent)
```

| n_year | cve_ent | nombre_estado | bien_juridico_afectado                             | tipo_de_delito | subtipo_de_delito          | modalidad                               | n_delitos |
|:-------|:--------|:--------------|:---------------------------------------------------|:---------------|:---------------------------|:----------------------------------------|----------:|
| 2020   | 00      | Nacional      | El patrimonio                                      | Robo           | Robo de autopartes         | Sin violencia                           |       133 |
| 2024   | 00      | Nacional      | La vida y la Integridad corporal                   | Homicidio      | Homicidio culposo          | En accidente de tránsito                |       128 |
| 2018   | 00      | Nacional      | El patrimonio                                      | Robo           | Robo de autopartes         | Sin violencia                           |        25 |
| 2018   | 00      | Nacional      | El patrimonio                                      | Robo           | Robo de vehículo automotor | Robo de coche de 4 ruedas Con violencia |      2021 |
| 2018   | 00      | Nacional      | Otros bienes jurídicos afectados (del fuero común) | Falsedad       | Falsedad                   | Falsedad                                |        99 |

Similar al caso del tasado de delitos a nivel municipal, se tiene que
agregar información específica de la población de mujeres para el tasado
del tasado del delito de Feminicidio.

``` r
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
```

| n_year | cve_ent | nombre_estado | bien_juridico_afectado                             | tipo_de_delito                | subtipo_de_delito             | modalidad                                                                           | n_delitos | n_delitos_x100khab | n_delitos_x100kmujeres |
|:-------|:--------|:--------------|:---------------------------------------------------|:------------------------------|:------------------------------|:------------------------------------------------------------------------------------|----------:|-------------------:|-----------------------:|
| 2021   | 00      | Nacional      | Otros bienes jurídicos afectados (del fuero común) | Otros delitos del Fuero Común | Otros delitos del Fuero Común | Otros delitos del Fuero Común                                                       |       844 |          0.6543501 |                     NA |
| 2018   | 17      | Morelos       | El patrimonio                                      | Robo                          | Robo en transporte individual | Sin violencia                                                                       |        83 |          4.1910619 |                     NA |
| 2017   | 00      | Nacional      | El patrimonio                                      | Robo                          | Robo de maquinaria            | Robo de cables, tubos y otros objetos destinados a servicios públicos Sin violencia |         4 |          0.0032057 |                     NA |
| 2023   | 00      | Nacional      | La vida y la Integridad corporal                   | Feminicidio                   | Feminicidio                   | Con otro elemento                                                                   |         6 |          0.0045754 |              0.0089556 |
| 2022   | 23      | Quintana Roo  | La vida y la Integridad corporal                   | Feminicidio                   | Feminicidio                   | No especificado                                                                     |         4 |          0.2023103 |              0.4079938 |

## Bases de datos con `db_victimas_delitos_ent_long`

### Número anual de víctimas de delitos por género

#### Agrupación por año, estado, género y (sub)tipo el número de delitos

El enfoque de los proyectos donde uso estos conjuntos de datos
normalmente uso los datos de los años completos, esto no significa que
no uso el dato meses por mes solo que no es tan común.

También es importante agregar el valor nacional para comparaciones.

``` r
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
```

| n_year | cve_ent | nombre_estado    | bien_juridico_afectado           | tipo_de_delito                                        | subtipo_de_delito                                     | modalidad                                             | genero | n_victimas |
|:-------|:--------|:-----------------|:---------------------------------|:------------------------------------------------------|:------------------------------------------------------|:------------------------------------------------------|:-------|-----------:|
| 2015   | 32      | Zacatecas        | Libertad personal                | Otros delitos que atentan contra la libertad personal | Otros delitos que atentan contra la libertad personal | Otros delitos que atentan contra la libertad personal | Hombre |        111 |
| 2022   | 27      | Tabasco          | La sociedad                      | Trata de personas                                     | Trata de personas                                     | Trata de personas                                     | Hombre |          0 |
| 2019   | 05      | Coahuila         | La vida y la Integridad corporal | Lesiones                                              | Lesiones culposas                                     | No especificado                                       | Mujer  |          0 |
| 2024   | 01      | Aguascalientes   | El patrimonio                    | Extorsión                                             | Extorsión                                             | Extorsión                                             | Mujer  |         19 |
| 2023   | 15      | Estado de México | La vida y la Integridad corporal | Aborto                                                | Aborto                                                | Aborto                                                | Total  |        156 |
| 2024   | 05      | Coahuila         | La vida y la Integridad corporal | Lesiones                                              | Lesiones dolosas                                      | No especificado                                       | Total  |          0 |

#### Adjuntar el valor de la población del estado para el tasado de víctimas por 100 mil habitantes.

Similar al caso del los tasados de delitos a nivel municipal y estatal,
se tiene que agregar información específica de la población de mujeres
para el tasado del tasado del delito de Feminicidio.

``` r
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
```

| n_year | cve_ent | nombre_estado | bien_juridico_afectado           | tipo_de_delito | subtipo_de_delito | modalidad           | genero | n_victimas | n_victimas_x100khab | n_victimas_x100kmujeres |
|:-------|:--------|:--------------|:---------------------------------|:---------------|:------------------|:--------------------|:-------|-----------:|--------------------:|------------------------:|
| 2022   | 11      | Guanajuato    | La vida y la Integridad corporal | Lesiones       | Lesiones culposas | Con arma blanca     | Hombre |          0 |           0.0000000 |                      NA |
| 2016   | 07      | Chiapas       | Libertad personal                | Secuestro      | Secuestro         | Secuestro extorsivo | Mujer  |         10 |           0.1833726 |                      NA |
| 2018   | 16      | Michoacán     | La vida y la Integridad corporal | Homicidio      | Homicidio culposo | Con arma de fuego   | Total  |         21 |           0.4403086 |                      NA |
| 2018   | 26      | Sonora        | La vida y la Integridad corporal | Feminicidio    | Feminicidio       | Con otro elemento   | Total  |         13 |           0.4390730 |               0.8796634 |
| 2022   | 11      | Guanajuato    | La vida y la Integridad corporal | Feminicidio    | Feminicidio       | Con arma de fuego   | Total  |          5 |           0.0786063 |               0.1530254 |

### Número anual de víctimas de delitos por género y rango de edad

<!--TODO: Empezar a partir de aqui-->

#### Agrupar por año, estado, género, rango de edad y (sub)tipo el número

El objetivo de la agrupación de las diferentes categorías de género y
rango de edad es para poder desagregar la información de acuerdo a
diferentes necesidades del proyecto.

``` r
df_victimas_delitos_gender_age <- db_victimas_delitos_ent_long %>%
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
    values_from = n_victimas) %>%
  janitor::clean_names() %>%
  # select(-no_identificado) %>%
  pivot_longer(
    # cols = total_genero:mujer,
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
    values_from = n_victimas) %>%
  janitor::clean_names() %>%
  # Tener las nuevas categorías implica tener diversas combinaciones de 
  # la información como _número de víctimas de X delito hombres menores de 
  # edad_. No todas las combinaciones son relevantes, por lo que se tendrán 
  # que eliminar aquellas que contengan los valores `No identificado` o `No 
  # especificado`
  filter(genero != "no_identificado") %>%
  select(!starts_with("no_")) %>%
  # Renombrar rangos de edad
  rename(
    adultos = adultos_18_y_mas,
    # NNA = Niñas, niños y adolescentes
    nna = menores_de_edad_0_17) %>%
  pivot_longer(
    cols = total_edad:nna,
    names_to = "rango_de_edad",
    values_to = "n_victimas") %>%
  # Eliminar registros de hombre y total_genero 
  # en el subtipo_de_delito "Feminicidio"
  filter(
    !(genero %in% c("hombre", "total_genero") &
      subtipo_de_delito == "Feminicidio"))
```

| n_year | cve_ent | nombre_estado | bien_juridico_afectado           | tipo_de_delito                   | subtipo_de_delito                | modalidad                        | genero       | rango_de_edad | n_victimas |
|:-------|:--------|:--------------|:---------------------------------|:---------------------------------|:---------------------------------|:---------------------------------|:-------------|:--------------|-----------:|
| 2019   | 26      | Sonora        | La vida y la Integridad corporal | Homicidio                        | Homicidio doloso                 | No especificado                  | total_genero | adultos       |          0 |
| 2022   | 32      | Zacatecas     | La vida y la Integridad corporal | Feminicidio                      | Feminicidio                      | Con arma de fuego                | mujer        | adultos       |          2 |
| 2020   | 23      | Quintana Roo  | La sociedad                      | Otros delitos contra la sociedad | Otros delitos contra la sociedad | Otros delitos contra la sociedad | total_genero | nna           |          1 |
| 2018   | 25      | Sinaloa       | La vida y la Integridad corporal | Aborto                           | Aborto                           | Aborto                           | mujer        | adultos       |         NA |
| 2016   | 21      | Puebla        | La vida y la Integridad corporal | Feminicidio                      | Feminicidio                      | No especificado                  | mujer        | nna           |          0 |

Como resultado se tienen 9 diferentes combinaciones de
`genero`-`rango_de_edad`

> **NNA** = **N**iñas, **N**iños y **A**dolescentes

| genero       | rango_de_edad | descripcion                                               |
|:-------------|:--------------|:----------------------------------------------------------|
| total_genero | total_edad    | Total de víctimas de todos los géneros y todas las edades |
| total_genero | adultos       | Total de víctimas de todos los géneros, adultas           |
| total_genero | nna           | Total de víctimas de todos los géneros, NNA               |
| hombre       | total_edad    | Total de víctimas hombres de todas las edades             |
| hombre       | adultos       | Total de víctimas hombres adultos                         |
| hombre       | nna           | Total de víctimas hombres NNA                             |
| mujer        | total_edad    | Total de víctimas mujeres de todas las edades             |
| mujer        | adultos       | Total de víctimas mujeres adultas                         |
| mujer        | nna           | Total de víctimas mujeres NNA                             |

#### Adjuntar el valor de la población estatal correspondiente a la combinación de género y rango de edad para el tasado de víctimas por 100 mil habitantes.

El conjunto de datos `df_victimas_delitos_gender_age` tiene 10 columnas,
a lo que se agregarán 3 columnas extra:

- Tasado con respecto a la población total (ambos genero y todas las
  edades): Para todas las observaciones
- Tasado con respecto a la población total de mujeres (todas las
  edades): Únicamente para el género `mujer`
- Tasado con respecto a su combinación de `genero`-`rango_de_edad`

## Pendiente 7

Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat
hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus
viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet
tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero.
Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et,
aliquet facilisis mauris.

## Pendiente 8

Duis ac ex venenatis turpis vulputate porttitor ut euismod libero. Fusce
sem neque, volutpat mattis sapien id, ultrices porta elit. Sed consequat
risus eu diam vehicula aliquet. Sed in mi posuere risus sollicitudin
rutrum ut id odio. In hac habitasse platea dictumst. Duis tincidunt
interdum pellentesque. In blandit vulputate dui, nec iaculis diam
ullamcorper quis.

[^1]: Para mayor información sobre conjunto de datos, visitar:
    [Procesamiento y transformación de datos: Proyecciones de
    población](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano/conapo_proyecciones)

[^2]: Para mayor información sobre conjunto de datos, visitar:
    [Procesamiento y transformación de datos: Proyecciones de
    población](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano/conapo_proyecciones)
