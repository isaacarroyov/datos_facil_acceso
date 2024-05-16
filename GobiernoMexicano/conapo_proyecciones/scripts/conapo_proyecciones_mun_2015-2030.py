"""
Script que combina los archivos base_municipios_final_datos_01.csv y base_municipios_final_datos_02.csv  
en un solo archivo CSV con los nombres 'comunes' de las entidades

Autor: Isaac Arroyo
Fecha de creación: 2023-08-21
Fecha de última modificación: 2024-03-14
"""

import pandas as pd
import os
import time

path2main = os.getcwd()
path2ogdata_01 = path2main + ("/Gobierno-Mexicano/"
                              "CONAPO_PROYECCIONES_1950-2070/municipios/"
                              "base_original/"
                              "base_municipios_final_datos_01.csv")
path2ogdata_02 = path2main + ("/Gobierno-Mexicano/"
                              "CONAPO_PROYECCIONES_1950-2070/municipios/"
                              "base_original/"
                              "base_municipios_final_datos_02.csv")
path2base_ent = path2main + ("/Gobierno-Mexicano/nombres_claves_entidades.csv")

list_order_df_columns = ["date_year",
                         "nombre_estado",
                         "cve_ent",
                         "nombre_municipio",
                         "cve_mun",
                         "rango_edad",
                         "genero",
                         "poblacion_proyectada"]

path2save = path2main + ("/Gobierno-Mexicano/"
                         "CONAPO_PROYECCIONES_1950-2070/municipios/")

# = = CARGAR AMBOS ARCHIVOS CSV = = #
df1 = pd.read_csv(filepath_or_buffer = path2ogdata_01, encoding = "latin1")
df2 = pd.read_csv(filepath_or_buffer = path2ogdata_02, encoding = "latin1")

# = = CONCATENAR = = #
# - - Tambien se elimina la columna RENGLON y NOM_ENT - - #
df_union = (pd.concat([df1,df2])
            .reset_index(drop=True)
            .drop(columns = ["RENGLON", "NOM_ENT"]))

# = = CAMBIO DE NOMBRE DE COLUMNAS = = #
df_union_renamed = df_union.rename(columns = {
    "CLAVE": "cve_mun",
    "CLAVE_ENT": "cve_ent",
    "MUN": "nombre_municipio",
    "SEXO": "genero",
    "AÑO": "date_year",
    "EDAD_QUIN": "rango_edad",
    "POB": "poblacion_proyectada"})

# = = CAMBIAR VALORES EN CELDAS DE ALGUNAS COLUMNAS = = #
df_union_renamed["cve_ent"] = (df_union_renamed["cve_ent"]
                               .apply(lambda x : f"0{int(x)}" if x < 10 else str(int(x))))
df_union_renamed["cve_mun"] = (df_union_renamed["cve_mun"]
                               .apply(lambda x : f"0{int(x)}" if x < 10_000 else str(int(x))))
df_union_renamed["rango_edad"] = (df_union_renamed["rango_edad"]
                                  .apply(lambda x: x.replace("pobm_","").replace("_","-")))
df_union_renamed["poblacion_proyectada"] = pd.to_numeric(df_union_renamed["poblacion_proyectada"])

# = = ACTUALIZAR NOMBRE DE ESTADOS = = #
nombres_entidades = pd.read_csv(path2base_ent, dtype = str)

# = = Base de datos "completa" y tidy = = #
db = (pd.merge(left = df_union_renamed,
               right = nombres_entidades,
               how = "left",
               on = "cve_ent")
        .reset_index(drop = True)
        [list_order_df_columns])

# = = Base de datos de poblacion total de municipios (sin rango de de edades) = = #
db_no_age = (db
    .groupby(["date_year", "nombre_estado", "cve_ent", "nombre_municipio", "cve_mun", "genero"])
    .sum()["poblacion_proyectada"]
    .reset_index()
    .pivot(index= ["date_year", "nombre_estado", "cve_ent", "nombre_municipio", "cve_mun"],
           columns= ["genero"],
           values = "poblacion_proyectada")
    .reset_index()
    .rename(columns = {"Hombres": "hombres", "Mujeres": "mujeres"}))

db_no_age['total'] = db_no_age['hombres'] + db_no_age['mujeres']

# = = GUARDAR BASES DE DATOS = = #
db.to_csv(
    path_or_buf = path2save + "conapo_proyecciones_mun_2015-2030_all.csv",
    index = False)

db_no_age.to_csv(
    path_or_buf = path2save + "conapo_proyecciones_mun_2015-2030.csv",
    index = False)

print("Listo ✓")