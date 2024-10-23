"""
Author: Isaac Arroyo
Notes: La extración y procesamiento de datos es una adaptación y mejora al
       realizado en el proyecto "Desplazamiento climático: La migración que
       no vemos de N+ Focus" (en https://github.com/nmasfocusdatos/desplazamiento-climatico).

       La ejecución de este código se realiza a través de una Jupyter Notebook
       en Google Colab (cuenta propia)


En este script se encuentra el código para la extracción de variables
derivadas de la precipitación tales como:

* Precipitación en milímetros (mm)

En el archivo **`documentacion_raster2csv_chirps.md`** se encuentra la
explicación y documentación de este código.


Cambiantes:
* `n_year_interes`: Año del que se van a extraer las métricas de precipitación
* `fc_interes`: `ee.FeatureCollection` de donde será la información
                - `ent` (Estados)
                - `mun` (Municipios)
* `limit_date`: Fecha del límite próximo de los datos. Esta información se
                puede consultar en la página del la `ee.ImageCollection`
"""

# = = = Imports = = = #
import ee
from datetime import datetime

# Trigger the authentication flow.
ee.Authenticate()

# Initialize the library.
ee.Initialize(project='project-name')

# = = Función de extracción (retorna: vacío) = = #
def get_chirps_metrics(
        n_year_interes,
        limit_date,
        fc_interes):

    # - - Función de etiquetado de fecha - - #
    def func_tag_date(img):
        full_date = ee.Date(ee.Number(img.get("system:time_start")))
        n_year = ee.Number(full_date.get("year"))
        n_month = ee.Number(full_date.get("month"))
        n_week = ee.Number(full_date.get("week"))
        n_day = ee.Number(full_date.get("day"))
        return img.set({"n_year": n_year,
                        "n_month": n_month,
                        "n_week":n_week,
                        "n_day": n_day})

    # - - Carga de CHIRPS - - #
    chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
              .select("precipitation"))

    # - - Enfoque en un solo año - - #
    chirps_year_interes = (chirps
                           .map(func_tag_date)
                           .filter(ee.Filter.eq("n_year", n_year_interes)))

    # - - Reducción a los periodos de interés - - #
    list_week = ee.List.sequence(1, 52)
    list_month = ee.List.sequence(1, 12)
    list_year = ee.List.sequence(n_year_interes, n_year_interes)

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

    # - - Agrupación por semana - - #
    # ~ Lista de 52 ee.Image ~ #
    list_pr_week = list_week.map(
        lambda element: (chirps_year_interes
                        .filter(ee.Filter.eq("n_week", element))
                        .sum()
                        .set({"n_week": element})))

    imgcoll_pr_week = ee.ImageCollection(list_pr_week)

    # - - De ee.ImageCollection a ee.Image - - #
    limit_date = datetime.strptime(limit_date, '%Y-%m-%d')
    limit_date_week = limit_date.isocalendar().week
    limit_date_month = limit_date.month
    limit_date_year = limit_date.year

    if limit_date_year == n_year_interes:
        dict_nombre_bandas = dict(
            week = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_week + 1)], # <3>
            month = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_month + 1)], # <3>
            year = [str(n_year_interes)])
    else:
        dict_nombre_bandas = dict(
            week = [f"0{i}" if i < 10 else str(i) for i in range(1,53)],
            month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)],
            year = [str(n_year_interes)])

    img_pr_year = (imgcoll_pr_year
                .toBands()
                .rename(dict_nombre_bandas["year"]))

    img_pr_month = (imgcoll_pr_month
                    .toBands()
                    .rename(dict_nombre_bandas["month"]))

    img_pr_week = (imgcoll_pr_week
                .toBands()
                .rename(dict_nombre_bandas["week"]))

    img_pr_day = chirps_year_interes.toBands()

    # - - De raster a ee.FeatureCollection = = #
    dict_fc = dict(
        ent = "projects/project-name/assets/00ent",
        mun = "projects/project-name/assets/00mun")
    fc = ee.FeatureCollection(dict_fc[fc_interes])

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
    fc_pr_year = ee.FeatureCollection(img2fc_pr_year.toList(3000).flatten())

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

    # - - Precipitación semanal - - #
    img2fc_pr_week = (img_pr_week
    .reduceRegions(
        collection = fc,
        reducer = ee.Reducer.mean(),
        scale = 5566)
    .map(lambda feature: (ee.Feature(feature)
                            .set({'n_year': n_year_interes})
                            .setGeometry(None))))

    fc_pr_week = ee.FeatureCollection(img2fc_pr_week.toList(3000).flatten())

    # - - Precipitación diaria - - #
    img2fc_pr_day = (img_pr_day
    .reduceRegions(
        collection = fc,
        reducer = ee.Reducer.mean(),
        scale = 5566)
    .map(lambda feature: (ee.Feature(feature)
                            .set({"n_year": n_year_interes})
                            .setGeometry(None))))

    fc_pr_day = ee.FeatureCollection(img2fc_pr_day.toList(3000).flatten())

    # - - De ee.FeatureCollection a CSV - - #
    # ~ Precipitación anual ~ #
    filename_pr_year = f"chirps_pr_mm_{fc_interes}_year_{n_year_interes}"

    # ~ Precipitación mensual ~ #
    filename_pr_month = f"chirps_pr_mm_{fc_interes}_month_{n_year_interes}"

    # ~ Precipitación semanal ~ #
    filename_pr_week = f"chirps_pr_mm_{fc_interes}_week_{n_year_interes}"

    # ~ Precipitación diaria ~ #
    filename_pr_day = f"chirps_pr_mm_{fc_interes}_day_{n_year_interes}"

    # ~ Exportar precipitación anual ~ #
    task_pr_year = ee.batch.Export.table.toDrive(
        collection = fc_pr_year,
        description = filename_pr_year,
        folder = "pruebas_ee")
    task_pr_year.start()
    print(f"Task: {filename_pr_year}")

    # ~ Exportar precipitacion mensual ~ #
    task_pr_month = ee.batch.Export.table.toDrive(
        collection = fc_pr_month,
        description = filename_pr_month,
        folder = "pruebas_ee")
    task_pr_month.start()
    print(f"Task: {filename_pr_month}")

    # ~ Exportar precipitación semanal ~ #
    task_pr_week = ee.batch.Export.table.toDrive(
        collection = fc_pr_week,
        description = filename_pr_week,
        folder = "pruebas_ee")
    task_pr_week.start()
    print(f"Task: {filename_pr_week}")

    # ~ Exportar precipitación diaria ~ #
    task_pr_day = ee.batch.Export.table.toDrive(
        collection = fc_pr_day,
        description = filename_pr_day,
        folder = "pruebas_ee")
    task_pr_day.start()
    print(f"Task: {filename_pr_day}")

    return None

