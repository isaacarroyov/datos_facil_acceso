# Procesamiento de datos: Incidencia Delictiva del Fuero Común
Isaac Arroyo
12 de junio de 2024

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
- **Víctimas de Delitos del Fuero Común anual a nivel estatal
  (general)**:
  - Año
  - Ubicación (Codigo y nombre de la entidad)
  - Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
  - Número de delitos por género
  - Número de delitos por cada 100 mil habitantes del total de la
    población total por género
- **Víctimas de Delitos del Fuero Común anual a nivel estatal (rango de
  edad)**:
  - Año
  - Ubicación (Codigo y nombre de la entidad)
  - Bien Jurídico Afectado, Tipo, Subtipo y Modalidad del delito
  - Género
  - Rango de edad
  - Número de delitos
  - Número de delitos por cada 100 mil habitantes de la población total
  - Número de delitos por cada 100 mil habitantes de la población del
    rango de edad

> \[!NOTE\]
>
> Los conjuntos de datos propuestos y el procesamiento de datos están
> sujetos cambios dependiendo del desarrollo de los proyectos que se
> harán con ellos o conforme se avance en la documentación.

## Lista de cambios

Curabitur orci lacus, cursus a fermentum nec, pretium a nulla. Curabitur
nec condimentum eros. Aliquam nibh enim, ullamcorper in malesuada in,
egestas at magna. Sed commodo id dui sed varius:

- Nulla ultrices maximus risus.
- Nam sodales vehicula nulla, ut placerat nunc dignissim non.
- Quisque tincidunt justo a ultrices dignissim. Curabitur aliquet ut
  elit id aliquam.
- Vivamus dictum imperdiet odio, ac consequat augue dapibus pulvinar.
- Interdum et malesuada fames ac ante ipsum primis in faucibus.
- Donec sit amet libero a justo aliquam sagittis ut a eros.

## Pendiente 2

Cras vestibulum lacinia felis et gravida. Etiam tempus lorem et dictum
iaculis. Etiam dapibus magna nisl, eget eleifend quam auctor quis.
Maecenas semper nunc nec nunc tempus, non egestas purus porttitor.
Nullam nisi felis, suscipit vel ullamcorper vitae, lobortis euismod
lacus. Aenean molestie faucibus libero at efficitur. Sed suscipit a eros
at eleifend. In quis ante commodo, tempus nisl a, elementum neque.
Nullam convallis fermentum tortor. Nunc scelerisque, nunc vel
scelerisque tempor, metus justo dictum augue, et luctus ante sapien eu
tellus. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Vestibulum non tristique ante. Curabitur a risus non justo varius dictum
sed sit amet magna. Curabitur rhoncus, diam eget commodo finibus, metus
mi feugiat tellus, eu vestibulum lacus massa quis arcu.

## Pendiente 3

Suspendisse potenti. In cursus nibh ut diam cursus, vitae mattis erat
hendrerit. Aliquam ornare risus ut ante porta, in laoreet lectus
viverra. Etiam ligula magna, tincidunt quis dui in, cursus laoreet
tortor. Vivamus nec molestie ipsum. Suspendisse eu pulvinar libero.
Praesent eu consectetur ligula. Etiam purus dolor, commodo at leo et,
aliquet facilisis mauris.

## Pendiente 4

Duis ac ex venenatis turpis vulputate porttitor ut euismod libero. Fusce
sem neque, volutpat mattis sapien id, ultrices porta elit. Sed consequat
risus eu diam vehicula aliquet. Sed in mi posuere risus sollicitudin
rutrum ut id odio. In hac habitasse platea dictumst. Duis tincidunt
interdum pellentesque. In blandit vulputate dui, nec iaculis diam
ullamcorper quis.

## Pendiente 5

Curabitur orci lacus, cursus a fermentum nec, pretium a nulla. Curabitur
nec condimentum eros. Aliquam nibh enim, ullamcorper in malesuada in,
egestas at magna. Sed commodo id dui sed varius. Nulla ultrices maximus
risus. Nam sodales vehicula nulla, ut placerat nunc dignissim non.
Quisque tincidunt justo a ultrices dignissim. Curabitur aliquet ut elit
id aliquam. Vivamus dictum imperdiet odio, ac consequat augue dapibus
pulvinar. Interdum et malesuada fames ac ante ipsum primis in faucibus.
Donec sit amet libero a justo aliquam sagittis ut a eros.

## Pendiente 6

Cras vestibulum lacinia felis et gravida. Etiam tempus lorem et dictum
iaculis. Etiam dapibus magna nisl, eget eleifend quam auctor quis.
Maecenas semper nunc nec nunc tempus, non egestas purus porttitor.
Nullam nisi felis, suscipit vel ullamcorper vitae, lobortis euismod
lacus. Aenean molestie faucibus libero at efficitur. Sed suscipit a eros
at eleifend. In quis ante commodo, tempus nisl a, elementum neque.
Nullam convallis fermentum tortor. Nunc scelerisque, nunc vel
scelerisque tempor, metus justo dictum augue, et luctus ante sapien eu
tellus. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Vestibulum non tristique ante. Curabitur a risus non justo varius dictum
sed sit amet magna. Curabitur rhoncus, diam eget commodo finibus, metus
mi feugiat tellus, eu vestibulum lacus massa quis arcu.

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
