# Datos del Gobierno de México

En este espacio se encuentran datos relacionados al Gobierno de México, 
tales como encuestas, _shapefiles_ de la división política de Estados y 
Municipios, encuestas, medio ambiente, entre otros.

## Códigos y nombres de los Estados 

> [!NOTE]
> Datos tomados del Marco Geoestadístico 2022, de haber un cambio en el Marco Geoestadístico 2023, se actualizará

→ [Descarga el CSV de relación Código-Nombre de las entidades](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/cve_nom_estados.csv)

| nombre_estado    |   cve_ent |
|:-----------------|----------:|
| Colima           |        06 |
| Ciudad de México |        09 |
| Michoacán        |        16 |


## Códigos y nombres de los Municipios 

> [!NOTE]
> Datos tomados del Marco Geoestadístico 2022, de haber un cambio en el Marco Geoestadístico 2023, se actualizará

→ [Descarga el CSV de relación Código-Nombre de los municipios](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/cve_nom_municipios.csv)

| nombre_estado   |   cve_ent | nombre_municipio          |   cve_mun |
|:----------------|----------:|:--------------------------|----------:|
| Oaxaca          |        20 | Teotitlán de Flores Magón |     20545 |
| Veracruz        |        30 | Jáltipan                  |     30089 |
| San Luis Potosí |        24 | Tampamolón Corona         |     24039 |


## Geometrías de estados y municipios

> [!NOTE]
> Datos tomados del Marco Geoestadístico 2023

→ [Descarga el GeoJSON de las geometrías del los **estados** de México](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/geometrias/00ent_mexico.geojson)

→ [Descarga el GeoJSON de las geometrías del los **municipios** de México](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/geometrias/00mun_simplified-t005-geopandas.geojson)


## INEGI

### Censo de Población y Vivienda

**Resultados generales por entidad federativa, 2020**

→ [Descarga el CSV de los resultados generales por entidad federativa del Censo de Población y Vivienda 2020](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/inegi/censo/2020/censo_2020_mexico_estandarizado.csv)

| nombre_estado_inegi   | nombre_estado    |   cve_geo |   pob_total_2020 |   pob_h_2020 |   pob_m_2020 |
|:----------------------|:-----------------|----------:|-----------------:|-------------:|-------------:|
| Colima                | Colima           |        06 |           731391 |       360622 |       370769 |
| Ciudad de México      | Ciudad de México |        09 |          9209944 |      4404927 |      4805017 |
| Michoacán de Ocampo   | Michoacán        |        16 |          4748846 |      2306341 |      2442505 |
| Durango               | Durango          |        10 |          1832650 |       904866 |       927784 |
| México                | Estado de México |        15 |         16992418 |      8251295 |      8741123 |


**Resultados por AGEBS (por entidad), 2020**

→ [Visita la carpeta con los CSVs de los resultados por AGEBS del Censo de Población y Vivienda 2020](https://github.com/isaacarroyov/datos_facil_acceso/tree/main/GobiernoMexicano/inegi/censo/2020/agebs)

> [!NOTE]
> Esta tabla es solo muestra las primeras 10 columnas del conjunto de datos **`RESAGEBURB_31CSV20.csv.bz2`**

|   cve_ent | nom_ent   |   cve_mun | nom_mun   |   cve_loc | nom_loc   |   ageb |   mza |   pobtot |   pobfem |
|----------:|:----------|----------:|:----------|----------:|:----------|-------:|------:|---------:|---------:|
|        31 | Yucatán   |        41 | Kanasín   |         1 | Kanasín   |   0136 |    38 |       36 |       19 |
|        31 | Yucatán   |        79 | Tekax     |        10 | Kancab    |   0684 |    37 |       62 |       33 |
|        31 | Yucatán   |        50 | Mérida    |         1 | Mérida    |   3712 |    17 |      110 |       55 |
|        31 | Yucatán   |        55 | Opichén   |         1 | Opichén   |   0095 |    32 |       68 |       35 |
|        31 | Yucatán   |        93 | Tixkokob  |         1 | Tixkokob  |   0043 |    11 |       73 |       41 |


## Medio ambiente

### Monitor de Sequía de México

> [!NOTE]  
>  Datos tomados del Monitor de Sequía de Mexico (MSM), CONAGUA. Estos datos son actualizados de manera quincenal en la página oficial y en este repositorio cuando me acuerdo de actualizarlo, se estará trabajando en la automatización de estos.

**Sequía en los municipios (registros)**

→ [Descarga el CSV.BZ2 del registro de sequía en los municipios de México](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/msm/datos/sequia_municipios.csv.bz2)

|   cve_concatenada |   cve_ent |   cve_mun | nombre_mun               | entidad                         | org_cuenca              | clv_oc   | con_cuenca      |   cve_conc | full_date   | sequia     |
|------------------:|----------:|----------:|:-------------------------|:--------------------------------|:------------------------|:---------|:----------------|-----------:|:------------|:-----------|
|             20444 |        20 |       444 | Santa María Yolotepec    | Oaxaca                          | Pacífico Sur            | V        | Costa de Oaxaca |         11 | 2022-03-15  | D0         |
|             20542 |        20 |       542 | Taniche                  | Oaxaca                          | Pacífico Sur            | V        | Costa de Oaxaca |         11 | 2008-10-31  | Sin sequia |
|             20367 |        20 |       367 | Santa Catarina Mechoacán | Oaxaca                          | Pacífico Sur            | V        | Costa de Oaxaca |         11 | 2004-01-31  | Sin sequia |
|             30141 |        30 |       141 | San Andrés Tuxtla        | Veracruz de Ignacio de la Llave | Golfo Centro            | X        | Rio Papaloapan  |         21 | 2015-08-15  | D1         |
|              1005 |         1 |         5 | Jesús María              | Aguascalientes                  | Lerma Santiago Pacífico | VIII     | Rio Santiago    |         16 | 2011-09-30  | D3         |

A partir de los datos del archivo **`sequia_municipios.csv.bz2`** se crearon dos conjuntos de datos extras

**Rachas de sequía en los municipios**

→ [Descarga el CSV de las rachas de sequía en los municipios de México](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/msm/datos/rachas_sequia_municipios.csv)

Es una manera de obtener la aproximación (en días) de la duración del tipo o la categoría de sequía

|   cve_concatenada | sequia     |   racha | full_date_start_racha   | full_date_end_racha   | racha_dias   |
|------------------:|:-----------|--------:|:------------------------|:----------------------|:-------------|
|             16022 | D3         |       1 | 2009-08-31              | 2009-08-31            | 0 days       |
|             29037 | Sin sequia |       1 | 2020-05-15              | 2020-05-15            | 0 days       |
|             20569 | Sin sequia |      11 | 2003-09-30              | 2004-08-31            | 336 days     |
|             21104 | D1         |       2 | 2011-04-30              | 2011-05-31            | 31 days      |
|             20334 | Sin sequia |      18 | 2009-09-30              | 2011-02-28            | 516 days     |


**Racha máxima de sequía en los municipios**

→ [Descarga el CSV de las rachas máximas de sequía en los municipios de México](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/msm/datos/max_rachas_sequia_municipios.csv)

Este conjunto de datos únicamente cuenta con las rachas de cada tipo de sequía más grandes de la historia de la base de datos

|   cve_concatenada | sequia     |   racha | full_date_start_racha   | full_date_end_racha   | racha_dias   |
|------------------:|:-----------|--------:|:------------------------|:----------------------|:-------------|
|             30080 | D1         |      13 | 2019-10-31              | 2020-04-30            | 182 days     |
|             12039 | Sin sequia |      16 | 2009-11-30              | 2011-02-28            | 455 days     |
|             30096 | D1         |       7 | 2004-11-30              | 2005-05-31            | 182 days     |
|             21073 | D2         |       7 | 2003-01-31              | 2003-07-31            | 181 days     |
|             32055 | D2         |       4 | 2021-04-30              | 2021-06-15            | 46 days      |


## Proyecciones de Población: País, Estados y Municipios

> [!NOTE]  
>  Datos tomados de la CONAPO. De existir nuevas ediciones, se actualizarán los datos

A partir de los datos publicados por la Comisión Nacional de Población 
se crearon 4 conjuntos de datos:

---

**Proyección de población de los estados y la nación: división por género y división por edad**

→ [Descarga el CSV de proyección de población de los estados y la nación: división por género y división por edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_ent_gender_age_1950_2070.csv)

| n_year | nombre_estado       | cve_ent | edad | genero  | pob_start_year | pob_mid_year |
|-------:|:--------------------|--------:|-----:|:--------|---------------:|-------------:|
|   1992 | Chihuahua           |      08 |   37 | Mujeres |          14532 |        14905 |
|   2062 | Guanajuato          |      11 |   28 | Hombres |          41364 |        41154 |
|   1990 | Baja California Sur |      03 |   32 | Mujeres |           2346 |         2407 |
|   1986 | Coahuila            |      05 |   61 | Hombres |           3718 |         3792 |
|   1985 | Aguascalientes      |      01 |   24 | Mujeres |           5327 |         5473 |

**Proyección de población de los estados y la nación: división por género y unión de edad**

→ [Descarga el CSV de proyección de población de los estados y la nación: división por género y unión de edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_ent_gender_1950_2070.csv)

| n_year | nombre_estado   | cve_ent | genero  | pob_start_year | pob_mid_year |
|-------:|:----------------|--------:|:--------|---------------:|-------------:|
|   1990 | Nacional        |      00 | Mujeres |       42231778 |     42648349 |
|   2049 | Querétaro       |      22 | Hombres |        1686191 |      1690779 |
|   2023 | Oaxaca          |      20 | Total   |        4260710 |      4276769 |
|   2007 | San Luis Potosí |      24 | Hombres |        1235204 |      1241918 |
|   2014 | Yucatán         |      31 | Mujeres |        1066091 |      1073334 |

---

**Proyección de población de los municipios: división por género y división por edad**

→ [Descarga el CSV de proyección de población de los municipios: división por género y división por edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_mun_gender_age_2015_2030.csv)


| n_year | nombre_estado    | cve_ent | nombre_municipio          | cve_mun | rango_edad | genero  | pob_mid_year |
|-------:|:-----------------|--------:|:--------------------------|--------:|:-----------|:--------|-------------:|
|   2020 | Oaxaca           |      20 | Villa Hidalgo             |   20038 | Age65_more | Hombres |          109 |
|   2020 | Veracruz         |      30 | Isla                      |   30077 | Age60_64   | Mujeres |          851 |
|   2023 | Sonora           |      26 | Pitiquito                 |   26047 | Age40_44   | Hombres |          367 |
|   2023 | Oaxaca           |      20 | Villa Tejúpam de la Unión |   20486 | Age10_14   | Mujeres |           99 |
|   2020 | Estado de México |      15 | Temoaya                   |   15087 | Age20_24   | Hombres |         4935 |


**Proyección de población de los municipios: división por género y unión de edad**

→ [Descarga el CSV de proyección de población de los municipios: división por género y unión de edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_mun_gender_2015_2030.csv)


| n_year | nombre_estado   | cve_ent | nombre_municipio       | cve_mun | genero  | pob_mid_year |
|-------:|:----------------|--------:|:-----------------------|--------:|:--------|-------------:|
|   2025 | Morelos         |      17 | Cuautla                |   17006 | Total   |       219233 |
|   2023 | Oaxaca          |      20 | Santa María Chilchotla |   20406 | Hombres |        10339 |
|   2027 | San Luis Potosí |      24 | Santo Domingo          |   24033 | Total   |        13233 |
|   2018 | Campeche        |      04 | Campeche               |   04002 | Mujeres |       158667 |
|   2017 | Chihuahua       |      08 | Batopilas              |   08008 | Hombres |         6548 |