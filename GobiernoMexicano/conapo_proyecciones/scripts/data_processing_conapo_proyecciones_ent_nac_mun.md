# Proyecciones de población de México
Isaac Arroyo
18 de mayo de 2024

## Introducción

En este documento GitHub Flavored Markdown se encuentra documentado el
código usado para la transformación y estandarización de los datos de la
Proyección de población de México que emite el **Consejo Nacional de
Población (CONAPO)**, tanto para nivel Nacional, Estatal y Municipal.

> \[!NOTE\]
>
> Cuando se habla de una *estandarización* es completamente subjetivo,
> ya que la manera en la que están estructuradas las bases de datos
> pueden ser las ideales para otro tipo de usuarios. En el caso personal
> una estrucura
> [*tidy*](https://tidyr.tidyverse.org/articles/tidy-data.html#tidy-data)
> es la que mejor se ajusta a mis requerimientos y proyectos.

``` python
import pandas as pd
import os

# Cambiar al folder principal del repositorio
os.chdir("../../../")

# Rutas a las carpetas necesarias
path2main = os.getcwd()
path2gobmex = path2main + "/GobiernoMexicano"
path2conapo = path2gobmex + "/conapo_proyecciones"
```

## Población a mitad e inicio de año de los estados de México (1950-2070)

``` python
path2conapoent = path2conapo + "/entidades"
```

> \[!NOTE\]
>
> - Actualización de los datos: Agosto 04, 2023.
> - Este código fue originalmente creado el 21 de agosto de 2023

Los datos publicados por la CONAPO incluyen 9 archivos:

- 0_Pob_Inicio_1950_2070.xlsx
- 0_Pob_Mitad_1950_2070.xlsx
- 1_Defunciones_1950_2070.xlsx
- 2_mig_inter_quinquen_proyecciones.xlsx
- 3_mig_interest_quinquenal_proyecciones.xlsx
- 4_Tasas_Especificas_Fecundidad_proyecciones.xlsx
- 5_Indicadores_demográficos_proyecciones.xlsx
- 6_Esperanza_Vida_Nacer_1950_2070.xlsx
- DICCIONARIO_2023_v3_07082023.pdf

De los cuales, para esta ocasión (y por ahora) se usarán 2:

- **0_Pob_Inicio_1950_2070.xlsx**
- **0_Pob_Mitad_1950_2070.xlsx**

> *Es común que en los cálculos de tasado por cada 1,000 (mil) ó 100,000
> (cien mil) habitantes se use la **población a mitad de año** en lugar
> de la población al inicio del año. Sin embargo, pertenecen a la misma
> base de datos e información.*

``` python
df_pob_ent_inicio_year = pd.read_excel(
    path2conapoent + "/0_Pob_Inicio_1950_2070.xlsx") 
df_pob_ent_mid_year = pd.read_excel(
    path2conapoent + "/0_Pob_Mitad_1950_2070.xlsx")
```

### Cambios a los `pandas.DataFrame`s

Ambos conjuntos de datos tienen las mismas columnas con el mismo nombre,
a continuación se muestra un ejemplo:

| RENGLON |  AÑO | ENTIDAD  | CVE_GEO | EDAD | SEXO    | POBLACION |
|--------:|-----:|:---------|--------:|-----:|:--------|----------:|
|  397482 | 2024 | Campeche |       4 |   80 | Mujeres |      1007 |
|  687945 | 2064 | Coahuila |       5 |    2 | Hombres |     20189 |
|  156305 | 1990 | Veracruz |      30 |   52 | Hombres |     20082 |

A continuación se enlistan las transformaciones y cambios que se le
harán a ambos conjuntos de datos:

1.  Renombrar columnas
2.  Unir ambos `pandas.DataFrame`s en uno solo
3.  Transformar la columna de códigos de las entidades
4.  Renombrar los estados

### Renombrar columnas

``` python
df_pob_ent_inicio_year = (df_pob_ent_inicio_year
  .rename(
      columns = {
          "AÑO": "n_year",
          "ENTIDAD": "entidad",
          "CVE_GEO": "cve_ent",
          "EDAD": "edad",
          "SEXO": "genero",
          # Dejar en claro que es la población al inicio del año
          "POBLACION": "pob_start_year"})
  # Eliminar columna que no aporta en la base de datos
  .drop(columns = "RENGLON"))

df_pob_ent_mid_year = (df_pob_ent_mid_year
  .rename(
      columns= {
          "AÑO": "n_year",
          "ENTIDAD": "entidad",
          "CVE_GEO": "cve_ent",
          "EDAD": "edad",
          "SEXO": "genero",
          # Dejar en claro que es la población a mitad del año
          "POBLACION": "pob_mid_year"})
  # Eliminar columna que no aporta en la base de datos
  .drop(columns = "RENGLON"))
```

### Unir ambos `pandas.DataFrame`s en uno solo

``` python
db_proj_ent = (pd.merge(
    left = df_pob_ent_inicio_year,
    right = df_pob_ent_mid_year.drop(columns = "entidad"),
    how = "left",
    on = ["n_year", "cve_ent", "edad","genero"])
  .reset_index(drop = True))

db_proj_ent["pob_mid_year"] = pd.to_numeric(
    db_proj_ent['pob_mid_year'],
    errors= 'coerce')
```

### Transformar columna de códigos de estados

Los códigos de los estados (`cve_ent`) fueron leídos por Python como
números en lugar de caracteres, por lo que tiene que se tiene que hacer
ese cambio.

``` python
# Función lambda para modificar claves de estados
func_trans_cve_ent = lambda x : f"0{int(x)}" if x < 10 else str(int(x))

db_proj_ent["cve_ent"] = (df_pob_ent_inicio_year["cve_ent"]
                          .apply(func = func_trans_cve_ent))
```

### Renombrar el nombre de los estados

La manera en la que están escritos los nombres de algunos estados no son
como comúnmente se nombran, por ejemplo, en la base de datos de la
CONAPO, **Coahuila** esta bajo el nombre de *Coahuila de Zaragoza*.

Es por eso que se usarán los nombres *comunes* de los estados, que se
encuentran en el archivo `cve_nom_estados.csv`, que se encuentra en la
carpeta `GobiernoMexicano`

``` python
cve_nom_ent = pd.read_csv(path2gobmex + "/cve_nom_estados.csv")
cve_nom_ent["cve_ent"] = (cve_nom_ent["cve_ent"]
  .fillna(0)
  .apply(lambda x : f"0{int(x)}" if x < 10 else str(int(x))))

list_orden_cols_ent = [
  "n_year",
  "nombre_estado",
  "cve_ent",
  "edad",
  "genero",
  "pob_start_year",
  "pob_mid_year"]

db_proj_ent = (db_proj_ent
               .drop(columns="entidad")
               .merge(cve_nom_ent, on = "cve_ent")
               [list_orden_cols_ent])
```

## Población a mitad de año de los municipios de México (2015-2030)

``` python
path2conapomun = path2conapo + "/municipios"
```

> \[!NOTE\]
>
> - Actualización de los datos: Septiembre 02, 2019.
> - Este código fue originalmente creado el 21 de agosto de 2023
> - Estos datos ya no se encuentran en la página de la CONAPO, fueron
>   descargados a mediados de 2023

Los datos publicados por la CONAPO incluyen dos archivos en CSV, y a
diferencia de la proyección de los estados, la de los municipios esta
dividida por la gran cantidad de datos (son más de 2 mil municipios) y
no porque una sea población al inicio del año.

El nombre de los archivos son:

- base_municipios_final_datos_01.csv
- base_municipios_final_datos_02.csv

``` python
df_pob_mun_mid_year_01 = pd.read_csv(
    filepath_or_buffer = (path2conapomun + 
                          "/base_municipios_final_datos_01.csv"),
    encoding = "latin1")

df_pob_mun_mid_year_02 = pd.read_csv(
    filepath_or_buffer = (path2conapomun + 
                          "/base_municipios_final_datos_02.csv"),
    encoding = "latin1")
```

### Cambios a los `pandas.DataFrame`s

Ambos conjuntos de datos tienen las mismas columnas con el mismo nombre,
a continuación se muestra un ejemplo:

| RENGLON | CLAVE | CLAVE_ENT | NOM_ENT    | MUN      | SEXO    |  AÑO | EDAD_QUIN  |  POB |
|--------:|------:|----------:|:-----------|:---------|:--------|-----:|:-----------|-----:|
|  801679 | 19018 |        19 | Nuevo León | García   | Mujeres | 2029 | pobm_50_54 | 4768 |
|  751482 | 10004 |        10 | Durango    | Cuencamé | Hombres | 2024 | pobm_45_49 | 1097 |
|  241710 | 11045 |        11 | Guanajuato | Xichú    | Mujeres | 2028 | pobm_15_19 |  609 |

A continuación se enlistan las transformaciones y cambios que se le hará
a la base de datos de manera general.

1.  Concatenar ambos `pandas.DataFrame`s en uno solo
2.  Renombrar columnas
3.  Transformar la columna de códigos de las entidades y de los
    municipios
4.  Transformar la columna de códigos de edades
5.  Renombrar los estados

A partir de este procesamiento, se crean dos bases de datos:

1.  Base de datos completa, con la división de género y edades
2.  Base de datos con la división de los géneros y uniendo las
    categorías de edades

### Concatenar ambos `pandas.DataFrame`s en uno solo

``` python
df_union_pob_mun = (pd.concat([df_pob_mun_mid_year_01,
                               df_pob_mun_mid_year_02])
            .reset_index(drop=True)
            # Eliminar columnas que no aportan o no son necesarias en la 
            # base de datos
            .drop(columns = ["RENGLON", "NOM_ENT"]))
```

### Renombrar columnas

``` python
db_proj_mun = (df_union_pob_mun
    .rename(columns = {
        "CLAVE": "cve_mun",
        "CLAVE_ENT": "cve_ent",
        "MUN": "nombre_municipio",
        "SEXO": "genero",
        "AÑO": "n_year",
        "EDAD_QUIN": "rango_edad",
        "POB": "pob_mid_year"}))
```

### Transformar la columna de códigos de las entidades y de los municipios

Tanto los códigos de los estados (`cve_ent`) como el de los municipios
(`cve_mun`) fueron leídos por Python como números en lugar de
caracteres, por lo que tiene que se tiene que hacer ese cambio.

``` python
# Función lambda para modificar claves de municipio
func_trans_cve_mun = lambda x : f"0{int(x)}" if x < 10_000 else str(int(x))

db_proj_mun["cve_ent"] = (db_proj_mun["cve_ent"]
                         .apply(func = func_trans_cve_ent))
db_proj_mun["cve_mun"] = (db_proj_mun["cve_mun"]
                         .apply(func = func_trans_cve_mun))
```

### Transformar la columna de códigos de edades

Los códigos de las edades estan organizados por rangos de 5 años,

``` python
# Función para modificar códigos de edades
def func_trans_rango_edad(cat_age):
    cat_age_clean = (cat_age
                     .replace("pobm_","Age")
                     .replace("mm", "more"))
    return cat_age_clean

db_proj_mun["rango_edad"] = (db_proj_mun["rango_edad"]
                            .apply(func = func_trans_rango_edad))
```

### Adjuntar el nombre de los estados

La manera en la que están escritos los nombres de algunos estados no son
como comúnmente se nombran, por ejemplo, en la base de datos de la
CONAPO, **Coahuila** esta bajo el nombre de *Coahuila de Zaragoza*.

Es por eso que se usarán los nombres *comunes* de los estados, que se
encuentran en el archivo `cve_nom_estados.csv`, previamente cargados en
el script.

``` python
list_orden_cols_mun = [
  "n_year",
  "nombre_estado",
  "cve_ent",
  "nombre_municipio",
  "cve_mun",
  "rango_edad",
  "genero",
  "pob_mid_year"]

db_proj_mun = (pd.merge(left = db_proj_mun,
                        right = cve_nom_ent,
                        how = "left",
                        on = "cve_ent")
              .reset_index(drop = True)
              [list_orden_cols_mun])
```

### Base de datos con la división de los géneros y uniendo las categorías de edades

> agregar la categoria de la suma de pob de ambos generos

``` python
db_proj_mun_all_ages = (db_proj_mun.groupby([
    "n_year",
    "nombre_estado",
    "cve_ent",
    "nombre_municipio",
    "cve_mun",
    "genero"])
    .sum()["pob_mid_year"]
    .reset_index()
    .pivot(
        index = [
            "n_year", 
            "nombre_estado",
            "cve_ent",
            "nombre_municipio",
            "cve_mun"],
        columns = ["genero"],
        values = "pob_mid_year")
    .reset_index())

db_proj_mun_all_ages['Total'] = (db_proj_mun_all_ages['Hombres'] + 
                                 db_proj_mun_all_ages['Mujeres'])
```

> explicar que se pondra en formato long

``` python
db_proj_mun_all_ages = pd.melt(
    db_proj_mun_all_ages,
    id_vars = ['n_year', 'nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun'],
    value_vars = ['Hombres', 'Mujeres', 'Total'],
    var_name= "genero",
    value_name = "pob_mid_year")
```

## Guardar bases de datos
