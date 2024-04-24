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
#     fontsize: 12pt
#     mainfont: Charter
#     geometry:
#       - top=0.6in
#       - bottom=0.6in
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
fecha actual^[Esto quiere decir, que si la fecha _actual_ es Marzo 2024, 
entonces los datos cubren hasta Abril 2024]

El procesamiento de texto es similar al realizado en el proyecto 
["Desplazamiento climático: La migración que no 
vemos"](https://github.com/nmasfocusdatos/desplazamiento-climatico).

"""

# %%
import ee # <1>
import geemap # <2>

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
|`date_base_start`|Constante|Inicio del periodo de 30 años de base: **`"1981-01-01"`**|
|`date_base_end`|Constante|Fin del periodo de 30 años de base: **`"2010-12-31"`**|
|`scale_img_coll`|Constante|Escala de la `ee.ImageCollection`. Para [CHIRPS Daily](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY#bands) es de 5,566 m|
|`geom_mex`|Constante|Geometría del perímetro de México, usada para delimitar espacialmente la información|
|`fc`|Cambiante|`ee.FeatureCollection` de las geomtrías e información de los Estados o Municipios de México|
|`chirps`|Constante|`ee.ImageCollection` de [CHIRPS Daily](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY)|

: Variables y constantes {#tbl-vars-const-notes}

"""

# %% 
date_base_start = "1981-01-01" # <1>
date_base_end = "2010-12-31" # <2>
scale_img_coll = 5566 # <3>

geom_mex = (ee.FeatureCollection("USDOS/LSIB/2017") # <4>
  .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")) # <5>
  .first() # <6>
  .geometry()) # <7>

path_fc = "'projects/ee-unisaacarroyov/assets/GEOM-MX/MX_ENT_2022'" # <8>
fc = ee.FeatureCollection(path_fc) # <8>

chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY') # <9>
  .select("precipitation") # <9>
  .filter(ee.Filter.bounds(geom_mex))) 


# %% [markdown]
"""
1. Inicio de periodo _base/histórico/normal_
2. Fin de periodo _base/histórico/normal_
3. Escala del raster CHIRPS Daily
4. `ee.FeatureCollection` de división politica de los países del mundo
5. Filtro donde la propiedad `COUNTRY_NA` sea igual a **Mexico**
6. Selección de la primera `ee.Feature`
7. Extracción de únicamente la geometría
8. `ee.FeatureCollection` de las divisiones de los estados o municipios 
de México
9. `ee.ImageCollection` de CHIRPS Daily
"""

# %% [markdown]
"""
# Modificiación de la `ee.ImageCollection`

La manera en la que se organiza `chirps` es tener la colección de más de 
15,700 imágenes de una sola banda de información (la precipitación del día).

Lo que se busca hacer es tener una colección de poco más de 40 imágenes con 
52 bandas, estas bandas son las semanas del año y la información de cada 
banda será la misma: la precipitación semanal.

## Etiquetado de año y semana del año

Para ir agrupando y sumando la precipitación semanal, hay que tener 
etiquetadas con el año y semana del año para poder agruparlas y sumar 
la precipitación. Para ello se crea una función que haga ese etiquetado en 
cada una de las imágenes
"""

# %% 
def func_tag_year_week(img): # <1>
  full_date = ee.Date(ee.Number(img.get("system:time_start"))) # <2>
  n_year = ee.Number(full_date.get("year")) # <3>
  n_week = ee.Number(full_date.get("week")) # <4>
  return img.set({"n_week": n_week, "n_year": n_year}) # <5>

chirps_year_week = chirps.map(func_tag_year_week) # <6>

# %% [markdown]
"""
1. La función toma una sola `ee.Image`
2. Obtener la fecha de la imagen, como esta en formato UNIX, se tiene que 
transformar a fecha con `ee.Date`
3. De la fecha se obtiene el valor numérico del año
4. De la fecha se obtiene el valor numérico de la semana del año
5. Asignación de año y semana del año como propiedades de la `ee.Image`
6. Crear nueva `ee.ImageCollection` con el etiquetado
"""

# %% [markdown]
"""
## Agrupar años y semanas

Antes de crear la colección de $\approx$ 40 imágenes con 52 bandas cada 
una, hay que reducir la colección de 365 imagenes por año a 52 imágenes 
por año, donde cada imagen tenga la precipitación de la semana.
"""

# %%

# TODO: Crear ee.ImageCollection de ~ 42 imagenes de a 52 bandas (semanas)
# TODO: Comentar codigo

list_of_img_coll_year_week = ee.List([])

for number_year in range(1981, 2024):
    # Filtrar por año
    # (tiene 365~366 imagenes)
    img_coll_number_year = chirps_year_week.filter(
        ee.Filter.eq("n_year", ee.Number(number_year)))
    
    # Filtrar reducir por semanas
    # Lista de 52 imagenes imagenes
    list_of_weeks = ee.List.sequence(1, 52).map(
        lambda number_week: (img_coll_number_year
            .filter(ee.Filter.eq("n_week", number_week))
            .sum()
            .set({"n_week": number_week, "n_year": ee.Number(number_year)}))
        )
    
    # Crear image collection de 52 imagenes por año
    img_coll_reduced = ee.ImageCollection.fromImages(list_of_weeks)
    print(img_coll_reduced.size().getInfo())   


# %% [markdown]
"""

# Procesamiento 3

Aliquam fermentum est dapibus convallis aliquam. Praesent tincidunt 
sagittis finibus. Proin bibendum at felis nec blandit. Sed sapien ipsum, 
luctus et nisl et, eleifend tristique urna. Nam quis diam non orci 
hendrerit cursus. Pellentesque venenatis nunc lectus, a sagittis magna 
condimentum eu. Nullam semper elit at sollicitudin rhoncus. Donec cursus 
mi sapien, id dapibus lorem convallis id. Nulla ut arcu eu mauris malesuada 
aliquet et et purus. Nullam bibendum fringilla cursus. Nulla congue 
ligula et consequat pellentesque. Donec id turpis lectus. Vestibulum quam 
nunc, rhoncus non mi ac, placerat interdum eros.
"""

# %% 
# Espacio

# %% [markdown]
"""
# Procesamiento 4

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %% 
# Espacio