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
extracción mensual^[Con posibilidad de que adaptar el código para que el 
periodo sea semanal] de variables derivadas de la precipitación, tales 
como: precipitación mensual promedio, anomalía de la precipitación en 
porcentaje con respecto de la normal y anomalía de la precipitación en 
milímetros con respecto de la normal.


Cada aspecto del código se documenta en diferentes capítulos.

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
|`geom_mex`|Constante|Geometría del perímetro de México, usada para delimitar espacialmente la información|
|`fc`|Cambiante|`ee.FeatureCollection` de las geomtrías e información de los Estados o Municipios de México|
|`chirps`|Constante|`ee.ImageCollection` de [CHIRPS Daily](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY)|

: Variables y constantes {#tbl-vars-const-notes}

"""

# %% 
select_fc = "ent" # <1>
dict_fc = dict( # <2>
    ent = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_ENT_2022", # <2>
    mun = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_MUN_2022") # <2>

fc = ee.FeatureCollection(dict_fc[select_fc]) # <3>

geom_mex = (ee.FeatureCollection("USDOS/LSIB/2017") # <4>
            .filter(ee.Filter.eq("COUNTRY_NA", "Mexico")) # <5>
            .first() # <6>
            .geometry()) # <7>


chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY') # <8>
          .select("precipitation") # <8>
          .filter(ee.Filter.bounds(geom_mex))) # <9>


# %% [markdown]
"""
1. Seleccion de `ee.FeatureCollection`, sea de Entidades (`ent`), 
Municipios (`mun`) o Cuencas Hidrológicas (`ch`)
2. Diccionario con los _paths_ hacia la `ee.FeatureCollection` de elección
3. Carga de `ee.FeatureCollection` de interés
4. `ee.FeatureCollection` de división politica de los países del mundo
5. Filtro donde la propiedad `COUNTRY_NA` sea igual a **Mexico**
6. Selección de la primera `ee.Feature`
7. Extracción de únicamente la geometría
8. `ee.ImageCollection` de CHIRPS Daily
9. Limitar el raster a la geometría de México
"""

# %% [markdown]
"""
# Modificiación de la `ee.ImageCollection`

`chirps` es una `ee.ImageCollection` de más de 15 mil 
imágenes (`ee.Image`). Lo que se busca hacer es tener una colección de 
poco más de 40 imágenes con 12 bandas, estas bandas son los meses del año 
y la información de cada banda será la misma: la precipitación mensual.

## Etiquetado de año y mes del año

Para ir agrupando y sumando la precipitación mensual, hay que tener las 
imágenes etiquetadas con el año y mes para poder agruparlas y sumar 
la precipitación. Para ello se crea una función que haga ese etiquetado en 
cada una de las imágenes
"""

# %% 
def func_tag_year_month(img): # <1>
    full_date = ee.Date(ee.Number(img.get("system:time_start"))) # <2>
    n_year = ee.Number(full_date.get("year")) # <3>
    n_month = ee.Number(full_date.get("month")) # <4>
    return img.set({"n_month": n_month, "n_year": n_year}) # <5>

chirps_tagged = chirps.map(func_tag_year_month) # <6>

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
## Precipitación mensual (1981-2023)

Antes de crear la colección de $\approx$ 43 imágenes con 12 bandas cada 
una, hay que reducir la colección de 365 imagenes por año a 12 imágenes 
por año, donde cada imagen tenga la precipitación del mes.
"""

# %%
list_months = ee.List.sequence(1, 12)
list_years = ee.List.sequence(1981, 2023)

# %% [markdown]

"""
La transformación conlleva múltiples iteraciones, y mientras que en 
JavaScript se puedan declarar funciones dentro de **`map`**, para el 
caso se Python se tendran que crear las funciones a parte, y después serán 
llamadas a su respectivo `map`.
"""

# %%
def func_iter_years(n_year): # <1>
    img_coll_year_interes = (chirps_tagged
                             .filter(ee.Filter.eq("n_year", n_year))) # <2>
    def func_iter_years_iter_months(n_month): # <3>
        return (img_coll_year_interes # <4>
                .filter(ee.Filter.eq("n_month", n_month)) # <4>
                .sum() # <4>
                .set({"n_year": n_year, "n_month": n_month})) # <5>
    
    list_monthly_pr_per_year = (list_months # <6>
                                .map(func_iter_years_iter_months)) # <6>

    return list_monthly_pr_per_year # <7>

# %% [markdown]
"""
1. Función que itera sobre elementos de una `ee.List`, estos elementos 
son los los años que ocupa la `ee.ImageCollection`
2. Se filtra el año de interes 
3. Función para iterar sobre elementos de una `ee.List`, estos elementos 
son los los meses que ocupa la `ee.ImageCollection`
4. Por cada año y cada mes (de ese año), se va a retornar (de función 
anidada) se va a regresar una `ee.Image`, que es resultado de reducir 
la `ee.ImageCollection` que cumple con las condiciones del año-mes. El 
reductor principal es la suma.
5. La nueva imagen tiene como propiedades el año y el mes que representa.
6. Se aplica la función que itera sobre meses, a la lista de meses del año.
7. El resultado final de la función _general_, es que por cada elemento 
(año) hay una lista de 12 imagenes, que representan 
la precipitación mensual de ese elemento.
"""

# %%
list_year_monthly_pr = (list_years # <1>
                        .map(func_iter_years) # <1>
                        .flatten()) # <2>

img_coll_year_monthly_pr = (ee.ImageCollection # <3>
                            .fromImages(list_year_monthly_pr)) # <3>

# %% [markdown]
"""
1. Se aplica la función para reducir el número de imagenes en la colección
2. Como el resultado es una lista de (poco más de 40) listas 
(de 12 imágenes), entonces se tiene que _aplanar_ es decir, sacar los 
elementos de cada sublista y que sean parte de la lista completa/general
3. Se crea una colección de imágenes a partir de una lista de imágenes

## Meses como bandas de imágenes

Ya que se logró pasar de más de 15 mil imágenes a poco más de 500, ya es 
tiempo de reducir a $\approx$ 40 imágenes de a 12 bandas cada una.
"""

# %%
def imgcoll2bands(n_year): # <1>
    img_12bands = (img_coll_year_monthly_pr # <2>
        .filter(ee.Filter.eq("n_year", n_year)) # <2>
        .toBands() # <3>
        .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)]) # <4>
        .set({"n_year": n_year})) # <5>
    return img_12bands # <6>

img_coll_year_monthly_pr_bands = (ee.ImageCollection # <7>
    .fromImages(list_years.map(imgcoll2bands)))

# %% [markdown]
"""
1. Función para transformar una `ee.ImageCollection` de _**n**_ imágenes 
a una `ee.Image` de _**n**_ bandas
2. Filtrar por año de interés
3. Transformar a una imagen con el número de bandas igual al número de 
imagenes que tenía la colección.
5. Agregar a la imagen, la propiedad del año al que pertenece.
6. Se regresa una imagen de 12 bandas (si es el año esta completo)
7. Aplicar la función a una lista de años.

# Cálculo de anomalías de precipitación

## Acumulación normal

De acuerdo a con el [glosario de la NOAA](https://forecast.weather.gov/glossary.php?word=ANOMALY#:~:text=NOAA's%20National%20Weather%20Service%20%2D%20Glossary,water%20level%20minus%20the%20prediction.) 
una anomalía es la desviación de una unidad dentro de un periodo en una 
región en específico con respecto a su promedio histórico o normal. Este 
promedio es usualmente de 30 años.

Para el caso del CHIRPS, es de 1981 hasta el 2010 (incluyendo a diciembre)
"""

# %% 
base_period = (img_coll_year_monthly_pr
               .filter(ee.Filter.lte("n_year", 2010))) # <1>
base_pr_monthly_accumulation = (ee.ImageCollection
    .fromImages(
        (list_months # <2>
         .map(lambda n_month: (base_period # <3>
                               .filter(ee.Filter.eq("n_month", n_month)) # <3>
                               .mean() # <4>
                               .set("n_month", n_month))))) # <5>
    .toBands() # <6>
    .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)])) # <7>
# %% [markdown]
"""
1. De la colección cuyas imagenes son de 12 bandas, se filtran aquellas 
que sean del 2010 _para abajo_
2. Ir por meses 
3. Filtrar al mes del interes
4. Calcular el promedio de la precipitación de esos 30 años
5. A esa imagen darle la propiedad del valor del mes
6. Como el resultado es una colección de 12 imágenes, se cambia a una 
imagen de 12 bandas
7. Renombrar las bandas (meses) con el número del mes del año

## Anomalía en milimetros 

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc dictum 
turpis ullamcorper pharetra pretium. Vivamus eu pellentesque nibh. Mauris 
ac massa faucibus, condimentum eros at, vehicula justo. Cras ultrices 
gravida risus, quis tempor tortor hendrerit quis. Aliquam erat volutpat. 
Nullam tincidunt iaculis varius. Donec tristique leo non sapien sagittis, 
in tincidunt lorem bibendum. Integer commodo sem vel risus hendrerit 
efficitur. Pellentesque ut tincidunt ante, finibus sodales tellus.

$$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$
"""

# %% 
#TODO: COMENTAR 04
img_coll_year_monthly_anomaly_mm = (img_coll_year_monthly_pr_bands
    .map(lambda img: (img
                      .subtract(base_pr_monthly_accumulation)
                      .copyProperties(img, img.propertyNames()))))

# %% [markdown]
"""
## Anomalía en porcentaje

Mauris porta lorem nisi, et mollis ligula eleifend sed. Donec tristique 
sed orci quis cursus. Pellentesque vulputate vel turpis eget maximus. 
Cras et rutrum neque, et accumsan felis. Nam vel leo scelerisque, pharetra 
quam feugiat, fermentum leo. Nullam consequat turpis non eros fermentum 
suscipit. Suspendisse sed dui nec tellus vulputate volutpat at nec tortor. 
Etiam tempus ut sapien non condimentum.

$$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$

"""

# %% 
#TODO: COMENTAR 05
img_coll_year_monthly_anomaly_prop = (img_coll_year_monthly_pr_bands
    .map(lambda img: (img
                      .subtract(base_pr_monthly_accumulation)
                      .divide(base_pr_monthly_accumulation)
                      .copyProperties(img, img.propertyNames()))))

# %% [markdown]
"""
# Guardar en tablas por años

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %% 
#TODO: COMENTAR 06
def func_create_list_of_fc(imgcoll, featurecoll, scale_img_coll = 5566):
    list_fc = list()
    
    for n_year_interes in range(1981, 2024):
        img_year_month = (imgcoll
                         .filter(ee.Filter.eq("n_year", n_year_interes))
                         .first())

        fc_from_image = (img_year_month
                        .reduceRegions(
                            reducer = ee.Reducer.mean(),
                            collection = featurecoll,
                            scale = scale_img_coll)
                        .map(lambda feature: (ee.Feature(feature)
                                            .set({'n_year': n_year_interes})
                                            .setGeometry(None))))

        fc_final = ee.FeatureCollection((fc_from_image
                                         .toList(3000)
                                         .flatten()))
        list_fc.append(fc_final)

    return list_fc

def save_all_years_fc(
        list_of_fc,
        descrp,
        filename,
        folder_name,
        fc_type= select_fc):
    
    iteracion = 0
    
    for vector in list_of_fc:
        print(f"Mandando a guardar la tabla de {1981 + iteracion}")
        print(f"Bajo el asunto {descrp}")
        final_filename = f"{filename}_{fc_type}_{1981 + iteracion}"
        final_descrp = f"{descrp}_{fc_type}_{1981 + iteracion}"
        geemap.ee_export_vector_to_drive(
            collection= vector,
            description= final_descrp,
            fileNamePrefix= final_filename,
            fileFormat= "CSV",
            folder= folder_name)
        print(f"El nombre del archivo es {final_filename}.csv")
        iteracion += 1

        time.sleep(120)
    
    return None
# %% [markdown]
"""
## Acumulación de lluvias

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

# %% 
#TODO: COMENTAR 07
list_fc_pr = func_create_list_of_fc(
    imgcoll= img_coll_year_monthly_pr_bands,
    featurecoll= fc)

# %% [markdown]
"""
El siguiente bloque de código es el que se usa para guardar la información 
del periodo 1981 - 2023. Las solicitudes son enviadas al servidor y el 
archivo CSV se guardará en la carpeta de Google Drive cuando el 
servidor haya terminado de ejecutar la solicitud.

```
save_all_years_fc(
    list_of_fc= list_fc_pr,
    descrp= "chirps_daily_precipitation",
    filename= "chirps_daily_pr",
    folder_name= "gee_chirps_daily_pr"
)
```
"""

# %% [markdown]
"""
## Anomalía de lluvias

### Anomalía en milimetros

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

# %% 
#TODO: COMENTAR 07

list_fc_anomaly_pr_mm = func_create_list_of_fc(
    imgcoll= img_coll_year_monthly_anomaly_mm,
    featurecoll= fc)

# %% [markdown]
"""
### Anomalía en porcentaje

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

# %% 
#TODO: COMENTAR 08

list_fc_anomaly_pr_prop = func_create_list_of_fc(
    imgcoll= img_coll_year_monthly_anomaly_prop,
    featurecoll= fc)

# %% [markdown]
"""
El siguiente bloque de código es el que se usa para guardar la información 
del periodo 1981 - 2023. Las solicitudes son enviadas al servidor y el 
archivo CSV se guardará en la carpeta de Google Drive cuando el 
servidor haya terminado de ejecutar la solicitud.


```Python
save_all_years_fc(
    list_of_fc= list_fc_anomaly_pr_prop,
    descrp= "chirps_daily_precipitation_anomaly_prop",
    filename= "chirps_daily_anomaly_pr_prop",
    folder_name= "gee_chirps_daily_anomaly_pr_prop"
)
```
"""

# %% [markdown]
"""
# Caso específico: 2024

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %%
#TODO: explicar por qué es el caso especifo
#TODO: Traducir JavaScript a Python

# %% [markdown]
"""
```JavaScript
/* *  Crear ee.Image de 12 bandas cada una * */
/*
list_year_month = list_months
                .map(function(number){
                return chirps_tagged
                        .filter(ee.Filter.eq("n_year", n_year_interes))
                        .filter(ee.Filter.eq("n_month", number))
                        .sum()
                        .set({"n_month": number});
                });
img_year_month = ee.ImageCollection
                .fromImages(list_year_month)
                .toBands()
                //.rename(["01","02","03"])
                ;
*/

/* * Crear ee.FeatureCollection de 12 columnas y n_estados/municipios * */

// Limitar a un anño en especifico 
n_year_interes = 2020;
img_year_month = img_coll_year_monthly_pr_bands
                .filter(ee.Filter.eq("n_year", n_year_interes))
                .first();

fc_from_image = img_year_month
                .reduceRegions({
                    'reducer': ee.Reducer.mean(),
                    'collection': fc,
                    'scale': scale_img_coll})
                .map(function(feature){
                    return ee.Feature(feature)
                            .set({'n_year': n_year_interes})
                            .setGeometry(null)});

fc_final = ee.FeatureCollection(fc_from_image.toList(3000).flatten());
```
"""
# %%
#TODO: explicar por qué es el caso especifo
#TODO: Traducir JavaScript a Python

# %% [markdown]
"""
## Acumulación de la precipitación

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %%
#TODO: explicar por qué es el caso especifo
#TODO: Traducir JavaScript a Python


# %% [markdown]
"""
## Anomalía de la precipitación

### Anomalía en milimetros

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %%
#TODO: explicar por qué es el caso especifo
#TODO: Traducir JavaScript a Python

# %% [markdown]
"""
### Anomalía en porcentaje

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %%
#TODO: explicar por qué es el caso especifo
#TODO: Traducir JavaScript a Python


# %% [markdown]
"""
## Guardar información actualizada

Nullam accumsan dolor a justo dapibus, sit amet interdum metus rhoncus. 
Praesent ac libero hendrerit, dapibus metus ac, dignissim tellus. Nunc ut 
enim ut ligula posuere eleifend. Vestibulum ac lorem in massa lacinia 
condimentum sed eget ligula. Maecenas imperdiet felis sit amet arcu 
viverra tristique. Maecenas suscipit mattis massa, ut malesuada erat 
consequat tristique. Nulla tincidunt augue vel ante aliquam, in ultricies 
purus laoreet.
"""

# %%
#TODO: explicar por qué es el caso especifo
#TODO: Traducir JavaScript a Python
