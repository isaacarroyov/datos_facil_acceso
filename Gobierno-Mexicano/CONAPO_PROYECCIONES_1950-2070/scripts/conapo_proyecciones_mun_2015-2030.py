"""
Script que combina los archivos base_municipios_final_datos_01.csv y base_municipios_final_datos_02.csv  
en un solo archivo CSV con los nombres 'comunes' de las entidades

Autor: Isaac Arroyo
Fecha de creación: 2023-08-21
Fecha de última modificación: 2023-08-21
"""

import pandas as pd
import os

# = = CARGAR AMBOS ARCHIVOS CSV = = #
df1 = pd.read_csv(os.getcwd() + "/Gobierno-Mexicano/CONAPO_PROYECCIONES_1950-2070/municipios/base_original/base_municipios_final_datos_01.csv", encoding="latin1")
df2 = pd.read_csv(os.getcwd() + "/Gobierno-Mexicano/CONAPO_PROYECCIONES_1950-2070/municipios/base_original/base_municipios_final_datos_02.csv", encoding="latin1")

# = = CONCATENAR = = #
# - - Tambien se elimina la columna RENGLON y NOM_ENT - - #
df = pd.concat([df1,df2]).reset_index(drop=True).drop(columns = ["RENGLON", "NOM_ENT"])

# = = CAMBIO DE NOMBRE DE COLUMNAS = = #
df = df.rename(columns = {"CLAVE": "cve_geo", "CLAVE_ENT": "cve_ent", "MUN": "nombre_municipio", "SEXO": "genero", "AÑO": "date_year_n", "EDAD_QUIN": "rango_edad", "POB": "poblacion_proyectada"})


# = = CAMBIAR VALORES EN CELDAS DE ALGUNAS COLUMNAS = = #
df["cve_ent"] = df["cve_ent"].apply(lambda x : f"0{int(x)}" if x < 10 else str(int(x)))
df["cve_geo"] = df["cve_geo"].apply(lambda x : f"0{int(x)}" if x < 10_000 else str(int(x)))
df["rango_edad"] = df["rango_edad"].apply(lambda x: x.replace("pobm_","").replace("_","-"))

# = = ACTUALIZAR NOMBRE DE ESTADOS = = #
nombres_entidades = pd.read_csv(os.getcwd() + "/Gobierno-Mexicano/nombres_claves_entidades.csv")
nombres_entidades["cve_geo"] = nombres_entidades["cve_geo"].apply(lambda x : f"0{x}" if x < 10 else str(x))

df = pd.merge(left=df, right=nombres_entidades[["cve_geo","nombre_estado_comun"]], how = "left", left_on = "cve_ent", right_on= "cve_geo").reset_index(drop = True).rename(columns = {"cve_geo_x":"cve_geo", "nombre_estado_comun":"nombre_estado"}).drop(columns = ["cve_geo_y"])[["nombre_estado","cve_ent","nombre_municipio","cve_geo","date_year_n","rango_edad","poblacion_proyectada"]]

# = = GUARDAR CSV = = #
df.to_csv(os.getcwd() + "/Gobierno-Mexicano/CONAPO_PROYECCIONES_1950-2070/municipios/conapo_proyecciones_mun_2015-2030.csv", index = False)