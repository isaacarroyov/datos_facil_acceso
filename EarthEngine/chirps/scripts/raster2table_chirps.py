# %% [markdown]
# ---
# title: 'CHIRPS: Extracción y procesamiento de datos de lluvia'
# author: Isaac Arroyo
# date-format: long
# date: last-modified
# lang: es
# format:
#   gfm:
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
<!-- TODO: Renombrar este documento a documentacion_raster2csv_chirps.py previo a crear el script raster2csv_chirps.py -->

## Introducción

En este documento se encuentra el código para la extracción de variables 
derivadas de la precipitación tales como: 

* Precipitación en milímetros (mm)
* Anomalía de la precipitación en porcentaje (%) con respecto de la normal 
* Anomalía de la precipitación en milímetros (mm) con respecto de la normal

Cada aspecto del código, así como las decisiones tomadas sobre éste, se 
documentan en diferentes secciones. Todo este archivo documenta el código 
del archivo `raster2csv_chirps.py`.
"""

# %%
import ee # <1>

try:
    ee.Initialize() # <2>
    print("Se ha inicializado correctamente")
except:
    print("Error en la inicialización")

# %% [markdown]
"""
1. Importar API de (Google) Earth Engine
2. Inicializar API
"""

# %% [markdown]
"""
## Varibles y constantes

La extracción de datos se planea que sea periódica a niveles estatales y 
municipales, por lo que se dejan declarados variables que se mantendrán 
constantes (como el rango del promedio _normal_ o histórico) o (valga la 
redundancia) cambiarán dependiendo de los datos que se quieran. 

|**Variable**|**Tipo**|**Notas**|
|:---|:---|:---|
|`date_year_interes`|Cambiante|Año del que se van a extraer las métricas de precipitación|
|`fc`|Cambiante|`ee.FeatureCollection` de las geomtrías e información de los **Estados (`ent`)**, **Municipios (`mun`)** o **Cuencas Hidrológicas (`ch`)** de México|
|`metrica_interes`|Cambiante|Se elige entre 3: **Precipitación en milímetros (`pr`)**, **Anomalía de precipitación en proporción de la normal (`anomaly_pr_prop`)** o **Anomalía de precipitación en milímetros de la normal (`anomaly_pr_mm`)**|
|`tipo_de_periodo`|Cambiante|Se elige entre 3: **Semanal (`week`)**, **Mensual (`month`)** o **Anual (`year`)**|
|`chirps`|Constante|`ee.ImageCollection` de [CHIRPS Daily](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY)|
|`year_base_inicio`|Constante|Inicio del periodo historico para el cálculo de la normal, Enero 01 de 1981|
|`year_base_fin`|Constante|Fin del periodo historico para el cálculo de la normal, Diciembre 31 de 2010|
|`geom_mex`|Constante|Geometría del perímetro de México, usada para delimitar espacialmente la información|
"""

# %% 

date_year_interes = 2023 # <1>
select_fc = "ent" # <2>
dict_fc = dict( # <3>
    ent = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_ENT_2022", # <3>
    mun = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_MUN_2022") # <3>
fc = ee.FeatureCollection(dict_fc[select_fc]) # <4>

year_base_inicio = 1981 # <5>
year_base_fin = 2010 # <5>
geom_mex = (ee.FeatureCollection("USDOS/LSIB/2017") # <6>
            .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")) # <6>
            .first() # <6>
            .geometry()) # <6>

chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY') # <7>
          .select("precipitation") # <7>
          .filter(ee.Filter.bounds(geom_mex))) # <7>

chirps_year_interes = (chirps # <8>
    .filter(ee.Filter.calendarRange(start = date_year_interes, # <8>
                                    field = "year"))) # <8>

# %% [markdown]
"""
1. Selección del año de interés
2. Seleccion de `ee.FeatureCollection`, sea de Entidades (`ent`), 
Municipios (`mun`) o Cuencas Hidrológicas (`ch`^[Pendiente subir 
a Google Earth Engine])
3. Diccionario con los _paths_ hacia la `ee.FeatureCollection` de elección
4. Carga de `ee.FeatureCollection` de interés
5. Fechas de inicio y fin del periodo historico para el cálculo de la 
normal (30 años)
6. Obtener la geometría de México desde una `ee.FeatureCollection` de 
división politica de los países del mundo
7. `ee.ImageCollection` de CHIRPS Daily limitado a México
8. Limitar las imágenes al año de interés
"""

# %% [markdown]
"""
## Reducción a los periodos de interés

`chirps` es una `ee.ImageCollection` de más de 15 mil 
imágenes (`ee.Image`), y aún con la reducción al año de interés, son más 
de 300. El procesamiento y tratado de las imagenes es 
_pesado_, y aunque la computadora no se encargue de hacer el trabajo, 
esto puede hacer que el servidor de Google Earth demore en hacer los 
cálculos y la transformación de los datos raster.Es por eso que se tienen 
que definir los periodos de interés.
"""

# %% [markdown]
"""
### Etiquetado de semana, mes y  año

Para ir agrupando y sumando la precipitación del periodo de interés, hay 
que tener las imágenes etiquetadas para poder agruparlas.
"""

# %% 
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
"""

# %% [markdown]
"""
### Precipitación del periodo de interés

Para una fácil extracción de los valores del año es necesario tener la 
información de la precipitación (o la métrica de interés) como una 
`ee.Image` de _n_ bandas, donde cada banda es el valor semanal (52), 
mensual (12) o anual (1) de la región.

Para crear una imagen de _n_ bandas se necesita primero una 
`ee.ImageColletion` de _n_ imágenes.

Para ello, se va a crear una lista dependiendo del periodo, así como 
la adaptación de la función

La transformación conlleva múltiples iteraciones, y mientras que en 
JavaScript se puedan declarar funciones dentro de **`map`**, para el 
caso se Python se tendran que crear las funciones a parte, y después serán 
llamadas a su respectivo `map`.
"""

# %%
select_tipo_periodo = "month"
dict_tipo_periodo = dict(
    week = (ee.List.sequence(1, 52)
            .map(lambda element: (chirps_year_interes_tagged
                                  .filter(ee.Filter.eq("n_week", element))
                                  .sum()
                                  .set({"n_week": element})))),
    month = (ee.List.sequence(1, 12)
            .map(lambda element: (chirps_year_interes_tagged
                                  .filter(ee.Filter.eq("n_month", element))
                                  .sum()
                                  .set({"n_month": element})))),
    year = (ee.List.sequence(1, 12)
            .map(lambda element: (chirps_year_interes_tagged
                                  .filter(ee.Filter.eq("n_year", element))
                                  .sum()
                                  .set({"n_year": element})))))

list_tipo_periodo_pr = dict_tipo_periodo[select_tipo_periodo]

img_coll_tipo_periodo_pr = (ee.ImageCollection # <1>
                            .fromImages(list_tipo_periodo_pr)) # <1>

# %% [markdown]
"""
1. Se crea una colección de imágenes a partir de una lista.
"""

# %% [markdown]
"""
### Periodos como bandas de una `ee.ImageCollection`

Ya que se logró tener una colección de _n_ imágenes, entonces se crea la 
imagen de _n_ bandas

> [!IMPORTANT]
> 
> Para obtener los datos del año en curso, se tienen que tomar en cuenta 
que no todos los meses están disponibles. Es por eso que se harán 
adaptaciones de las funciones de cálculos
"""

# %%

from datetime import datetime

limit_date_str = "2024-06-30"
limit_date = datetime.strptime(limit_date_str, '%Y-%m-%d')
limit_date_week = limit_date.isocalendar().week
limit_date_month = limit_date.month
limit_date_year = limit_date.year

if limit_date_year == date_year_interes:
    dict_nombre_bandas = dict(
        week = [f"0{i}" if i < 10 else str(i) for i in range(1,53)],
        month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)],
        year = [date_year_interes])
else:
    dict_nombre_bandas = dict(
        week = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_week + 1)],
        month = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_month + 1)],
        year = [date_year_interes])


img_coll_tipo_periodo_pr = (img_coll_tipo_periodo_pr
                            .toBands() # <1>
                            .rename(dict_nombre_bandas[select_tipo_periodo])) # <2>

# %% [markdown]
"""
1. Pasar `ee.ImageCollection` de _**n**_ imágenes 
a una `ee.Image` de _**n**_ bandas
2. Renombrar el nombre de las bandas a los números de los meses
"""

# %% [markdown]
"""
## Métricas a extraer

El objetivo es poder extraer información sobre las lluvias de 
cada año, a las que se les prestará atención son:

* Precipitación en milímetros (mm)
* Anomalía de la precipitación en porcentaje (%) con respecto de la normal 
* Anomalía de la precipitación en milímetros (mm) con respecto de la normal

Para las últimas dos hace falta tener el valor de la **acumulación normal**.

### Acumulación normal

De acuerdo a con el [glosario de la NOAA](https://forecast.weather.gov/glossary.php?word=ANOMALY#:~:text=NOAA's%20National%20Weather%20Service%20%2D%20Glossary,water%20level%20minus%20the%20prediction.) 
una anomalía es la desviación de una unidad dentro de un periodo en una 
región en específico con respecto a su promedio histórico o normal. Este 
promedio es usualmente de 30 años.

Para el caso del CHIRPS, es de Enero 1981 hasta Diciembre 2010.

Esta tarea se tiene que hacer con ayuda de dos funciones. La primera 
etiquetará por mes, semana y año la colección _base_. La segunda función 
tendrá que reducir a las _n_ (depende del tipo de periodo de interés) 
imagenes cada año de esa base.
"""

# %% 
# TODO: Hasta aquí se llegó. Evaluar si se re-usan las funciones de 
#       periodo de interés
def func_tag_year_month_base_period(img): # <1>
    full_date = ee.Date(ee.Number(img.get("system:time_start"))) 
    n_year = ee.Number(full_date.get("year")) 
    n_month = ee.Number(full_date.get("month")) 
    return img.set({"n_month": n_month, "n_year": n_year})


def func_reduce2yearmonths_base_period(n_year): # <2>
    imgcoll_year_interes = (base_period_tagged
                            .filter(ee.Filter.eq("n_year", n_year)))
    def func_reduce2months_base_period(n_month): 
        return (imgcoll_year_interes
                .filter(ee.Filter.eq("n_month", n_month))
                .sum()
                .set({"n_year": n_year, "n_month": n_month}))
    list_monthly_pr_per_year = (list_months
                                .map(func_reduce2months_base_period))
    
    return list_monthly_pr_per_year

# %% [markdown]
"""
1. Función para etiquetar año y mes
2. Función para crear una lista de listas de precipitaciones mensuales para 
cada año del periodo base

Con estas dos funciones se creará una colección de imagenes 
de $\approx$ 360 imágenes
"""

# %% 
base_period = (chirps # <1>
  .filter(ee.Filter.calendarRange(start = year_base_inicio, # <1>
                                  end = year_base_fin, field = "year"))) # <1>

base_period_tagged = base_period.map(func_tag_year_month_base_period) # <2>

base_period_tagged_reduced_year_month = (ee.ImageCollection.fromImages( # <3>
    (ee.List # <4>
    .sequence(year_base_inicio, year_base_fin) # <4>
    .map(func_reduce2yearmonths_base_period) # <5>
    .flatten()))) # <6>

base_pr_monthly_accumulation = (ee.ImageCollection.fromImages( # <7>
    list_months.map(lambda n_month: ( # <8>
                      base_period_tagged_reduced_year_month # <9>
                      .filter(ee.Filter.eq("n_month", n_month)) # <9>
                      .mean() # <10>
                      .set({"n_month": n_month})))) # <11>
  .toBands() # <12>
  .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)])) # <13>
# %% [markdown]
"""
1. Limitar la colección los años del periodo de referencia
2. Etiquetar el año y mes al que pertenece cada imagen
3. Crear una `ee.ImageCollection` a partir de una lista
4. La es una secuencia de números que representan los años del periodo base
5. A cada elemento (número) se le aplica una función. Esta función regresa 
una lista de 12 imágenes por año, es decir, el resultado es una lista de 
30 elementos, donde cada elemento es una lista de 12 imágenes.
6. Se cambia la lista de sublistas a una lista, es decir, se _desempacan_ 
los elementos de las sublistas.
7. A partir de una lista se crea una colección
8. Esta lista es de 12 elementos, la lista del promedio historico de 
precipitación por cada mes del periodo base.
9. Se filtra por el mes indicado
10. Obtener la media de los 30 años
11. Marcar como propiedad el año del mes
12. De una coleccción de 12 imágenes, se crea una imagen de 12 bandas
13. Renombramiento de las bandas (número del mes) 

### Anomalía en milimetros 

Es la diferencia en milimetros, de la precipitación de un determinado 
mes $\left( \overline{x}_{i} \right)$ y el promedio histórico o la normal 
$\left( \mu_{\text{normal}} \right)$ de ese mes

$$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$
"""

# %% 
img_monthly_anomaly_mm = ee.Image((img_monthly_pr
  .subtract(base_pr_monthly_accumulation) # <1>
  .copyProperties(img_monthly_pr, img_monthly_pr.propertyNames()))) # <2>

# %% [markdown]
"""
1. Restar el promedio histórico
2. Copiar todas las propiedades en la nueva imagen

### Anomalía en porcentaje

Es el resultado de dividir la diferencia de la precipitación de un 
determinado mes $\left( \overline{x}_{i} \right)$ y el promedio 
histórico o la normal $\left( \mu_{\text{normal}} \right)$ entre la normal 
de ese mismo mes.

$$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$
"""

# %% 
img_monthly_anomaly_prop = ee.Image((img_monthly_pr
  .subtract(base_pr_monthly_accumulation) # <1>
  .divide(base_pr_monthly_accumulation) # <2>
  .copyProperties(img_monthly_pr, img_monthly_pr.propertyNames()))) # <3>

# %% [markdown]
"""
1. Restar el promedio histórico
2. Dividir entre el promedio histórico
3. Copiar todas las propiedades en la nueva imagen

# De raster a CSV

### Información de `ee.Image` a `ee.FeatureCollection`

> Este apartado se hará la demostración con **`img_monthly_pr`** pero 
puede ser aplicado a cualquiera de las imágenes que se crearon

Para poder exportar la información como una tabla de CSV, primero se tiene 
que almacenar o reducir la información a las geometrias de las regiones 
del país (sean entidades, municipios o cualquier otro tipo de división).
"""

# %%
img2fc_monthly_pr = (img_monthly_pr
  .reduceRegions( # <1>
      collection = fc, # <2>
      reducer = ee.Reducer.mean(), # <3>
      scale = 5566) # <4>
  .map(lambda feature: (ee.Feature(feature) # <5>
                        .set({'n_year': date_year_interes}) # <5>
                        .setGeometry(None)))) # <5>

fc_monthly_pr = ee.FeatureCollection( # <6>
  (img2fc_monthly_pr
   .toList(3000) # <7>
   .flatten())) # <8>

# %% [markdown]
"""
1. Se crea una `ee.FeatureCollection` a partir de la información de la 
imagen de 12 bandas
2. La información que se extraerá vendrá de las geometrías de México 
(sean entidades, municipios o cualquier otro tipo de división de interés)
3. Se extraerá el promedio de la región
4. La escala a la que se hará la reducción, debe ser la misma a la que 
se encuentra la imagen. Esta puede encontrarse en la página de información 
de la imagen o colección
5. Cuando se crea la nueva `ee.FeatureCollection`, se itera por cada 
`ee.Feature` para poder asignar la propiedad (columna) del año de la 
información. Las 12 bandas se transforman en tambien en columnas, 
entonces se tiene la información mensual. Finalmente se elimina la 
geometría asignada porque de esta manera la exporación es más fácil y 
no demora mucho.
6. Se crea una `ee.FeatureCollection` a partir de una lista de _features_
6. Transformar la `ee.Feature` a una lista de máximo 3000 elementos
7. Se eliminan sublistas (de existir).
"""

# %% [markdown]
"""
### Exportar `ee.FeatureCollection` a CSV


Dentro del editor de código de Earth Engine existe la función para exportar 
una tabla, pero para el caso de la API de Python se usa la librería de 
**`geemap`** a través de la función **`ee_export_vector_to_drive`**.
"""

# %%
from geemap import ee_export_vector_to_drive

description_task = f"{select_fc}_monthly_pr_{date_year_interes}"

ee_export_vector_to_drive(
  collection= fc_monthly_pr,
  description= description_task,
  fileFormat= "CSV",
  folder= "pruebas_ee")

# %% [markdown]
"""
## Código final

<!-- TODO: Eliminar para cuando se haya actualizado la documentación -->

Tras explicar cada aspecto del procesamiento y extracción de los datos 
se concluye el documento con la función para pasar los datos raster de 
CHIRPS a un archivo CSV.

La función toma como argumentos:

1. El año de interés
2. La métrica de interes: 
  * Precipitación $\rightarrow$ `pr`
  * Anomalía de precipitación en mm $\rightarrow$ `anomaly_pr_mm`
  * Anomalía de precipitación en porcentaje $\rightarrow$ `anomaly_pr_prop`
3. Tipo de `ee.FeatureCollection`:
  * Entidades $\rightarrow$ `ent`
  * Municipios $\rightarrow$ `mun`
  * Cuencas Hidrológicas $\rightarrow$ `ch`
"""

# %%
import ee # <1>
from geemap import ee_export_vector_to_drive # <1>

try:
    ee.Initialize() # <2>
    print("Se ha inicializado correctamente")
except:
    print("Error en la inicialización")

# %% [markdown]
"""
1. Cargar librerías y funciones necesarias
2. Inicializar sesion de Earth Engine

### Funciones escenciales
"""

# %%
def func_tag_date(img): # <1>
    full_date = ee.Date(ee.Number(img.get("system:time_start")))
    n_month = ee.Number(full_date.get("month"))
    return img.set({"n_month": n_month})

def func_tag_year_month_hist_pr(img): # <2>
    full_date = ee.Date(ee.Number(img.get("system:time_start"))) 
    n_year = ee.Number(full_date.get("year")) 
    n_month = ee.Number(full_date.get("month")) 
    return img.set({"n_month": n_month, "n_year": n_year})

# %% [markdown]
"""
1. Función para _taggear_ únicamente el mes
2. Función para _taggear_ año y mes. Usada únicamente para la 
`ee.ImageCollection` que cubre la normal de 30 años (1981-2010)

### Función de extracción, procesamiento y exportación de datos
"""
# %%
def extract_from_chirps_daily( # <1>
        year = 2024,
        metrica_interes = "pr",
        tipo_fc = 'ent'):
    
    dict_fc = dict( # <2>
        ent = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_ENT_2022",
        mun = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_MUN_2022")
    fc = ee.FeatureCollection(dict_fc[tipo_fc])

    geom_mex = (ee.FeatureCollection("USDOS/LSIB/2017") # <2>
                .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")) 
                .first()
                .geometry())

    chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY') # <3>
              .select("precipitation")
              .filter(ee.Filter.bounds(geom_mex)))

    chirps_year = (chirps.filter( # 4>
        ee.Filter.calendarRange(start = year, field = "year"))) # <4>

    chirps_year_tagged = chirps_year.map(func_tag_date) # <5>

    list_months = ee.List.sequence(1, 12)

    def func_reduce2months(n_month): 
        return (chirps_year_tagged
                .filter(ee.Filter.eq("n_month", n_month))
                .sum()
                .set({"n_month": n_month}))

    list_month_pr = (list_months.map(func_reduce2months)) # <6>

    imgcoll_month_pr = ee.ImageCollection.fromImages(list_month_pr) # <6>

    if year > 2023: # <7>
        img_bands = ["01", "02", "03", "04"] # <7>
    else: # <7>
        img_bands = [f"0{i}" if i < 10 else str(i) for i in range(1,13)] # <7>
    
    img_month_pr = imgcoll_month_pr.toBands().rename(img_bands) # <8>
    
    if metrica_interes != "pr": # <9>
        hist_pr = (chirps
            .filter(ee.Filter.calendarRange(1981, 2010, field = "year")))
        
        hist_pr_tagged = hist_pr.map(func_tag_year_month_hist_pr)

        def func_reduce2yearmonths_hist_pr(n_year): 
            imgcoll_interes = (hist_pr_tagged
                                .filter(ee.Filter.eq("n_year", n_year)))
            def func_reduce2months_hist_pr(n_month): 
                return (imgcoll_interes
                        .filter(ee.Filter.eq("n_month", n_month))
                        .sum()
                        .set({"n_year": n_year, "n_month": n_month}))
            list_month_pr_per_year = (list_months
                                        .map(func_reduce2months_hist_pr))
            return list_month_pr_per_year

        hist_pr_tagged_reduced_year_month = (ee.ImageCollection
            .fromImages((ee.List.sequence(1981, 2010)
                         .map(func_reduce2yearmonths_hist_pr)
                         .flatten())))

        img_hist_pr = (ee.ImageCollection.fromImages(
            list_months.map(lambda n_month: (
                            hist_pr_tagged_reduced_year_month
                            .filter(ee.Filter.eq("n_month", n_month))
                            .mean()
                            .set({"n_month": n_month}))))
            .toBands()
            .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)]))
        
        if metrica_interes == "anomaly_pr_mm": # <10>
            img_metrica_interes = ee.Image(
                (img_month_pr
                .subtract(img_hist_pr.select(img_bands))
                .copyProperties(img_hist_pr, img_hist_pr.propertyNames())))
        else:
            img_metrica_interes = ee.Image( # <11>
                (img_month_pr
                .subtract(img_hist_pr.select(img_bands))
                .divide(img_hist_pr.select(img_bands))
                .copyProperties(img_hist_pr, img_hist_pr.propertyNames())))
    else:
        img_metrica_interes = img_month_pr # <12>

    img2fc_metrica_interes = (img_metrica_interes # <13>
        .reduceRegions(collection = fc,
                       reducer = ee.Reducer.mean(),
                       scale = 5566)
        .map(lambda feature: (ee.Feature(feature)
                              .set({'n_year': year})
                              .setGeometry(None))))

    fc_metrica_interes = ee.FeatureCollection( # <13>
        img2fc_metrica_interes.toList(3000).flatten())
    
    # Guardar este pedo
    descr_task = f"chirps_daily_{metrica_interes}_{tipo_fc}_{year}" # <14>
    folder_name = f"gee_chirps_daily_{metrica_interes}" # <14>

    print(f"Va al servidor: '{descr_task}' y se gurda en {folder_name}") # <15>
    ee_export_vector_to_drive(
        collection = fc_metrica_interes,
        description= descr_task,
        fileFormat= "CSV",
        folder= folder_name)
    return None

# %% [markdown]
"""
1. La **precipitación** del **2024** en las **entidades** de México es lo 
que por _default_ se extraerá
2. Carga de geometrías y `ee.FeatureCollection`s
3. Carga de CHIRPS Daily
4. Selección del año del cual se obtendrán las metricas
5. Etiquetado de los meses a la `ee.ImageCollection` de interés
6. Reducción de una `ee.ImageCollection` de $\approx$ 365 imágenes a una de 
(máximo) 12 imágenes.
7. Si el año de interés es menor o igual que el 2023, entonces se tiene 
información de todos los meses (12 bandas), de lo contrario son menos
8. Renombramiento de las bandas a el número de los meses del año
9. Si la métrica **no es la precipitación (`'pr'`)**, es decir es anomalía 
de la precipitación en porcentaje (`'anomaly_pr_prop'`) o en milimetros 
(`'anomaly_pr_mm`'), entonces se hace el cálculo del promedio histórico 
de la precipitación de cada uno de los meses (`img_hist_pr`)
10. Identificar si es anomalía de la precipitación en milimetros (`'anomaly_pr_mm`')
11. Si no es `'anomaly_pr_mm`' entonces se hace la división del promedio 
histórico para el cálculo de la anomalía de la precipitación en porcentaje 
(`'anomaly_pr_prop'`)
12. Si la métrica de interés **es la precipitación (`'pr'`)**, entonces no 
se hace el cálculo del promedio histórico.
13. Se crea `ee.FeatureCollection` de la `ee.Image`
14. Se crean las variables para exportar los datos
15. Se exportan los resultados

### Extracción

Con el codigo creado en esta Sección lo único que queda por hacer es 
iterar o seleccionar el año, división política y tipo de métrica a extraer

```Python

for anio in range(1981, 2025): # <1>
    extract_from_chirps_daily(year = anio, # <2>
                              metrica_interes= "pr",
                              tipo_fc= "ent")

    extract_from_chirps_daily(year = anio, # <3>
                              metrica_interes= "pr",
                              tipo_fc= "mun")

    extract_from_chirps_daily(year = anio, # <4>
                              metrica_interes= "anomaly_pr_prop",
                              tipo_fc= "ent")

    extract_from_chirps_daily(year = anio, # <5>
                              metrica_interes= "anomaly_pr_prop",
                              tipo_fc= "mun")
```
1. Extraer información de todos los años disponibles 
2. Precipitación en los estados de México
3. Precipitación en los municipios de México
4. Anomalía de precipitación en porcentaje con respecto a la normal en 
los estados de México
5. Anomalía de precipitación en porcentaje con respecto a la normal en 
los municipios de México
"""