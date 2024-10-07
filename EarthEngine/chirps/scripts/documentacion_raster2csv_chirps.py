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
En este documento se encuentra el código para la extracción de variables
derivadas de la precipitación tales como:

* Precipitación en milímetros (mm)
* Anomalía de la precipitación en porcentaje (%) con respecto de la normal
* Anomalía de la precipitación en milímetros (mm) con respecto de la normal

Cada aspecto del código, así como las decisiones tomadas sobre éste, se
documentan en diferentes secciones. Todo este archivo documenta el código
del archivo **`raster2csv_chirps.py`**.

> [!IMPORTANT]
>
> Este código fue creado para ser ejecutado en el ambiente de Google 
Colaboratory, ya que es la manera más sencilla de usar la API de 
Earth Engine debido a las nuevas políticas y condiciones de uso. Estas 
políticas y condiciones (en resumen) dicen que para poder hacer uso de la 
API de Earth Engine se tiene que **crear un proyecto** en la nube.
> 
> Una vez que se haya creado el proyecto (`project-name`), entonces se 
podrá inicializar la librería con el nombre (no olvidar el primer paso, 
que es la autenticación).
"""

# %%
#| label: initialize_earthengine
import ee

# Autenticar cuenta de Google asociada a Earth Engine
ee.Authenticate()

# Inicializar la librería
ee.Initialize(project='project-name')

# %% [markdown]
"""
## Varibles y constantes

La extracción de datos se planea que sea periódica a niveles estatales y
municipales, por lo que se dejan declarados variables que se mantendrán
constantes (como el rango del promedio _normal_ o histórico) o (valga la
redundancia) cambiarán dependiendo de los datos que se quieran.

|**Variable**|**Tipo**|**Notas**|
|:---|:---|:---|
|`n_year_interes`|Cambiante|Año del que se van a extraer las métricas de precipitación|
|`fc_interes`|Cambiante|`ee.FeatureCollection` de las geomtrías e información de los **Estados (`ent`)**, **Municipios (`mun`)** o **Cuencas Hidrológicas (`ch`)** de México|
|`periodo_interes`|Cambiante|Se elige entre 3: **Semanal (`week`)**, **Mensual (`month`)** o **Anual (`year`)**|
|`limit_date`|Cambiante|Fecha del límite próximo de los datos. Esta información se puede consultar en la página del la `ee.ImageCollection`|
|`geom_mex`|Constante|Geometría del perímetro de México, usada para delimitar espacialmente la información|
|`chirps`|Constante|`ee.ImageCollection` de [CHIRPS Daily](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY)|
|`year_normal_inicio`|Constante|Inicio del periodo historico para el cálculo de la normal, Enero 01 de 1981|
|`year_normal_fin`|Constante|Fin del periodo historico para el cálculo de la normal, Diciembre 31 de 2010|
"""

# %% [markdown]
"""
## Carga de CHIRPS
"""

# %%
#| label: load-geom_mex-chirps
geom_mex = (ee.FeatureCollection("USDOS/LSIB/2017") # <1>
            .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")) # <1>
            .first() # <1>
            .geometry()) # <1>

chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY') # <2>
          .select("precipitation") # <2>
          .filter(ee.Filter.bounds(geom_mex))) # <2>

# %% [markdown]
"""
1. Obtener la geometría de México desde una `ee.FeatureCollection` de
división politica de los países del mundo
2. `ee.ImageCollection` de CHIRPS Daily limitado a México
"""

# %% [markdown]
"""
## Enfoque en el año de interés

`chirps` es una `ee.ImageCollection` de más de 15 mil imágenes
(`ee.Image`), y hacer los cálculos de anomalía de precipitación (sea en
porcentaje/proporción o milímetros) en cada una de las imágenes es un
trabajo computacional pesado. Aunque la computadora no se encargue de
hacer el trabajo de manera local, esto puede hacer que el servidor de
Google Earth demore en hacer los cálculos y la transformación de los
datos raster.

Para optimizar la extracción de los datos, se seleccionará únicamente un
año de interés, esto reduce el número de imágenes a 365.
"""

# %%
#| label: filter-year_of_interes
n_year_interes = 2023

chirps_year_interes = (chirps
    .filter(ee.Filter.calendarRange(start = n_year_interes,
                                    field = "year")))

# %% [markdown]
"""
## Reducción a los periodos de interés

Aún con la reducción al año de interés (365 imágenes), lo que se busca es
poder contar con la información en periodos de interés (semanal, mensual o
anual).
"""

# %%
#| label: set-periodo_interes
periodo_interes = "month"

# %% [markdown]
"""
### Etiquetado de semana, mes y  año

Para ir sumando la precipitación en los periodos de interés, hay
que tener las imágenes etiquetadas para que sean agrupadas.
"""

# %%
#| label: create-func_tag_date
def func_tag_date(img): # <1>
    full_date = ee.Date(ee.Number(img.get("system:time_start"))) # <2>
    n_week = ee.Number(full_date.get("week")) # <3>
    n_month = ee.Number(full_date.get("month")) # <3>
    n_year = ee.Number(full_date.get("year")) # <3>
    return img.set( # <4>
        {"n_week":n_week, # <4>
         "n_month": n_month, # <4>
         "n_year": n_year }) # <4>

chirps_year_interes_tagged = chirps_year_interes.map(func_tag_date) # <5>

# %% [markdown]
"""
1. La función toma una sola `ee.Image`
2. Obtener la fecha de la imagen, como esta en formato UNIX, se tiene que
transformar a fecha con `ee.Date`
3. De la fecha se obtiene el valor numérico de la semana, mes o año
4. Asignación de año y semana del año como propiedades de la `ee.Image`
5. Crear nueva `ee.ImageCollection` con el etiquetado

Junto con el etiquetado de las fecha de la imagen, se crean listas
(`ee.List`) de secuencias de números de acuerdo con el periodo de
interés: semanal (52), mensual (12) o anual (1).
"""

# %%
#| label: create-dict_list_periodo_interes
dict_list_periodo_interes = dict(
    week = ee.List.sequence(1, 52),
    month = ee.List.sequence(1, 12))

# %% [markdown]
"""
### Precipitación del periodo de interés

Para una fácil extracción de los valores del año es necesario tener la
información de la precipitación (o la métrica de interés) como una
`ee.Image` de _n_ bandas, donde cada banda es el valor semanal (52),
mensual (12) o anual (1) de la región.

Para crear una imagen de _n_ bandas se necesita primero una
`ee.ImageColletion` de _n_ imágenes.

La transformación conlleva múltiples iteraciones, y mientras que en
JavaScript se puedan declarar funciones dentro de **`map`**, el caso de
Python tienen que ser funciones **`lambda`**
"""

# %%
#| label: create-dict_reducer_periodo_interes
dict_reducer_periodo_interes = dict(
    week = (dict_list_periodo_interes["week"]
            .map(lambda element: (chirps_year_interes_tagged
                                  .filter(ee.Filter.eq("n_week", element))
                                  .sum()
                                  .set({"n_week": element})))),
    month = (dict_list_periodo_interes["month"]
            .map(lambda element: (chirps_year_interes_tagged
                                  .filter(ee.Filter.eq("n_month", element))
                                  .sum()
                                  .set({"n_month": element})))),
    year = (ee.List.sequence(n_year_interes, n_year_interes)
            .map(lambda element: (chirps_year_interes_tagged
                                  .filter(ee.Filter.eq("n_year", element))
                                  .sum()
                                  .set({"n_year": element})))))

list_img_periodo_interes_pr = dict_reducer_periodo_interes[periodo_interes]

imgcoll_periodo_interes_pr = (ee.ImageCollection
                              .fromImages(list_img_periodo_interes_pr))

# %% [markdown]
"""
### Periodos como bandas de una `ee.Image`

Ya que se logró tener una colección de _n_ imágenes, entonces se crea la
imagen de _n_ bandas.

> [!IMPORTANT]
>
> Para obtener los datos del año en curso(al tiempo de modificación de este
documento, es Julio 2024), se tienen que tomar en cuenta
que no todos los meses están disponibles. Es por eso que se harán
adaptaciones de las funciones de cálculos
"""

# %%
#| label: create-img_periodo_interes_pr
from datetime import datetime

limit_date = "2024-08-31" # <1>
limit_date = datetime.strptime(limit_date, '%Y-%m-%d') # <1>
limit_date_week = limit_date.isocalendar().week # <1>
limit_date_month = limit_date.month # <1>
limit_date_year = limit_date.year # <1>

if limit_date_year == n_year_interes: # <2>
    dict_nombre_bandas = dict( # <3>
        week = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_week + 1)], # <3>
        month = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_month + 1)], # <3>
        year = [str(n_year_interes)]) # <3>
else:
    dict_nombre_bandas = dict( # <4>
        week = [f"0{i}" if i < 10 else str(i) for i in range(1,53)], # <4>
        month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)], # <4>
        year = [str(n_year_interes)]) # <4>

img_periodo_interes_pr = (imgcoll_periodo_interes_pr # <5>
                          .toBands() # <5>
                          .rename(dict_nombre_bandas[periodo_interes])) # <6>

# %% [markdown]
"""
1. Obtener los elementos de semana, mes y año del límite de información
próxima del conjunto de datos de CHIRPS Daily (Cambiante)
2. Comprobar si el año de interés es el año del límite de información próxima
3. Si el año de interés es el año del límite de información próxima, entonces
se toman como límites de semanas o meses, los de la fecha límite.
4. Si el año de interés NO es el año del límite de información próxima,
entonces se toman todos los meses y semanas del año.
5. Pasar `ee.ImageCollection` de _**n**_ imágenes a una `ee.Image`
de _**n**_ bandas
6. Renombrar el nombre de las bandas a los números de los semanas, meses o años
"""

# %% [markdown]
"""
---

> [!NOTE]
>
> Pendiente por hacer: Código para tener como raster la anomalía de 
precipitación con respecto a la normal (porcentaje y milímetros). Se tiene 
como solución temporal el cálculo en **`documentacion_wide2long_chirps.R`**

---
"""

# %% [markdown]
"""
## Métricas a extraer

El objetivo es poder extraer información sobre las lluvias de
cada año, a las que se les prestará atención son:

* Precipitación en milímetros (mm)
"""

# %%
img_periodo_interes_pr

# %% [markdown]
"""
## De raster a CSV

### Información de `ee.Image` a `ee.FeatureCollection`

Para poder exportar la información como una tabla de CSV, primero se tiene
que almacenar o reducir la información a las geometrias de las regiones
del país (sean entidades, municipios o cualquier otro tipo de división).

> [!IMPORTANT]
>
> Para poder adaptar este código a las geometrías que se desean, se tienen 
que importar directamente al proyecto de Google Earth Engine

"""

# %%
#| label: create_define-fc_roi
select_fc_interes = "ent"
dict_fc = dict( # <3>
    ent = "projects/project-name/assets/00ent",
    mun = "projects/project-name/assets/00mun")
fc_interes = ee.FeatureCollection(dict_fc[select_fc_interes])

# %% [markdown]
"""
El proceso de transformación se hará con las imágenes de todas las métricas.
"""

# %%
#| label: create-img2fc_periodo_interes_pr-and-fc_periodo_interes_pr
# ~ Precipitación en milímetros (mm) ~ #
img2fc_periodo_interes_pr = (img_periodo_interes_pr
  .reduceRegions( # <1>
      collection = fc_interes, # <1>
      reducer = ee.Reducer.mean(), # <1>
      scale = 5566) # <1>
  .map(lambda feature: (ee.Feature(feature) # <2>
                        .set({'n_year': n_year_interes}) # <2>
                        .setGeometry(None)))) # <2>

# Nota: No se por qué hago esto, pero solo así funciona el código.
#       [Inserte meme de Bibi diciendo "Pues sucedió wey"]
fc_periodo_interes_pr = ee.FeatureCollection( # <3>
  (img2fc_periodo_interes_pr # <4>
   .toList(3000) # <4>
   .flatten())) # <5>

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
### Exportar `ee.FeatureCollection` a CSV

Dentro del editor de código de Earth Engine existe la función para exportar
una tabla, pero para el caso de la API de Python se usa la librería de
[**`geemap`**](https://geemap.org/) a través de la función
**`ee_export_vector_to_drive`**.
"""

# %%
#| label: import-ee_export_vector_to_drive
from geemap import ee_export_vector_to_drive

# %% [markdown]
"""
Al momento de exportar las `ee.FeatureCollection`, se tiene que hacer
con una descripción de la tarea, así como el nombre del archivo.

La descripción es obligatoria pero el nombre del archivo no, por lo que
con solo la descripción es más que suficiente (el nombre del archivo
toma el nombre de la descripción).
"""

# %%
#| label: export-chirps-data
# ~ Precipitación en milímetros (mm) ~ #
description_task_pr = f"pr_{select_fc_interes}_{periodo_interes}_{n_year_interes}"

ee_export_vector_to_drive(
  collection= fc_periodo_interes_pr,
  description= description_task_pr,
  fileFormat= "CSV",
  folder= "pruebas_ee")