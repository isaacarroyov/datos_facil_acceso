# CHIRPS: Extracción y procesamiento de datos de lluvia
Isaac Arroyo
25 de julio de 2024

- [Introducción](#introducción)
- [Varibles y constantes](#varibles-y-constantes)
- [Carga de CHIRPS](#carga-de-chirps)
- [Enfoque en el año de interés](#enfoque-en-el-año-de-interés)
- [Reducción a los periodos de interés](#reducción-a-los-periodos-de-interés)
  - [Etiquetado de semana, mes y año](#etiquetado-de-semana-mes-y-año)
  - [Precipitación del periodo de interés](#precipitación-del-periodo-de-interés)
  - [Periodos como bandas de una `ee.Image`](#periodos-como-bandas-de-una-eeimage)
- [Acumulación normal](#acumulación-normal)
- [Métricas a extraer](#métricas-a-extraer)
  - [Precipitación en milímetros](#precipitación-en-milímetros)
  - [Anomalía en milimetros](#anomalía-en-milimetros)
  - [Anomalía en porcentaje](#anomalía-en-porcentaje)
- [De raster a CSV](#de-raster-a-csv)
  - [Información de `ee.Image` a `ee.FeatureCollection`](#información-de-eeimage-a-eefeaturecollection)
  - [Exportar `ee.FeatureCollection` a CSV](#exportar-eefeaturecollection-a-csv)

## Introducción

En este documento se encuentra el código para la extracción de variables derivadas de la precipitación tales como:

- Precipitación en milímetros (mm)
- Anomalía de la precipitación en porcentaje (%) con respecto de la normal
- Anomalía de la precipitación en milímetros (mm) con respecto de la normal

Cada aspecto del código, así como las decisiones tomadas sobre éste, se documentan en diferentes secciones. Todo este archivo documenta el código del archivo **`raster2csv_chirps.py`**.

``` python
import ee 

try:
    ee.Initialize() 
    print("Se ha inicializado correctamente")
except:
    print("Error en la inicialización")
```

## Varibles y constantes

La extracción de datos se planea que sea periódica a niveles estatales y municipales, por lo que se dejan declarados variables que se mantendrán constantes (como el rango del promedio *normal* o histórico) o (valga la redundancia) cambiarán dependiendo de los datos que se quieran.

| **Variable**         | **Tipo**  | **Notas**                                                                                                                                            |
|:---------------------|:----------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `n_year_interes`     | Cambiante | Año del que se van a extraer las métricas de precipitación                                                                                           |
| `fc_interes`         | Cambiante | `ee.FeatureCollection` de las geomtrías e información de los **Estados (`ent`)**, **Municipios (`mun`)** o **Cuencas Hidrológicas (`ch`)** de México |
| `periodo_interes`    | Cambiante | Se elige entre 3: **Semanal (`week`)**, **Mensual (`month`)** o **Anual (`year`)**                                                                   |
| `limit_date`         | Cambiante | Fecha del límite próximo de los datos. Esta información se puede consultar en la página del la `ee.ImageCollection`                                  |
| `geom_mex`           | Constante | Geometría del perímetro de México, usada para delimitar espacialmente la información                                                                 |
| `chirps`             | Constante | `ee.ImageCollection` de [CHIRPS Daily](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY)                            |
| `year_normal_inicio` | Constante | Inicio del periodo historico para el cálculo de la normal, Enero 01 de 1981                                                                          |
| `year_normal_fin`    | Constante | Fin del periodo historico para el cálculo de la normal, Diciembre 31 de 2010                                                                         |

## Carga de CHIRPS

``` python
geom_mex = (ee.FeatureCollection("USDOS/LSIB/2017")
            .filter(ee.Filter.eq("COUNTRY_NA", "Mexico"))
            .first()
            .geometry())

chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
          .select("precipitation")
          .filter(ee.Filter.bounds(geom_mex)))
```

Líneas 1-4  
Obtener la geometría de México desde una `ee.FeatureCollection` de división politica de los países del mundo

Líneas 6-8  
`ee.ImageCollection` de CHIRPS Daily limitado a México

## Enfoque en el año de interés

`chirps` es una `ee.ImageCollection` de más de 15 mil imágenes (`ee.Image`), y hacer los cálculos de anomalía de precipitación (sea en porcentaje/proporción o milímetros) en cada una de las imágenes es un trabajo computacional pesado. Aunque la computadora no se encargue de hacer el trabajo de manera local, esto puede hacer que el servidor de Google Earth demore en hacer los cálculos y la transformación de los datos raster.

Para optimizar la extracción de los datos, se seleccionará únicamente un año de interés, esto reduce el número de imágenes a 365.

``` python
n_year_interes = 2023

chirps_year_interes = (chirps
    .filter(ee.Filter.calendarRange(start = n_year_interes,
                                    field = "year")))
```

## Reducción a los periodos de interés

Aún con la reducción al año de interés (365 imágenes), lo que se busca es poder contar con la información en periodos de interés (semanal, mensual o anual).

``` python
periodo_interes = "month"
```

### Etiquetado de semana, mes y año

Para ir sumando la precipitación en los periodos de interés, hay que tener las imágenes etiquetadas para que sean agrupadas.

``` python
def func_tag_date(img):
    full_date = ee.Date(ee.Number(img.get("system:time_start")))
    n_week = ee.Number(full_date.get("week"))
    n_month = ee.Number(full_date.get("month"))
    n_year = ee.Number(full_date.get("year"))
    return img.set(
        {"n_week":n_week,
         "n_month": n_month,
         "n_year": n_year })

chirps_year_interes_tagged = chirps_year_interes.map(func_tag_date)
```

Línea 1  
La función toma una sola `ee.Image`

Línea 2  
Obtener la fecha de la imagen, como esta en formato UNIX, se tiene que transformar a fecha con `ee.Date`

Líneas 3-5  
De la fecha se obtiene el valor numérico de la semana, mes o año

Líneas 6-9  
Asignación de año y semana del año como propiedades de la `ee.Image`

Línea 11  
Crear nueva `ee.ImageCollection` con el etiquetado

Junto con el etiquetado de las fecha de la imagen, se crean listas (`ee.List`) de secuencias de números de acuerdo con el periodo de interés: semanal (52), mensual (12) o anual (1).

``` python
dict_list_periodo_interes = dict(
    week = ee.List.sequence(1, 52),
    month = ee.List.sequence(1, 12))
```

### Precipitación del periodo de interés

Para una fácil extracción de los valores del año es necesario tener la información de la precipitación (o la métrica de interés) como una `ee.Image` de *n* bandas, donde cada banda es el valor semanal (52), mensual (12) o anual (1) de la región.

Para crear una imagen de *n* bandas se necesita primero una `ee.ImageColletion` de *n* imágenes.

La transformación conlleva múltiples iteraciones, y mientras que en JavaScript se puedan declarar funciones dentro de **`map`**, el caso de Python tienen que ser funciones **`lambda`**

``` python
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
```

### Periodos como bandas de una `ee.Image`

Ya que se logró tener una colección de *n* imágenes, entonces se crea la imagen de *n* bandas.

> \[!IMPORTANT\]
>
> Para obtener los datos del año en curso(al tiempo de modificación de este documento, es Julio 2024), se tienen que tomar en cuenta que no todos los meses están disponibles. Es por eso que se harán adaptaciones de las funciones de cálculos

``` python
from datetime import datetime

limit_date = "2024-06-30"
limit_date = datetime.strptime(limit_date, '%Y-%m-%d')
limit_date_week = limit_date.isocalendar().week
limit_date_month = limit_date.month
limit_date_year = limit_date.year

if limit_date_year == n_year_interes:
    dict_nombre_bandas = dict(
        week = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_week + 1)],
        month = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_month + 1)],
        year = [n_year_interes])
else:
    dict_nombre_bandas = dict(
        week = [f"0{i}" if i < 10 else str(i) for i in range(1,53)],
        month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)],
        year = [n_year_interes])

img_periodo_interes_pr = (imgcoll_periodo_interes_pr
                          .toBands()
                          .rename(dict_nombre_bandas[periodo_interes]))
```

Líneas 3-7  
Obtener los elementos de semana, mes y año del límite de información próxima del conjunto de datos de CHIRPS Daily (Cambiante)

Línea 9  
Comprobar si el año de interés es el año del límite de información próxima

Líneas 10-13  
Si el año de interés es el año del límite de información próxima, entonces se toman como límites de semanas o meses, los de la fecha límite.

Líneas 15-18  
Si el año de interés NO es el año del límite de información próxima, entonces se toman todos los meses y semanas del año.

Líneas 20-21  
Pasar `ee.ImageCollection` de ***n*** imágenes a una `ee.Image` de ***n*** bandas

Línea 22  
Renombrar el nombre de las bandas a los números de los semanas, meses o años

------------------------------------------------------------------------

## Acumulación normal

> \[!WARNING\]
>
> Las secciones **Acumulación normal**, **Métricas a extraer: Anomalía en milimetros**, **Métricas a extraer: Anomalía en porcentaje**, así como cualquier operación relacionada al cálculo de la normal y de las anomalías, quedan temporalmente en pausa hasta que se encuentre una manera de mejorar su extracción semananal, mensual y anual.
>
> Esta decisión se debe al error de tiempo de ejecución en los servidores de Google Earth Engine.
>
> En lo que se encuentra la solución los valores de las anomalías serán el resultado de CSV exportados de la acumulación de la precipitación (semanal, mensual o anual)

De acuerdo a con el [glosario de la NOAA](https://forecast.weather.gov/glossary.php?word=ANOMALY#:~:text=NOAA's%20National%20Weather%20Service%20%2D%20Glossary,water%20level%20minus%20the%20prediction.) una anomalía es la desviación de una unidad dentro de un periodo en una región en específico con respecto a su promedio histórico o normal. Este promedio es usualmente de 30 años.

Para el caso del CHIRPS, es de Enero 1981 hasta Diciembre 2010.

La colección **`imgcoll_normal_pr`** tiene más de 10 mil imágenes, y para que pueda ser usada en los cálculos de las anomalías se necesita que sea una imagen de *n* bandas (recordatorio: *n* es el número de elementos de un periodo de interés: semanal (52), mensual (12) y anual (1)), donde cada banda sea el promedio histórico de la acumulación de la precipitación.

Primero se etiquetará por mes, semana y año la colección *base*. Esta función ya fue creada (**`func_tag_date`**).

Una función tendrá que crear una lista de 30 $\times$ *n* bandas. Esta función tiene que hacer dos procesos:

1.  Aislar uno año del periodo normal
2.  Reducir ese año en los periodos de interés y almacenar esas imágenes en una lista.

Para el segundo paso, se va a crear un diccionario especial para la reducción a esos periodos. Es especial, porque así como el diccionario `dict_reducer_periodo_interes`, toma por defecto la `ee.ImageCollection` del año de interés

1.  Se aisla la `ee.ImageCollection` de un solo año del periodo normal
2.  Diccionario especial con las operaciones de reducción a los periodos de interés dependiendo del periodo que se eligió desde un inicio. Para el caso de que el periodo de interés sea `'year'`, se hace una lista especial de un solo elemento: el año del periodo normal filtrado (`n_year`). Esto se hace ya que `dict_list_periodo_interes` únicamente cubre el año de interes (`n_year_interes`)
3.  La función regresa una lista de *n* imágenes
4.  Crear `ee.ImageCollection` de 30 $\times$ *n* imágenes. Se usa `flatten()` para dejar de tener una lista de 30 elementos, donde cada elemento es una lista de *n* elementos

Con la colección de 30 $\times$ *n* imágenes, lo que queda es agrupar por los periodos y calcular el promedio de la precipitación de ese periodo.

Para este proceso tambien se crea un diccionario especial para la reducción, similar a los anteriores que se han creado. También un diccionario de nombre de las bandas, solo que sin el condicional `if`

------------------------------------------------------------------------

## Métricas a extraer

El objetivo es poder extraer información sobre las lluvias de cada año, a las que se les prestará atención son:

- Precipitación en milímetros (mm)
- Anomalía de la precipitación en porcentaje (%) con respecto de la normal
- Anomalía de la precipitación en milímetros (mm) con respecto de la normal

### Precipitación en milímetros

Para la Precipitación en milímetros no hace falta hacer algun cálculo.

``` python
img_periodo_interes_pr
```

------------------------------------------------------------------------

### Anomalía en milimetros

> \[!WARNING\]
>
> Las secciones **Acumulación normal**, **Métricas a extraer: Anomalía en milimetros**, **Métricas a extraer: Anomalía en porcentaje**, así como cualquier operación relacionada al cálculo de la normal y de las anomalías, quedan temporalmente en pausa hasta que se encuentre una manera de mejorar su extracción semananal, mensual y anual.
>
> Esta decisión se debe al error de tiempo de ejecución en los servidores de Google Earth Engine.
>
> En lo que se encuentra la solución los valores de las anomalías serán el resultado de CSV exportados de la acumulación de la precipitación (semanal, mensual o anual)

Es la diferencia en milimetros, de la precipitación de un determinado mes $\left( \overline{x}_{i} \right)$ y el promedio histórico o la normal $\left( \mu_{\text{normal}} \right)$ de ese mes

$$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$

1.  Restar el promedio histórico
2.  Copiar todas las propiedades en la nueva imagen

### Anomalía en porcentaje

> \[!WARNING\]
>
> Las secciones **Acumulación normal**, **Métricas a extraer: Anomalía en milimetros**, **Métricas a extraer: Anomalía en porcentaje**, así como cualquier operación relacionada al cálculo de la normal y de las anomalías, quedan temporalmente en pausa hasta que se encuentre una manera de mejorar su extracción semananal, mensual y anual.
>
> Esta decisión se debe al error de tiempo de ejecución en los servidores de Google Earth Engine.
>
> En lo que se encuentra la solución los valores de las anomalías serán el resultado de CSV exportados de la acumulación de la precipitación (semanal, mensual o anual)

Es el resultado de dividir la diferencia de la precipitación de un determinado mes $\left( \overline{x}_{i} \right)$ y el promedio histórico o la normal $\left( \mu_{\text{normal}} \right)$ entre la normal de ese mismo mes.

$$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$

1.  Restar el promedio histórico
2.  Dividir entre el promedio histórico
3.  Copiar todas las propiedades en la nueva imagen

------------------------------------------------------------------------

## De raster a CSV

### Información de `ee.Image` a `ee.FeatureCollection`

Para poder exportar la información como una tabla de CSV, primero se tiene que almacenar o reducir la información a las geometrias de las regiones del país (sean entidades, municipios o cualquier otro tipo de división).

``` python
select_fc_interes = "ent"
dict_fc = dict(
    ent = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_ENT_2022",
    mun = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_MUN_2022")
fc_interes = ee.FeatureCollection(dict_fc[select_fc_interes])
```

El proceso de transformación se hará con las imágenes de todas las métricas.

``` python
# ~ Precipitación en milímetros (mm) ~ #
img2fc_periodo_interes_pr = (img_periodo_interes_pr
  .reduceRegions(
      collection = fc_interes,
      reducer = ee.Reducer.mean(),
      scale = 5566)
  .map(lambda feature: (ee.Feature(feature)
                        .set({'n_year': n_year_interes})
                        .setGeometry(None))))

# Nota: No se por qué hago esto, pero solo así funciona el código.
#       [Inserte meme de Bibi diciendo "Pues sucedió wey"]
fc_periodo_interes_pr = ee.FeatureCollection(
  (img2fc_periodo_interes_pr
   .toList(3000)
   .flatten()))
```

Líneas 3-6  
Se crea una `ee.FeatureCollection` a partir de la información de la imagen de *n* bandas. La información que se extraerá será de las geometrías de interés. Se extraerá el promedio de la región. La escala de la extracción es la misma que la resolución de CHIRPS, 5,566 m (se puede encontrar en la página de información de CHIRPS)

Líneas 7-9  
Cuando se crea la nueva `ee.FeatureCollection`, se itera por cada `ee.Feature` para poder asignar la propiedad (columna) del año de la información. Las *n* bandas se transforman en tambien en columnas, entonces se tiene la información mensual. Finalmente se elimina la geometría asignada porque de esta manera la exportación es más fácil y no demora mucho.

Línea 13  
Se crea una `ee.FeatureCollection` a partir de una lista de *features*

Líneas 14-15  
Transformar la `ee.Feature` a una lista de máximo 3000 elementos

Línea 16  
Se eliminan sublistas (de existir).

### Exportar `ee.FeatureCollection` a CSV

Dentro del editor de código de Earth Engine existe la función para exportar una tabla, pero para el caso de la API de Python se usa la librería de [**`geemap`**](https://geemap.org/) a través de la función **`ee_export_vector_to_drive`**.

``` python
from geemap import ee_export_vector_to_drive
```

Al momento de exportar las `ee.FeatureCollection`, se tiene que hacer con una descripción de la tarea, así como el nombre del archivo.

La descripción es obligatoria pero el nombre del archivo no, por lo que con solo la descripción es más que suficiente (el nombre del archivo toma el nombre de la descripción).

``` python
# ~ Precipitación en milímetros (mm) ~ #
description_task_pr = f"pr_{select_fc_interes}_{periodo_interes}_{n_year_interes}"

ee_export_vector_to_drive(
  collection= fc_periodo_interes_pr,
  description= description_task_pr,
  fileFormat= "CSV",
  folder= "pruebas_ee")
```
