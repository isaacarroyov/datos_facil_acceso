# %% [markdown]
# ---
# title: 'CHIRPS: Extracción y procesamiento de datos de lluvia'
# author: Isaac Arroyo
# date-format: long
# date: last-modified
# lang: es
# format:
#   gfm:
#     toc: true
#     html-math-method: mathml
#     fig-width: 5
#     fig-asp: 0.75
#     fig-dpi: 300
#     code-annotations: below
#     wrap: none
# execute:
#   echo: true
#   eval: false
#   warning: false
# ---

# %% [markdown]
"""
## Introducción

En este documento se encuentra el código para la extracción de
la **Precipitación en milímetros (mm)**.

Cada aspecto del código, así como las decisiones tomadas sobre éste, se
documentan en diferentes secciones. Todo este archivo documenta el código
del archivo **`raster2csv_chirps.py`**.
"""

# %%
#| label: import-ee
import ee

# Trigger the authentication flow.
ee.Authenticate()

# Initialize the library.
ee.Initialize(project='project-name')

# %% [markdown]
"""
## Objetivo

Al finalizar la ejecución de cada una de las celdas de código se
tendrán 4 archivos CSV:

* Precipitación anual en milímetros
* Precipitación mensual en milímetros

Para cada uno de los conjuntos de datos, el periodo de información es de
un determinado año de interés y _nivel_ espacial (municipios, estados
o país).

> [!NOTE]  
>
> Pendiente por hacer: Código para tener como raster la anomalía de precipitación con respecto a la normal (porcentaje y milímetros). Se tiene como solución temporal el cálculo en **`documentacion_wide2long_chirps.R`**
"""

# %% [markdown]
"""
## Tabla de variables

La siguiente tabla indica las variables que tendrán que se actualizadas
de manera manual o que el usuario tiene que escribir para que todo el código
funcione.

|**Variable**|**Tipo**|**Notas**|
|:---|:---|:---|
|`n_year_interes`|Cambiante|Año del que se van a extraer las métricas de precipitación|
|`fc_interes`|Cambiante|`ee.FeatureCollection` de las geomtrías e información de los **Estados (`ent`)**, **Municipios (`mun`)** o **Nación (`nac`)**|
|`limit_date`|Cambiante|Fecha del límite próximo de los datos. Esta información se puede consultar en la página del la `ee.ImageCollection`|
"""

# %% [markdown]
"""
## Carga de CHIRPS
"""

# %%
#| label: load_chirps
chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
          .select("precipitation"))

# %% [markdown]
"""
## Enfoque en un solo año

`chirps` es una `ee.ImageCollection` de más de 15 mil imágenes
(`ee.Image`), y para optimizar la extracción de los datos,
se seleccionará únicamente un año (el de interés), esto reduce el número
de imágenes a 365.

Para ello se va a crear una función de etiquetado de fecha de cada
imagen.

> [!NOTE]
>
> A pesar de que la función no es necesaria al momento de filtrar
por año, servirá para operaciones donde se tenga que agrupar por
mes o semana.
"""

# %%
#| label: create-func_tag_date
def func_tag_date(img): # <1>
    full_date = ee.Date(ee.Number(img.get("system:time_start"))) # <2>
    n_year = ee.Number(full_date.get("year")) # <3>
    n_month = ee.Number(full_date.get("month")) # <3>
    n_day = ee.Number(full_date.get("day")) # <3>
    return img.set( # <4>
        {"n_year": n_year, # <4>
         "n_month": n_month}) # <4>

# %% [markdown]
"""
1. La función toma una sola `ee.Image`
2. Obtener la fecha de la imagen, como esta en formato UNIX, se tiene que
transformar a fecha con `ee.Date`
3. De la fecha se obtiene el valor numérico del año, mes, semana y día
4. Asignación de año  y mes como propiedades de la `ee.Image`
"""

# %% 
#| label: create-chirps_year_interes
n_year_interes = 1981 # <1>
chirps_year_interes = (chirps # <2>
                       .map(func_tag_date) # <2>
                       .filter(ee.Filter.eq("n_year", n_year_interes))) # <3>

# %% [markdown]
"""
1. Seleccionar el año de interés
2. Etiquetar fechas en el cojunto de datos
3. Filtrar por año de interés
"""

# %% [markdown]
"""
## Reducción a los periodos de interés

Aún con la reducción al año de interés (365 imágenes), lo que se busca es
poder contar con la información en periodos: anual, mensual, semanal
y diario.

Para ello se usan listas con el número de elementos de
cada periodo (menos para el periodo diario) para poder agrupar las
imágenes
"""

# %%
#| label: create-lists_week_month_year
list_month = ee.List.sequence(1, 12)
list_year = ee.List.sequence(n_year_interes, n_year_interes)

# %% [markdown]
"""
La transformación conlleva múltiples iteraciones, y mientras que en
JavaScript se puedan declarar funciones dentro de **`map`**, el caso de
Python tienen que ser funciones **`lambda`**

Las interaciones se llevan a cabo por cada elemento de la `ee.List`
"""

# %%
#| label: create-img_coll_pr-groupby_year_month_week
# - - Agrupación por año - - #
# ~ Lista de 1 ee.Image ~ #
list_pr_year = list_year.map(
    lambda element: (chirps_year_interes # <1>
                     .filter(ee.Filter.eq("n_year", element)) # <2>
                     .sum() # <3>
                     .set({"n_year": element}))) # <4>
imgcoll_pr_year = ee.ImageCollection(list_pr_year) # <5>

# - - Agrupación por mes - - #
# ~ Lista de 12 ee.Image ~ #
list_pr_month = list_month.map(
    lambda element: (chirps_year_interes
                     .filter(ee.Filter.eq("n_month", element))
                     .sum()
                     .set({"n_month": element})))

imgcoll_pr_month = ee.ImageCollection(list_pr_month)

# %% [markdown]
"""
1. Tomar la `ee.ImageCollection`
2. Filtrar por el periodo de interés (año o mes)
3. Sumar todos los pixeles = Acumulación de lluvia
4. Asignar el año de la información. Es útil para el momento de
exportar como CSV
5. La operación se hace dentro de una `ee.List`, y el resultado de cada
iteración del `map` es una imagen individual. Al final se tiene una
lista de `ee.Image` que puede ser transformada a una colección.
"""

# %% [markdown]
"""
## Periodos como bandas de una `ee.Image`

Para poder extraer la información de los raster, se tiene que crear una
imagen de _N_ bandas:

* `ee.Image` de 1 banda: Precipitación anual
* `ee.Image` de 12 bandas: Precipitación mensual

> [!IMPORTANT]
>
> Para obtener los datos del año en curso, se tienen que tomar en cuenta
que no todos los meses están disponibles. Es por eso que se harán
adaptaciones de las funciones de cálculos
"""

# %%
#| label: create-img_pr-year_month_week_day
from datetime import datetime

limit_date = "2024-08-31" # <1>
limit_date = datetime.strptime(limit_date, '%Y-%m-%d') # <1>
limit_date_month = limit_date.month # <1>
limit_date_year = limit_date.year # <1>

if limit_date_year == n_year_interes: # <2>
    dict_nombre_bandas = dict( # <3>
        month = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_month + 1)], # <3>
        year = [str(n_year_interes)]) # <3>
else:
    dict_nombre_bandas = dict( # <4>
        month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)], # <4>
        year = [str(n_year_interes)]) # <4>

img_pr_year = (imgcoll_pr_year # <5>
               .toBands() # <5>
               .rename(dict_nombre_bandas["year"])) # <6>

img_pr_month = (imgcoll_pr_month
                .toBands()
                .rename(dict_nombre_bandas["month"]))

# %% [markdown]
"""
1. Obtener los elementos de semana, mes y año del límite de información
próxima del conjunto de datos de CHIRPS Daily (Cambiante)
2. Comprobar si el año de interés es el año del límite de información próxima
3. Si el año de interés es el año del límite de información próxima, entonces
se toman como límites de meses los de la fecha límite.
4. Si el año de interés NO es el año del límite de información próxima,
entonces se toman todos los meses del año.
5. Pasar `ee.ImageCollection` de _**n**_ imágenes a una `ee.Image`
de _**n**_ bandas
6. Renombrar el nombre de las bandas a los números de los semanas, meses o años
"""

# %% [markdown]
"""
## De raster a `ee.FeatureCollection`

Para poder exportar la información como una tabla de CSV, primero se tiene
que almacenar o reducir la información a las geometrias de las regiones
del país (sean entidades, municipios o la nación).
"""

# %%
#| label: load-fc_interes
select_fc_interes = "mun"
dict_fc = dict(
    ent = "projects/project-name/assets/00ent",
    mun = "projects/project-name/assets/00mun")

if select_fc_interes == "nac":
    fc = (ee.FeatureCollection("USDOS/LSIB_SIMPLE/2017")
          .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")))
else:
    fc = ee.FeatureCollection(dict_fc[select_fc_interes])

# %% [markdown]
"""
El proceso de transformación se hará con las imágenes de todas las métricas.
"""

# %%
#| label: create-fc_pr-year_month_week_day
# - - Precipitación anual - - #
# ~ Pasar imagen a FeatureCollection ~ #
img2fc_pr_year = (img_pr_year # <1>
  .reduceRegions( # <1>
      collection = fc, # <1>
      reducer = ee.Reducer.mean(), # <1>
      scale = 5566) # <1>
  .map(lambda feature: (ee.Feature(feature) # <2>
                        .set({'n_year': n_year_interes}) # <2>
                        .setGeometry(None)))) # <2>

# ~ Corrección rara que tuve que hacer ~ #
# Nota: No se por qué hago esto, pero solo así funciona el código.
#       [Inserte meme de Bibi diciendo "Pues sucedió wey"]
fc_pr_year = ee.FeatureCollection( # <3>
  (img2fc_pr_year # <4>
   .toList(3000) # <4>
   .flatten())) # <5>

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

# %% [markdown]
"""
1. Se crea una `ee.FeatureCollection` a partir de la información de la
imagen de _n_ bandas. La información que se extraerá será de las geometrías
de interés. Se extraerá el promedio de la región. La escala de la extracción
es la misma que la resolución de CHIRPS, 5,566 m (se puede encontrar en la
página de información de CHIRPS)
2. Cuando se crea la nueva `ee.FeatureCollection`, se itera por cada
`ee.Feature` para poder asignar la propiedad (columna) del año de la
información. Las _n_ bandas se transforman en tambien en columnas,
entonces se tiene la información mensual. Finalmente se elimina la
geometría asignada porque de esta manera la exportación es más fácil y
no demora mucho.
3. Se crea una `ee.FeatureCollection` a partir de una lista de _features_
4. Transformar la `ee.Feature` a una lista de máximo 3000 elementos
5. Se eliminan sublistas (de existir).
"""

# %% [markdown]
"""
## Exportar `ee.FeatureCollection` a CSV

Todos los archivos van a tener se guardan en la carpeta
**pruebas_ee**
"""

# %%
#| label: create-filenames
# ~ Precipitación anual ~ #
filename_pr_year = f"chirps_pr_mm_{select_fc_interes}_year_{n_year_interes}"

# ~ Precipitación mensual ~ #
filename_pr_month = f"chirps_pr_mm_{select_fc_interes}_month_{n_year_interes}"

# %% [markdown]
"""
Finalmente, para cada tipo de archivo CSV, se crea
(`ee.Batch.Export.table`) y se manda al servidor Google Earth
Engine (`task.start()`)
"""

# %%
#| label: export-all_tasks
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
