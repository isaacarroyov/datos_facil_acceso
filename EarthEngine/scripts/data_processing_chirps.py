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
# TODO: COMENTAR 01
def func_iter_years(n_year):
    img_coll_year_interes = (chirps_tagged
                             .filter(ee.Filter.eq("n_year", n_year)))
    def func_iter_years_iter_months(n_month):
        return (img_coll_year_interes
                .filter(ee.Filter.eq("n_month", n_month))
                .sum()
                .set({"n_year": n_year, "n_month": n_month}))
    
    list_monthly_pr_per_year = list_months.map(func_iter_years_iter_months)

    return list_monthly_pr_per_year

list_year_monthly_pr = (list_years
                        .map(func_iter_years)
                        .flatten())

img_coll_year_monthly_pr = (ee.ImageCollection
                            .fromImages(list_year_monthly_pr))

# %% [markdown]
"""

## Meses como bandas de imágenes

Ya que se logró pasar de más de 15 mil imágenes a poco más de 500, ya es 
tiempo de reducir a $\approx$ 40 imágenes de a 12 bandas cada una.
"""

# %%
# TODO: COMENTAR 02
def imgcoll2bands(n_year):
    img_12bands = (img_coll_year_monthly_pr
        .filter(ee.Filter.eq("n_year", n_year))
        .toBands()
        .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)])
        .set({"n_year": n_year}))
    return img_12bands

img_coll_year_monthly_pr_bands = (ee.ImageCollection
    .fromImages(list_years.map(imgcoll2bands)))

# %% [markdown]
"""
# Cálculo de anomalías de precipitación

## Acumulación normal

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
#TODO: COMENTAR 03
base_period = (img_coll_year_monthly_pr
               .filter(ee.Filter.lte("n_year", 2010)))
base_pr_monthly_accumulation = (ee.ImageCollection
    .fromImages(
        (list_months
         .map(lambda n_month: (base_period
                               .filter(ee.Filter.eq("n_month", n_month))
                               .mean()
                               .set("n_month", n_month)))))
    .toBands()
    .rename([f"0{i}" if i < 10 else str(i) for i in range(1,13)]))
# %% [markdown]
"""

## Anomalía en milimetros 

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc dictum 
turpis ullamcorper pharetra pretium. Vivamus eu pellentesque nibh. Mauris 
ac massa faucibus, condimentum eros at, vehicula justo. Cras ultrices 
gravida risus, quis tempor tortor hendrerit quis. Aliquam erat volutpat. 
Nullam tincidunt iaculis varius. Donec tristique leo non sapien sagittis, 
in tincidunt lorem bibendum. Integer commodo sem vel risus hendrerit 
efficitur. Pellentesque ut tincidunt ante, finibus sodales tellus.

Aliquam ornare felis elit, ut euismod erat eleifend ac. Donec eget nisl 
ligula. Vestibulum sit amet ultricies augue. Vivamus ac sem vitae libero 
porttitor semper et quis lacus. Aenean ut arcu ipsum. Suspendisse 
facilisis nisl ac sodales semper. Aliquam interdum convallis accumsan. 
Vestibulum consequat tortor eget dapibus feugiat. Duis vitae mi est. Sed 
laoreet eleifend sem. Integer dignissim, purus nec condimentum pharetra, 
sapien nunc rhoncus nulla, eu porttitor lorem ipsum a massa. Etiam dapibus 
sodales erat eu viverra.
"""

# %% 
#TODO: COMENTAR 04
#TODO: Escribir la formula
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

Curabitur lacus dui, vehicula ut ex non, suscipit rutrum purus. Sed 
dignissim mattis tortor, eget euismod risus egestas id. Nam vel orci a 
nisl tincidunt commodo. Maecenas sagittis nibh et purus tincidunt 
faucibus. In eu sagittis nisl. Duis nec feugiat dui, sit amet hendrerit 
urna. Etiam in varius lorem. Etiam eu mauris non nunc imperdiet blandit 
et feugiat dui. In consequat dui ut sapien molestie, sed venenatis libero 
rutrum. Sed venenatis vulputate felis, ac tempor nunc luctus a. Ut ut 
ipsum congue, fermentum mi non, tristique justo. Quisque id pretium quam. 
Fusce eget eleifend metus. Aenean eget purus porta, dignissim nunc et, 
feugiat mauris. Aliquam eget quam et odio scelerisque finibus vestibulum 
non ligula. Maecenas sit amet velit pellentesque, cursus dolor at, 
vulputate tellus.
"""

# %% 
#TODO: COMENTAR 05
#TODO: Escribir la formula

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

#TODO: Falta crear codigo para guardar 



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

#TODO: Falta crear codigo para guardar  


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

list_fc_pr = func_create_list_of_fc(
    imgcoll= img_coll_year_monthly_anomaly_prop,
    featurecoll= fc)


#TODO: Falta crear codigo para guardar  