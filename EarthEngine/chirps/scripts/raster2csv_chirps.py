"""
Author: Isaac Arroyo
Notes: La extración y procesamiento de datos es una adaptación y mejora al 
       realizado en el proyecto "Desplazamiento climático: La migración que 
       no vemos de N+ Focus" (en https://github.com/nmasfocusdatos/desplazamiento-climatico).


En este script se encuentra el código para la extracción de variables 
derivadas de la precipitación tales como: 

* Precipitación en milímetros (mm)
* Anomalía de la precipitación en porcentaje (%) con respecto de la normal 
* Anomalía de la precipitación en milímetros (mm) con respecto de la normal

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
try:
    ee.Initialize() 
    print("Se ha inicializado correctamente")
except:
    print("Error en la inicialización")

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
            year = [n_year_interes])
    else:
        dict_nombre_bandas = dict(
            week = [f"0{i}" if i < 10 else str(i) for i in range(1,53)],
            month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)],
            year = [n_year_interes])

    img_periodo_interes_pr = (imgcoll_periodo_interes_pr
                            .toBands()
                            .rename(dict_nombre_bandas[periodo_interes]))
    """
    # - - Acumulación normal - - #
    imgcoll_normal_pr = (chirps
                         .filter(ee.Filter.calendarRange(
                             start = year_normal_inicio,
                             end = year_normal_fin,
                             field = "year")))
    imgcoll_normal_pr_tagged = imgcoll_normal_pr.map(func_tag_date)
    
    def func_reduce2yearnperiods(n_year):
        imgcoll_year_normal = (imgcoll_normal_pr_tagged
                               .filter(ee.Filter.eq("n_year", n_year)))
        
        dict_reducer_func_reduce2yearnperiods = dict(
            week = (dict_list_periodo_interes["week"]
                    .map(lambda element: (imgcoll_year_normal
                                          .filter(ee.Filter.eq("n_week", element))
                                          .sum()
                                          .set({"n_week": element})))),
            month = (dict_list_periodo_interes["month"]
                    .map(lambda element: (imgcoll_year_normal
                                          .filter(ee.Filter.eq("n_month", element))
                                          .sum()
                                          .set({"n_month": element})))),
            year = (ee.List.sequence(n_year, n_year)
                    .map(lambda element: (imgcoll_year_normal
                                          .filter(ee.Filter.eq("n_year", element))
                                          .sum()
                                          .set({"n_year": element})))))
        
        return dict_reducer_func_reduce2yearnperiods[periodo_interes] # <3>

    imgcoll_normal_pr_periodo_interes = (ee.ImageCollection
        .fromImages((ee.List
                     .sequence(year_normal_inicio, year_normal_fin)
                     .map(func_reduce2yearnperiods)
                     .flatten())))
    dict_reducer_mean_periodo_interes_normal = dict( 
        week = (dict_list_periodo_interes["week"]
                .map(lambda element: (imgcoll_normal_pr_periodo_interes
                                      .filter(ee.Filter.eq("n_week", element))
                                      .mean()
                                      .set({"n_week": element})))),
        month = (dict_list_periodo_interes["month"]
                .map(lambda element: (imgcoll_normal_pr_periodo_interes
                                      .filter(ee.Filter.eq("n_month", element))
                                      .mean()
                                      .set({"n_month": element})))),
        year = (ee.List.sequence(1, 1)
                .map(lambda element: (imgcoll_normal_pr_periodo_interes
                                      .mean()))))

    dict_nombre_bandas_normal = dict(
            week = [f"0{i}" if i < 10 else str(i) for i in range(1,53)],
            month = [f"0{i}" if i < 10 else str(i) for i in range(1,13)],
            year = ["normal"])

    img_periodo_interes_pr_normal = (ee.ImageCollection
        .fromImages(dict_reducer_mean_periodo_interes_normal[periodo_interes])
        .toBands()
        .rename(dict_nombre_bandas_normal[periodo_interes]))

    # = = = Métricas a calcular = = = #
    # ~ Precipitación en milímetros (mm) ~ #
    # No se hace cálculo

    # ~ Anomalía de precipitación en milímetros (mm) con respecto a la normal ~ #
    img_periodo_interes_anomaly_pr_mm = ee.Image((img_periodo_interes_pr
                                        .subtract(img_periodo_interes_pr_normal)
                                        .copyProperties(
                                            img_periodo_interes_pr,
                                            img_periodo_interes_pr.propertyNames())))
    
    # ~ Anomalía de precipitación en procentaje (%) con respecto a la normal ~ #
    img_periodo_interes_anomaly_pr_prop = ee.Image((img_periodo_interes_pr
                                          .subtract(img_periodo_interes_pr_normal)
                                          .divide(img_periodo_interes_pr_normal)
                                          .copyProperties(
                                              img_periodo_interes_pr,
                                              img_periodo_interes_pr.propertyNames())))
    """
    # = = De raster a CSV = = #
    dict_fc = dict(
        ent = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_ENT_2022",
        mun = "projects/ee-unisaacarroyov/assets/GEOM-MX/MX_MUN_2022")
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
    """
    # ~ Anomalía de precipitación en milímetros (mm) con respecto a la normal ~ #
    img2fc_periodo_interes_anomaly_pr_mm = (img_periodo_interes_anomaly_pr_mm
        .reduceRegions(
            collection = fc,
            reducer = ee.Reducer.mean(),
            scale = 5566)
        .map(lambda feature: (ee.Feature(feature)
                              .set({'n_year': n_year_interes})
                              .setGeometry(None))))

    fc_periodo_interes_anomaly_pr_mm = ee.FeatureCollection(
        (img2fc_periodo_interes_anomaly_pr_mm
         .toList(3000)
         .flatten()))

    # ~ Anomalía de precipitación en procentaje (%) con respecto a la normal ~ #
    img2fc_periodo_interes_anomaly_pr_prop = (img_periodo_interes_anomaly_pr_prop
        .reduceRegions(
            collection = fc,
            reducer = ee.Reducer.mean(),
            scale = 5566)
        .map(lambda feature: (ee.Feature(feature)
                              .set({'n_year': n_year_interes})
                              .setGeometry(None))))

    fc_periodo_interes_anomaly_pr_prop = ee.FeatureCollection(
        (img2fc_periodo_interes_anomaly_pr_prop
         .toList(3000)
         .flatten()))
    """
    
    # - - Mandar a exportar a servidor - - #
    # ~ Precipitación en milímetros (mm) ~ #
    description_task_pr = f"pr_{fc_interes}_{periodo_interes}_{n_year_interes}"

    ee_export_vector_to_drive(
        collection= fc_periodo_interes_pr,
        description= description_task_pr,
        fileFormat= "CSV",
        folder= "pruebas_ee")
    """
    # ~ Anomalía de precipitación en milímetros (mm) con respecto a la normal ~ #
    description_task_anomaly_pr_mm = f"anomaly_pr_mm_{fc_interes}_{periodo_interes}_{n_year_interes}"

    ee_export_vector_to_drive(
        collection= fc_periodo_interes_anomaly_pr_mm,
        description= description_task_anomaly_pr_mm,
        fileFormat= "CSV",
        folder= "pruebas_ee")

    # ~ Anomalía de precipitación en procentaje (%) con respecto a la normal ~ #
    description_task_anomaly_pr_prop = f"anomaly_pr_prop_{fc_interes}_{periodo_interes}_{n_year_interes}"

    ee_export_vector_to_drive(
        collection= fc_periodo_interes_anomaly_pr_prop,
        description= description_task_anomaly_pr_prop,
        fileFormat= "CSV",
        folder= "pruebas_ee")
    """
    
    return None

# = = Ejecución del código = = #

get_chirps_metrics(
    n_year_interes= 24,
    fc_interes= "ent",
    periodo_interes= "week",
    limit_date= "2024-06-30")

print("\nFin")