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
* `periodo_interes`: Se elige entre 3:
                    - `week` (Semanal)
                    - `month` (Mensual)
                    - `year` (Anual)
* `limit_date`: Fecha del límite próximo de los datos. Esta información se
                puede consultar en la página del la `ee.ImageCollection`
"""

# = = = Imports = = = #
import ee
from datetime import datetime
from geemap import ee_export_vector_to_drive

# = = Inicializar Earth Engine = = #
import ee

# Autenticar cuenta de Google asociada a Earth Engine
ee.Authenticate()

# Inicializar la librería
ee.Initialize(project='project-name')

# = = Función de extracción (retorna: vacío) = = #
def get_chirps_metrics(
        n_year_interes,
        periodo_interes,
        limit_date,
        fc_interes,
        year_normal_inicio = 1981,
        year_normal_fin = 2010):

    # - - Carga de CHIRPS - - #
    geom_mex = (ee.FeatureCollection("USDOS/LSIB/2017")
            .filter(ee.Filter.eq("COUNTRY_NA", "Mexico"))
            .first()
            .geometry())

    chirps = (ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
            .select("precipitation")
            .filter(ee.Filter.bounds(geom_mex)))

    # - - Enfoque en el año de interés - - #
    chirps_year_interes = (chirps
    .filter(ee.Filter.calendarRange(start = n_year_interes,
                                    field = "year")))

    # - - Reducción a los periodos de interés - - #
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

    dict_list_periodo_interes = dict(
        week = ee.List.sequence(1, 52),
        month = ee.List.sequence(1, 12))

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

    limit_date = datetime.strptime(limit_date, '%Y-%m-%d')
    limit_date_week = limit_date.isocalendar().week
    limit_date_month = limit_date.month
    limit_date_year = limit_date.year

    if limit_date_year == n_year_interes:
        dict_nombre_bandas = dict(
            week = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_week + 1)],
            month = [f"0{i}" if i < 10 else str(i) for i in range(1, limit_date_month + 1)],
            year = [str(n_year_interes)])
    else:
        dict_nombre_bandas = dict(
            week = [f"0{i}" if i < 10 else str(i) for i in range(1,53)],
            month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)],
            year = [str(n_year_interes)])

    img_periodo_interes_pr = (imgcoll_periodo_interes_pr
                            .toBands()
                            .rename(dict_nombre_bandas[periodo_interes]))

    # = = De raster a CSV = = #
    dict_fc = dict(
        ent = "projects/project-name/assets/00ent",
        mun = "projects/project-name/assets/00mun")
    fc = ee.FeatureCollection(dict_fc[fc_interes])

    # ~ Precipitación en milímetros (mm) ~ #
    img2fc_periodo_interes_pr = (img_periodo_interes_pr
        .reduceRegions(
            collection = fc,
            reducer = ee.Reducer.mean(),
            scale = 5566)
        .map(lambda feature: (ee.Feature(feature)
                              .set({'n_year': n_year_interes})
                              .setGeometry(None))))

    fc_periodo_interes_pr = ee.FeatureCollection(
        (img2fc_periodo_interes_pr
         .toList(3000)
         .flatten()))

    # - - Mandar a exportar a servidor - - #
    # ~ Precipitación en milímetros (mm) ~ #
    description_task_pr = f"pr_{fc_interes}_{periodo_interes}_{n_year_interes}"

    ee_export_vector_to_drive(
        collection= fc_periodo_interes_pr,
        description= description_task_pr,
        fileFormat= "CSV",
        folder= "pruebas_ee")

    return None

# = = Ejecución del código = = #

get_chirps_metrics(
    n_year_interes= 2024,
    fc_interes= "ent",
    periodo_interes= "week",
    limit_date= "2024-08-31")

print("\nFin")

