# CHIRPS: Extracción y procesamiento de datos de lluvia
Isaac Arroyo
20 de julio de 2025

- [Introducción](#introducción)
- [Objetivo](#objetivo)
- [Tabla de variables](#tabla-de-variables)
- [Carga de CHIRPS](#carga-de-chirps)
- [Enfoque en un solo año](#enfoque-en-un-solo-año)
- [Reducción a los periodos de interés](#reducción-a-los-periodos-de-interés)
- [Periodos como bandas de una `ee.Image`](#periodos-como-bandas-de-una-eeimage)
- [De raster a `ee.FeatureCollection`](#de-raster-a-eefeaturecollection)
- [Exportar `ee.FeatureCollection` a CSV](#exportar-eefeaturecollection-a-csv)

## Introducción

En este documento se encuentra el código para la extracción de la **Precipitación en milímetros (mm)**.

Cada aspecto del código, así como las decisiones tomadas sobre éste, se documentan en diferentes secciones. Todo este archivo documenta el código del archivo **`raster2csv_chirps.py`**.

``` python
import ee

# Trigger the authentication flow.
ee.Authenticate()

# Initialize the library.
ee.Initialize(project='project-name')
```

## Objetivo

Al finalizar la ejecución de cada una de las celdas de código se tendrán 4 archivos CSV:

- Precipitación anual en milímetros
- Precipitación mensual en milímetros

Para cada uno de los conjuntos de datos, el periodo de información es de un determinado año de interés y *nivel* espacial (municipios, estados o país).

> \[!NOTE\]
>
> Pendiente por hacer: Código para tener como raster la anomalía de precipitación con respecto a la normal (porcentaje y milímetros). Se tiene como solución temporal el cálculo en **`documentacion_wide2long_chirps.R`**

## Tabla de variables

La siguiente tabla indica las variables que tendrán que se actualizadas de manera manual o que el usuario tiene que escribir para que todo el código funcione.

| **Variable**     | **Tipo**  | **Notas**                                                                                                                     |
|:-----------------|:----------|:------------------------------------------------------------------------------------------------------------------------------|
| `n_year_interes` | Cambiante | Año del que se van a extraer las métricas de precipitación                                                                    |
| `fc_interes`     | Cambiante | `ee.FeatureCollection` de las geomtrías e información de los **Estados (`ent`)**, **Municipios (`mun`)** o **Nación (`nac`)** |
| `limit_date`     | Cambiante | Fecha del límite próximo de los datos. Esta información se puede consultar en la página del la `ee.ImageCollection`           |

## Carga de CHIRPS

``` python
chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
          .select("precipitation"))
```

## Enfoque en un solo año

`chirps` es una `ee.ImageCollection` de más de 15 mil imágenes (`ee.Image`), y para optimizar la extracción de los datos, se seleccionará únicamente un año (el de interés), esto reduce el número de imágenes a 365.

Para ello se va a crear una función de etiquetado de fecha de cada imagen.

> \[!NOTE\]
>
> A pesar de que la función no es necesaria al momento de filtrar por año, servirá para operaciones donde se tenga que agrupar por mes o semana.

``` python
def func_tag_date(img):
    full_date = ee.Date(ee.Number(img.get("system:time_start")))
    n_year = ee.Number(full_date.get("year"))
    n_month = ee.Number(full_date.get("month"))
    n_day = ee.Number(full_date.get("day"))
    return img.set(
        {"n_year": n_year,
         "n_month": n_month})
```

Línea 1  
La función toma una sola `ee.Image`

Línea 2  
Obtener la fecha de la imagen, como esta en formato UNIX, se tiene que transformar a fecha con `ee.Date`

Líneas 3-5  
De la fecha se obtiene el valor numérico del año, mes, semana y día

Líneas 6-8  
Asignación de año y mes como propiedades de la `ee.Image`

``` python
n_year_interes = 1981
chirps_year_interes = (chirps
                       .map(func_tag_date)
                       .filter(ee.Filter.eq("n_year", n_year_interes)))
```

Línea 1  
Seleccionar el año de interés

Líneas 2-3  
Etiquetar fechas en el cojunto de datos

Línea 4  
Filtrar por año de interés

## Reducción a los periodos de interés

Aún con la reducción al año de interés (365 imágenes), lo que se busca es poder contar con la información en periodos: anual, mensual, semanal y diario.

Para ello se usan listas con el número de elementos de cada periodo (menos para el periodo diario) para poder agrupar las imágenes

``` python
list_month = ee.List.sequence(1, 12)
list_year = ee.List.sequence(n_year_interes, n_year_interes)
```

La transformación conlleva múltiples iteraciones, y mientras que en JavaScript se puedan declarar funciones dentro de **`map`**, el caso de Python tienen que ser funciones **`lambda`**

Las interaciones se llevan a cabo por cada elemento de la `ee.List`

``` python
# - - Agrupación por año - - #
# ~ Lista de 1 ee.Image ~ #
list_pr_year = list_year.map(
    lambda element: (chirps_year_interes
                     .filter(ee.Filter.eq("n_year", element))
                     .sum()
                     .set({"n_year": element})))
imgcoll_pr_year = ee.ImageCollection(list_pr_year)

# - - Agrupación por mes - - #
# ~ Lista de 12 ee.Image ~ #
list_pr_month = list_month.map(
    lambda element: (chirps_year_interes
                     .filter(ee.Filter.eq("n_month", element))
                     .sum()
                     .set({"n_month": element})))

imgcoll_pr_month = ee.ImageCollection(list_pr_month)
```

Línea 4  
Tomar la `ee.ImageCollection`

Línea 5  
Filtrar por el periodo de interés (año o mes)

Línea 6  
Sumar todos los pixeles = Acumulación de lluvia

Línea 7  
Asignar el año de la información. Es útil para el momento de exportar como CSV

Línea 8  
La operación se hace dentro de una `ee.List`, y el resultado de cada iteración del `map` es una imagen individual. Al final se tiene una lista de `ee.Image` que puede ser transformada a una colección.

## Periodos como bandas de una `ee.Image`

Para poder extraer la información de los raster, se tiene que crear una imagen de *N* bandas:

- `ee.Image` de 1 banda: Precipitación anual
- `ee.Image` de 12 bandas: Precipitación mensual

> \[!IMPORTANT\]
>
> Para obtener los datos del año en curso, se tienen que tomar en cuenta que no todos los meses están disponibles. Es por eso que se harán adaptaciones de las funciones de cálculos

``` python
from datetime import datetime

limit_date = "2024-08-31"
limit_date = datetime.strptime(limit_date, '%Y-%m-%d')
limit_date_month = limit_date.month
limit_date_year = limit_date.year

if limit_date_year == n_year_interes:
    dict_nombre_bandas = dict(
        month = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_month + 1)],
        year = [str(n_year_interes)])
else:
    dict_nombre_bandas = dict(
        month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)],
        year = [str(n_year_interes)])

img_pr_year = (imgcoll_pr_year
               .toBands()
               .rename(dict_nombre_bandas["year"]))

img_pr_month = (imgcoll_pr_month
                .toBands()
                .rename(dict_nombre_bandas["month"]))
```

Líneas 3-6  
Obtener los elementos de semana, mes y año del límite de información próxima del conjunto de datos de CHIRPS Daily (Cambiante)

Línea 8  
Comprobar si el año de interés es el año del límite de información próxima

Líneas 9-11  
Si el año de interés es el año del límite de información próxima, entonces se toman como límites de meses los de la fecha límite.

Líneas 13-15  
Si el año de interés NO es el año del límite de información próxima, entonces se toman todos los meses del año.

Líneas 17-18  
Pasar `ee.ImageCollection` de ***n*** imágenes a una `ee.Image` de ***n*** bandas

Línea 19  
Renombrar el nombre de las bandas a los números de los semanas, meses o años

## De raster a `ee.FeatureCollection`

Para poder exportar la información como una tabla de CSV, primero se tiene que almacenar o reducir la información a las geometrias de las regiones del país (sean entidades, municipios o la nación).

``` python
select_fc_interes = "mun"
dict_fc = dict(
    ent = "projects/project-name/assets/00ent",
    mun = "projects/project-name/assets/00mun")

if select_fc_interes == "nac":
    fc = (ee.FeatureCollection("USDOS/LSIB_SIMPLE/2017")
          .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")))
else:
    fc = ee.FeatureCollection(dict_fc[select_fc_interes])
```

El proceso de transformación se hará con las imágenes de todas las métricas.

``` python
# - - Precipitación anual - - #
# ~ Pasar imagen a FeatureCollection ~ #
img2fc_pr_year = (img_pr_year
  .reduceRegions(
      collection = fc,
      reducer = ee.Reducer.mean(),
      scale = 5566)
  .map(lambda feature: (ee.Feature(feature)
                        .set({'n_year': n_year_interes})
                        .setGeometry(None))))

# ~ Corrección rara que tuve que hacer ~ #
# Nota: No se por qué hago esto, pero solo así funciona el código.
#       [Inserte meme de Bibi diciendo "Pues sucedió wey"]
fc_pr_year = ee.FeatureCollection(
  (img2fc_pr_year
   .toList(3000)
   .flatten()))

# - - Precipitación mensual - - #
img2fc_pr_month = (img_pr_month
  .reduceRegions(
      collection = fc,
      reducer = ee.Reducer.mean(),
      scale = 5566)
  .map(lambda feature: (ee.Feature(feature)
                        .set({'n_year': n_year_interes})
                        .setGeometry(None))))

fc_pr_month = ee.FeatureCollection(img2fc_pr_month.toList(3000).flatten())
```

Líneas 3-7  
Se crea una `ee.FeatureCollection` a partir de la información de la imagen de *n* bandas. La información que se extraerá será de las geometrías de interés. Se extraerá el promedio de la región. La escala de la extracción es la misma que la resolución de CHIRPS, 5,566 m (se puede encontrar en la página de información de CHIRPS)

Líneas 8-10  
Cuando se crea la nueva `ee.FeatureCollection`, se itera por cada `ee.Feature` para poder asignar la propiedad (columna) del año de la información. Las *n* bandas se transforman en tambien en columnas, entonces se tiene la información mensual. Finalmente se elimina la geometría asignada porque de esta manera la exportación es más fácil y no demora mucho.

Línea 15  
Se crea una `ee.FeatureCollection` a partir de una lista de *features*

Líneas 16-17  
Transformar la `ee.Feature` a una lista de máximo 3000 elementos

Línea 18  
Se eliminan sublistas (de existir).

## Exportar `ee.FeatureCollection` a CSV

Todos los archivos van a tener se guardan en la carpeta **pruebas_ee**

``` python
# ~ Precipitación anual ~ #
filename_pr_year = f"chirps_pr_mm_{select_fc_interes}_year_{n_year_interes}"

# ~ Precipitación mensual ~ #
filename_pr_month = f"chirps_pr_mm_{select_fc_interes}_month_{n_year_interes}"
```

Finalmente, para cada tipo de archivo CSV, se crea (`ee.Batch.Export.table`) y se manda al servidor Google Earth Engine (`task.start()`)

``` python
# ~ Exportar precipitación anual ~ #
task_pr_year = ee.batch.Export.table.toDrive(
    collection = fc_pr_year,
    description = filename_pr_year,
    folder = "pruebas_ee")
task_pr_year.start()

# ~ Exportar precipitacion mensual ~ #
task_pr_month = ee.batch.Export.table.toDrive(
    collection = fc_pr_month,
    description = filename_pr_month,
    folder = "pruebas_ee")
task_pr_month.start()
```
