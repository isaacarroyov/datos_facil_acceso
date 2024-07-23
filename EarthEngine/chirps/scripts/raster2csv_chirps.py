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
* `fc_interes`: `ee.FeatureCollection` de las geomtrías e información de 
                los **Estados (`ent`)**, **Municipios (`mun`)**
* `periodo_interes`: Se elige entre 3: **Semanal (`week`)**, **Mensual 
                     (`month`)** o **Anual (`year`)**
* `limit_date`: Fecha del límite próximo de los datos. Esta información se 
                puede consultar en la página del la `ee.ImageCollection`
"""

import ee 

try:
    ee.Initialize() 
    print("Se ha inicializado correctamente")
except:
    print("Error en la inicialización")