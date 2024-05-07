# %% [markdown]
# ---
# title: Extracción y procesamiento de datos de lluvia
# subtitle: CHIRPS Daily via Google Earth Engine
# author: Isaac Arroyo
# date-format: long
# date: last-modified
# lang: es
# jupyter: python3
# format:
#   pdf:
#     toc: true
#     fontsize: 12pt
#     mainfont: Georgia
#     geometry:
#       - top=1in
#       - bottom=1in
#       - left=1in
#       - right=1in
#     documentclass: report
#     number-sections: true
#     papersize: letter
#     fig-width: 5
#     fig-asp: 0.75
#     fig-dpi: 300
#     code-annotations: below
#     code-line-numbers: true
# 
# execute:
#   echo: true
#   eval: false
#   warning: false
# ---

# %% [markdown]
"""
# Introducción

En este documento se encuentran documentados los pasos y el código para la 
extracción mensual de variables derivadas de la precipitación, tales 
como: precipitación mensual promedio, anomalía de la precipitación en 
porcentaje con respecto de la normal y anomalía de la precipitación en 
milímetros con respecto de la normal.

Cada aspecto del código se documenta en diferentes capítulos, donde el 
último capítulo estará la función final, con la que se resume y concluye 
el proceso de extracción.

# Sobre los datos

Los fuente de los datos se llama **CHIRPS (Climate Hazards Group InfraRed 
Precipitation With Station Data) Daily**, se puede encontrar en diferentes 
lugares, uno de estos la plataforma **Google Earth Engine**.

De acuerdo con la descripción:

> _Climate Hazards Group InfraRed Precipitation with Station data (CHIRPS) 
is a 30+ year quasi-global rainfall dataset. CHIRPS incorporates 0.05° 
resolution satellite imagery with in-situ station data to create gridded 
rainfall time series for trend analysis and seasonal drought monitoring._


Estos datos cuentan con la **precipitación diaria** medida en milímetros 
(mm) desde Enero 01, de 1981 hasta el mes inmediato anterior a la 
fecha actual^[Esto quiere decir, que si la fecha _actual_ es Abril 2024, 
entonces los datos cubren hasta Marzo 2024]

El procesamiento de texto es similar al realizado en el proyecto 
["Desplazamiento climático: La migración que no 
vemos"](https://github.com/nmasfocusdatos/desplazamiento-climatico).

"""

# %%
import ee # <1>
import geemap # <2>
import time

try:
    ee.Initialize() # <3>
    print("Se ha inicializado correctamente")
except:
    print("Error en la inicialización")

# %% [markdown]
"""
1. Importar API de (Google) Earth Engine
2. Importar `geemap` para la creación de mapas interactivos tipo folium 
3. Inicializar API
"""

# %% [markdown]
"""
# Varibles y constantes

La extracción de datos se planea que sea periódica a niveles estatales y 
municipales, por lo que se dejan declarados variables que se mantendrán 
constantes (como el rango del promedio _normal_ o histórico) o (valga la 
redundancia) cambiarán dependiendo de los datos que se quieran. La 
@tbl-vars-const-notes entra a mayor detalle de lo que se esta haciendo

|**Variable**|**Tipo**|**Notas**|
|:---|:---|:---|
|`date_year_interes`|Cambiante|Año del que se van a extraer las métricas de precipitación|
|`fc`|Cambiante|`ee.FeatureCollection` de las geomtrías e información de los Estados o Municipios de México|
|`chirps`|Constante|`ee.ImageCollection` de [CHIRPS Daily](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY)|
|`year_base_inicio`|Constante|Inicio del periodo historico para el cálculo de la normal, Enero 01 de 1981|
|`year_base_fin`|Constante|Fin del periodo historico para el cálculo de la normal, Diciembre 31 de 2010|
|`geom_mex`|Constante|Geometría del perímetro de México, usada para delimitar espacialmente la información|

: Variables y constantes {#tbl-vars-const-notes}

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
            .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")) # <7>
            .first() # <8>
            .geometry()) # <9>

chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY') # <10>
          .select("precipitation") # <10>
          .filter(ee.Filter.bounds(geom_mex))) # <11>


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
6. `ee.FeatureCollection` de división politica de los países del mundo
7. Filtro donde la propiedad `COUNTRY_NA` sea igual a **Mexico**
8. Selección de la primera `ee.Feature`
9. Extracción de únicamente la geometría
10. `ee.ImageCollection` de CHIRPS Daily
11. Limitar el raster a la geometría de México
"""

# %% [markdown]
"""
# Reducción a valores mensuales

`chirps` es una `ee.ImageCollection` de más de 15 mil 
imágenes (`ee.Image`). El procesamiento y tratado de las imagenes es 
_pesado_, y aunque la computadora no se encargue de hacer el trabajo, 
esto puede hacer que el servidor de Google Earth demore en hacer los 
cálculos y la transformación de los datos raster.

Es por eso que en el procesamiento se incluye un primer filtro: la 
creación de una `ee.ImageCollection` de 365 
imágenes^[366 si es año bisiesto].
"""

# %%
chirps_year_interes = (chirps
    .filter(ee.Filter.calendarRange(start = date_year_interes,
                                    field = "year")))
# %% [markdown]
"""
## Etiquetado de año y mes del año

Para ir agrupando y sumando la precipitación mensual, hay que tener las 
imágenes etiquetadas con el mes para poder agruparlas y sumar 
la precipitación. Para ello se crea una función que haga ese etiquetado en 
cada una de las imágenes
"""

# %% 
def func_tag_month(img): # <1>
    full_date = ee.Date(ee.Number(img.get("system:time_start"))) # <2>
    n_month = ee.Number(full_date.get("month")) # <3>
    return img.set({"n_month": n_month}) # <4>

chirps_year_interes_tagged = chirps_year_interes.map(func_tag_month) # <5>

# %% [markdown]
"""
1. La función toma una sola `ee.Image`
2. Obtener la fecha de la imagen, como esta en formato UNIX, se tiene que 
transformar a fecha con `ee.Date`
3. De la fecha se obtiene el valor numérico de la semana del año
4. Asignación de año y semana del año como propiedades de la `ee.Image`
5. Crear nueva `ee.ImageCollection` con el etiquetado
"""

# %% [markdown]
"""
## Precipitación mensual del año de interés

Para una fácil extracción de los valores del año es necesario tener la 
información de la precipitación (o la métrica de interés) como una 
`ee.Image` de 12 bandas, donde cada banda es el valor mensual de la región.

Para crear una imagen de 12 bandas se necesita primero una 
`ee.ImageColletion` de 12 imágenes.

Para ello, se va a crear una lista de 12 imágenes.
"""

# %%
list_months = ee.List.sequence(1, 12)
# %% [markdown]

"""
La transformación conlleva múltiples iteraciones, y mientras que en 
JavaScript se puedan declarar funciones dentro de **`map`**, para el 
caso se Python se tendran que crear las funciones a parte, y después serán 
llamadas a su respectivo `map`.
"""

# %%
def func_reduce2months(n_month): # <1>
    return (chirps_year_interes_tagged # <2>
            .filter(ee.Filter.eq("n_month", n_month)) # <2>
            .sum() # <3>
            .set({"n_month": n_month})) # <4>
# %% [markdown]
"""
1. Función para sumar todas las imágenes que pertenezcan a un mes en 
específico. Esta función itera sobre elementos de una `ee.List`, estos 
elementos son los los meses que ocupa la `ee.ImageCollection`
2. Se filtran aquellas imágenes que sean del mes de interés
3. Se reduce la colección a una imagen a través de la suma
4. Se le asigna la propiedad del mes que representa.
"""

# %%
list_monthly_pr = (list_months.map(func_reduce2months)) # <1>

img_coll_monthly_pr = (ee.ImageCollection # <2>
                            .fromImages(list_monthly_pr)) # <2>

# %% [markdown]
"""
1. Se aplica la función para reducir el número de imagenes en la 
colección, como resultado da una lista de 12 imágenes
2. Se crea una colección de imágenes a partir de una lista.

## Meses como bandas de una `ee.ImageCollection`

Ya que se logró tener una colección de 12 imágenes, entonces se crea la 
imagen de 12 bandas
"""

# %%
img_monthly_pr = (img_coll_monthly_pr
  .toBands() # <1>
  .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)])) # <2>
# %% [markdown]
"""
1. Pasar `ee.ImageCollection` de _**n**_ imágenes 
a una `ee.Image` de _**n**_ bandas
2. Renombrar el nombre de las bandas a los números de los meses
"""

# %% [markdown]
"""
# Métricas a extraer

El objetivo es poder extraer información mensual sobre las lluvias de 
cada año, a las que se les prestará atención son:

* **Precipitación**
* **Anomalía de precipitación en mm**
* **Anomalía de precipitación en porcentaje**

Para las últimas dos hace falta tener el valor de la **acumulación normal**.

## Acumulación normal

De acuerdo a con el [glosario de la NOAA](https://forecast.weather.gov/glossary.php?word=ANOMALY#:~:text=NOAA's%20National%20Weather%20Service%20%2D%20Glossary,water%20level%20minus%20the%20prediction.) 
una anomalía es la desviación de una unidad dentro de un periodo en una 
región en específico con respecto a su promedio histórico o normal. Este 
promedio es usualmente de 30 años.

Para el caso del CHIRPS, es de 1981 hasta el 2010 (incluyendo a diciembre).

Esta tarea se tiene que hacer con ayuda de dos funciones. La primera 
etiquetará por año y mes la colección _base_. La segunda función tendrá 
que reducir a 12 imagenes cada año del periodo.
"""

# %% 
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
2. Función para crear una lista de listas de precipitaciones mensuales


Con estas dos funciones se creará una colección de imagenes 
de $\approx$ 360 imágenes
"""

# %% 
# TODO: Commentar y explicar
base_period = (chirps
  .filter(ee.Filter.calendarRange(start = year_base_inicio,
                                  end = year_base_fin, field = "year")))

base_period_tagged = base_period.map(func_tag_year_month_base_period)

base_period_tagged_reduced_year_month = (ee.ImageCollection
  .fromImages((ee.List
               .sequence(year_base_inicio, year_base_fin)
               .map(func_reduce2yearmonths_base_period)
               .flatten())))

base_pr_monthly_accumulation = (ee.ImageCollection
  .fromImages(list_months.map(lambda n_month: (
                                    base_period_tagged_reduced_year_month
                                    .filter(ee.Filter.eq("n_month", n_month))
                                    .mean()
                                    .set({"n_month": n_month}))))
  .toBands()
  .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)]))
# %% [markdown]
"""
## Anomalía en milimetros 

Es la diferencia en milimetros, de la precipitación de un determinado 
mes $\left( \overline{x}_{i} \right)$ y el promedio histórico o la normal 
$\left( \mu_{\text{normal}} \right)$ de ese mes

$$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$
"""

# %% 
img_monthly_anomaly_mm = (img_monthly_pr
  .subtract(base_pr_monthly_accumulation) # <1>
  .copyProperties(img_monthly_pr, img_monthly_pr.propertyNames())) # <2>

# %% [markdown]
"""
1. Restar el promedio histórico
2. Copiar todas las propiedades en la nueva imagen

## Anomalía en porcentaje

Es el resultado de dividir la diferencia de la precipitación de un 
determinado mes $\left( \overline{x}_{i} \right)$ y el promedio 
histórico o la normal $\left( \mu_{\text{normal}} \right)$ entre la normal 
de ese mismo mes.

$$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$
"""

# %% 
img_monthly_anomaly_prop = (img_monthly_pr
  .subtract(base_pr_monthly_accumulation) # <1>
  .divide(base_pr_monthly_accumulation) # <2>
  .copyProperties(img_monthly_pr, img_monthly_pr.propertyNames())) # <3>

# %% [markdown]
"""
1. Restar el promedio histórico
2. Dividir entre el promedio histórico
3. Copiar todas las propiedades en la nueva imagen

# Función final

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %% 
# TODO: ACOMODAR A IMAGENES
# %% [markdown]
"""
# Guardar información por años

Vivamus at vestibulum elit. Maecenas in dui at diam aliquet feugiat. In 
justo nisi, cursus vitae augue a, faucibus consectetur felis. Duis nisi 
lorem, scelerisque a libero et, posuere vulputate nibh. Nulla dictum enim 
ac nisi congue egestas. Curabitur volutpat mi nec tristique mattis. Nulla 
sed dictum ante. Nunc vitae erat neque. Morbi rhoncus ex ac tellus 
maximus, nec cursus lorem semper. Donec porta congue placerat. Ut finibus 
est tellus, ut elementum nisl dictum nec. Nulla facilisi. Etiam auctor 
quam ac nunc condimentum mollis. Pellentesque libero mi, finibus sit amet 
fermentum non, condimentum eu dolor. Nam hendrerit ullamcorper nunc, 
tristique facilisis erat sagittis non. Pellentesque fermentum, magna vel 
feugiat pellentesque, odio diam facilisis erat, et ultricies dui erat 
at velit.
"""