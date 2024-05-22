# Procesamiento y transformación de datos: Proyecciones de población de
México
Isaac Arroyo
21 de mayo de 2024

## Introducción

En este documento se encuentra documentado el código usado para la
transformación y estandarización de los datos de la Proyección de
población de México que emite el **Consejo Nacional de Población
(CONAPO)**, tanto para nivel Nacional, Estatal y Municipal.

``` python
import pandas as pd
import os

# Cambiar al folder principal del repositorio
os.chdir("../../")

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

| RENGLON |  AÑO | ENTIDAD        | CVE_GEO | EDAD | SEXO    | POBLACION |
|--------:|-----:|:---------------|--------:|-----:|:--------|----------:|
|  475967 | 2034 | Yucatán        |      31 |   53 | Hombres |     15064 |
|  274974 | 2007 | Chihuahua      |       8 |   96 | Mujeres |       113 |
|   77227 | 1980 | Aguascalientes |       1 |    3 | Hombres |      9049 |

A continuación se enlistan las transformaciones y cambios que se le
harán a ambos conjuntos de datos:

1.  Renombrar columnas
2.  Unir ambos `pandas.DataFrame`s en uno solo
3.  Transformar la columna de códigos de las entidades
4.  Renombrar los estados

A partir de este procesamiento, se crean dos bases de datos:

1.  Base de datos completa, con la división de género y edades
2.  Base de datos con la división de los géneros y uniendo las
    categorías de edades

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
  .query("n_year <= 2070")
  .reset_index(drop = True))

db_proj_ent['pob_mid_year'] = db_proj_ent['pob_mid_year'].astype(int)
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

### Crear un conjunto de datos de la población de ambos géneros sin distinción de la edad

Cuando se dice **sin distinción de edad** se habla de que se suma la
población de todas las edades

``` python
db_proj_ent_all_ages = (db_proj_ent.groupby([
    "n_year",
    "nombre_estado",
    "cve_ent",
    "genero"])
    .sum()[["pob_start_year", "pob_mid_year"]]
    .reset_index())
```

Ahora se va a transformar los datos de *wide format* a *long format*
para crear una columna donde se sumen las poblaciones de ambos géneros

``` python
db_proj_ent_all_ages = db_proj_ent_all_ages.pivot(
    index = ['n_year', 'nombre_estado', 'cve_ent'],
    columns= ['genero'],
    values = ['pob_start_year', 'pob_mid_year'])
```

Despues de aplicar `pivot` al `pandas.DataFrame`, se tiene un
`pandas.DataFrame` con multi-índice en filas y columnas.

|                                  | (‘pob_start_year’, ‘Hombres’) | (‘pob_start_year’, ‘Mujeres’) | (‘pob_mid_year’, ‘Hombres’) | (‘pob_mid_year’, ‘Mujeres’) |
|:---------------------------------|------------------------------:|------------------------------:|----------------------------:|----------------------------:|
| (2070, ‘Ciudad de México’, ‘09’) |                   3.22117e+06 |                   3.36655e+06 |                 3.20338e+06 |                 3.34511e+06 |
| (2032, ‘Nayarit’, ‘18’)          |                        692797 |                        712547 |                      695071 |                      715531 |
| (1986, ‘Aguascalientes’, ‘01’)   |                        317950 |                        327881 |                      323441 |                      333790 |

Específicamente, se renombran las columnas con la combinación de
`{poblacion a inicio o mitad de año}_{genero}`

``` python
# Renombrar columnas de población para que tengan como suffix el genero
db_proj_ent_all_ages.columns = ['_'.join(col) for col in 
                                db_proj_ent_all_ages.columns]

# Eliminar el multi-index (sin eliminar las columnas indice)
db_proj_ent_all_ages = db_proj_ent_all_ages.reset_index()
```

El resultado es el siguiente:

| n_year | nombre_estado    | cve_ent | pob_start_year_Hombres | pob_start_year_Mujeres | pob_mid_year_Hombres | pob_mid_year_Mujeres |
|-------:|:-----------------|--------:|-----------------------:|-----------------------:|---------------------:|---------------------:|
|   2070 | Ciudad de México |      09 |                3221170 |                3366552 |              3203379 |              3345111 |
|   2032 | Nayarit          |      18 |                 692797 |                 712547 |               695071 |               715531 |
|   1986 | Aguascalientes   |      01 |                 317950 |                 327881 |               323441 |               333790 |

Ahora solo falta crear la columna de la suma de las poblaciones de los
géneros

``` python
# Poblacion total a inicio de año
db_proj_ent_all_ages['pob_start_year_Total'] = (
    db_proj_ent_all_ages['pob_start_year_Hombres'] + 
    db_proj_ent_all_ages['pob_start_year_Mujeres'])

# Poblacion total a mitad de año
db_proj_ent_all_ages['pob_mid_year_Total'] = (
    db_proj_ent_all_ages['pob_mid_year_Hombres'] + 
    db_proj_ent_all_ages['pob_mid_year_Mujeres'])
```

El objetivo sigue siendo el mismo, mantener los datos *tidy*, por lo que
se volverá a hacer la transformación de datos *wide format* a *long
format*.

``` python
db_proj_ent_all_ages = (pd.wide_to_long(
    df = db_proj_ent_all_ages,
    stubnames = ['pob_start_year', 'pob_mid_year'],
    i = ['n_year','nombre_estado', 'cve_ent'],
    j = 'genero',
    sep = "_",
    suffix=r'\w+')
  .reset_index())
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

| RENGLON | CLAVE | CLAVE_ENT | NOM_ENT          | MUN                | SEXO    |  AÑO | EDAD_QUIN  |   POB |
|--------:|------:|----------:|:-----------------|:-------------------|:--------|-----:|:-----------|------:|
|  908503 |  9007 |         9 | Ciudad de México | Iztapalapa         | Hombres | 2021 | pobm_55_59 | 46302 |
|   51866 | 16004 |        16 | Michoacán        | Angamacutiro       | Hombres | 2024 | pobm_00_04 |   683 |
|   88143 | 14064 |        14 | Jalisco          | Ojuelos de Jalisco | Mujeres | 2029 | pobm_05_09 |  1645 |

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

### Crear un conjunto de datos de la población de ambos géneros sin distinción de la edad

Cuando se dice **sin distinción de edad** se habla de que se suma la
población de todas las edades

> \[!NOTE\]
>
> El procesamiento es más sencillo que el de los estados ya que
> solamente hay una columna de información

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
    # Long2Wide
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

# Poblacion total a mitad de año
db_proj_mun_all_ages['Total'] = (db_proj_mun_all_ages['Hombres'] + 
                                 db_proj_mun_all_ages['Mujeres'])
```

El objetivo sigue siendo el mismo, mantener los datos *tidy*, por lo que
se volverá a hacer la transformación de datos *wide format* a *long
format*.

``` python
db_proj_mun_all_ages = pd.melt(
    db_proj_mun_all_ages,
    id_vars = ['n_year', 'nombre_estado', 'cve_ent', 'nombre_municipio', 'cve_mun'],
    value_vars = ['Hombres', 'Mujeres', 'Total'],
    var_name= "genero",
    value_name = "pob_mid_year")
```

## Guardar bases de datos

### Proyección de la población a inicio y mitad del año de los Estados de México

Base de datos con división de género y división de edad

Nombre del archivo: **/conapo_pob_ent_gender_age_1950_2070.csv.bz2**

| n_year | nombre_estado       | cve_ent | edad | genero  | pob_start_year | pob_mid_year |
|-------:|:--------------------|--------:|-----:|:--------|---------------:|-------------:|
|   1992 | Chihuahua           |      08 |   37 | Mujeres |          14532 |        14905 |
|   2062 | Guanajuato          |      11 |   28 | Hombres |          41364 |        41154 |
|   1990 | Baja California Sur |      03 |   32 | Mujeres |           2346 |         2407 |
|   1986 | Coahuila            |      05 |   61 | Hombres |           3718 |         3792 |
|   1985 | Aguascalientes      |      01 |   24 | Mujeres |           5327 |         5473 |

``` python
db_proj_ent.to_csv(
  path_or_buf= path2conapo + filename_db_proj_ent,
  compression= "bz2",
  index = False)
```

Base de datos con división de género y unión de edades

Nombre del archivo: **/conapo_pob_ent_gender_1950_2070.csv**

| n_year | nombre_estado   | cve_ent | genero  | pob_start_year | pob_mid_year |
|-------:|:----------------|--------:|:--------|---------------:|-------------:|
|   1990 | Nacional        |      00 | Mujeres |       42231778 |     42648349 |
|   2049 | Querétaro       |      22 | Hombres |        1686191 |      1690779 |
|   2023 | Oaxaca          |      20 | Total   |        4260710 |      4276769 |
|   2007 | San Luis Potosí |      24 | Hombres |        1235204 |      1241918 |
|   2014 | Yucatán         |      31 | Mujeres |        1066091 |      1073334 |

``` python
db_proj_ent_all_ages.to_csv(
  path_or_buf= path2conapo + filename_db_proj_ent_all_ages,
  index = False)
```

### Proyección de la población a mitad del año de los Municipios de México

Base de datos con división de género y división de edad

Nombre del archivo: **/conapo_pob_mun_gender_age_2015_2030.csv.bz2**

| n_year | nombre_estado    | cve_ent | nombre_municipio          | cve_mun | rango_edad | genero  | pob_mid_year |
|-------:|:-----------------|--------:|:--------------------------|--------:|:-----------|:--------|-------------:|
|   2020 | Oaxaca           |      20 | Villa Hidalgo             |   20038 | Age65_more | Hombres |          109 |
|   2020 | Veracruz         |      30 | Isla                      |   30077 | Age60_64   | Mujeres |          851 |
|   2023 | Sonora           |      26 | Pitiquito                 |   26047 | Age40_44   | Hombres |          367 |
|   2023 | Oaxaca           |      20 | Villa Tejúpam de la Unión |   20486 | Age10_14   | Mujeres |           99 |
|   2020 | Estado de México |      15 | Temoaya                   |   15087 | Age20_24   | Hombres |         4935 |

``` python
db_proj_mun.to_csv(
  path_or_buf= path2conapo + filename_db_proj_mun,
  compression= "bz2",
  index = False)
```

Base de datos con división de género y unión de edades

Nombre del archivo: **/conapo_pob_mun_gender_2015_2030.csv**

| n_year | nombre_estado   | cve_ent | nombre_municipio       | cve_mun | genero  | pob_mid_year |
|-------:|:----------------|--------:|:-----------------------|--------:|:--------|-------------:|
|   2025 | Morelos         |      17 | Cuautla                |   17006 | Total   |       219233 |
|   2023 | Oaxaca          |      20 | Santa María Chilchotla |   20406 | Hombres |        10339 |
|   2027 | San Luis Potosí |      24 | Santo Domingo          |   24033 | Total   |        13233 |
|   2018 | Campeche        |      04 | Campeche               |   04002 | Mujeres |       158667 |
|   2017 | Chihuahua       |      08 | Batopilas              |   08008 | Hombres |         6548 |

``` python
db_proj_mun_all_ages.to_csv(
  path_or_buf= path2conapo + filename_db_proj_mun_all_ages,
  index = False)
```
