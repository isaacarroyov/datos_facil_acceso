# Datos del Gobierno de México

En este espacio se encuentran datos relacionados al Gobierno de México, 
tales como encuestas, _shapefiles_ de la división política de Estados y 
Municipios, encuestas, medio ambiente, entre otros.

## Códigos y nombres de los Estados 

> [!NOTE]
> Datos tomados del Marco Geoestadístico 2022, de haber un cambio en el Marco Geoestadístico 2023, se actualizará

→ [Descarga el archivo de relación Código-Nombre de las entidades](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/cve_nom_estados.csv)

| nombre_estado    |   cve_ent |
|:-----------------|----------:|
| Colima           |        06 |
| Ciudad de México |        09 |
| Michoacán        |        16 |


## Códigos y nombres de los Municipios 

> [!NOTE]
> Datos tomados del Marco Geoestadístico 2022, de haber un cambio en el Marco Geoestadístico 2023, se actualizará

→ [Descarga el archivo de relación Código-Nombre de los municipios](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/cve_nom_municipios.csv)

| nombre_estado   |   cve_ent | nombre_municipio          |   cve_mun |
|:----------------|----------:|:--------------------------|----------:|
| Oaxaca          |        20 | Teotitlán de Flores Magón |     20545 |
| Veracruz        |        30 | Jáltipan                  |     30089 |
| San Luis Potosí |        24 | Tampamolón Corona         |     24039 |


## Geometrías de estados y municipios

> [!NOTE]
> Datos tomados del Marco Geoestadístico 2022, de haber un cambio en el Marco Geoestadístico 2023, se actualizará

→ [Descarga el GeoJSON de las geometrías del los **estados** de México](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/geometrias/00ent_mexico.geojson)

→ [Descarga el GeoJSON de las geometrías del los **municipios** de México](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/geometrias/00mun_simplified-t005-geopandas.geojson)


## INEGI

### Censo de Población y Vivienda


**Resultados generales por entidad federativa**
<!-- TODO: Descripcion y descarga de los archivos de MSM -->

**Resultados por AGEBS (por entidad y nacional)**
<!-- TODO: Descripcion y descarga de los archivos de MSM -->


## Medio ambiente

### Monitor de Sequía de México

> [!NOTE]  
>  Datos tomados del Monitor de Sequía de Mexico (MSM), CONAGUA. Estos datos son actualizados de manera quincenal en la página oficial.

**Sequía en los municipios (registros)**
<!-- TODO: Descripcion y descarga de los archivos de MSM -->

**Rachas de sequía en los municipios**
<!-- TODO: Descripcion y descarga de los archivos de MSM -->

**Racha máxima de sequía en los municipios**
<!-- TODO: Descripcion y descarga de los archivos de MSM -->

## Proyecciones de Población: País, Estados y Municipios

> [!NOTE]  
>  Datos tomados de la CONAPO. De existir nuevas ediciones, se actualizarán los datos

A partir de los datos publicados por la Comisión Nacional de Población 
se crearon 4 conjuntos de datos:

---

**Proyección de población de los estados y la nación: división por género y división por edad**

→ [Descarga el archivo de proyección de población de los estados y la nación: división por género y división por edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_ent_gender_age_1950_2070.csv)

| n_year | nombre_estado       | cve_ent | edad | genero  | pob_start_year | pob_mid_year |
|-------:|:--------------------|--------:|-----:|:--------|---------------:|-------------:|
|   1992 | Chihuahua           |      08 |   37 | Mujeres |          14532 |        14905 |
|   2062 | Guanajuato          |      11 |   28 | Hombres |          41364 |        41154 |
|   1990 | Baja California Sur |      03 |   32 | Mujeres |           2346 |         2407 |
|   1986 | Coahuila            |      05 |   61 | Hombres |           3718 |         3792 |
|   1985 | Aguascalientes      |      01 |   24 | Mujeres |           5327 |         5473 |

**Proyección de población de los estados y la nación: división por género y unión de edad**

→ [Descarga el archivo de proyección de población de los estados y la nación: división por género y unión de edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_ent_gender_1950_2070.csv)

| n_year | nombre_estado   | cve_ent | genero  | pob_start_year | pob_mid_year |
|-------:|:----------------|--------:|:--------|---------------:|-------------:|
|   1990 | Nacional        |      00 | Mujeres |       42231778 |     42648349 |
|   2049 | Querétaro       |      22 | Hombres |        1686191 |      1690779 |
|   2023 | Oaxaca          |      20 | Total   |        4260710 |      4276769 |
|   2007 | San Luis Potosí |      24 | Hombres |        1235204 |      1241918 |
|   2014 | Yucatán         |      31 | Mujeres |        1066091 |      1073334 |

---

**Proyección de población de los municipios: división por género y división por edad**

→ [Descarga el archivo de proyección de población de los municipios: división por género y división por edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_mun_gender_age_2015_2030.csv)


| n_year | nombre_estado    | cve_ent | nombre_municipio          | cve_mun | rango_edad | genero  | pob_mid_year |
|-------:|:-----------------|--------:|:--------------------------|--------:|:-----------|:--------|-------------:|
|   2020 | Oaxaca           |      20 | Villa Hidalgo             |   20038 | Age65_more | Hombres |          109 |
|   2020 | Veracruz         |      30 | Isla                      |   30077 | Age60_64   | Mujeres |          851 |
|   2023 | Sonora           |      26 | Pitiquito                 |   26047 | Age40_44   | Hombres |          367 |
|   2023 | Oaxaca           |      20 | Villa Tejúpam de la Unión |   20486 | Age10_14   | Mujeres |           99 |
|   2020 | Estado de México |      15 | Temoaya                   |   15087 | Age20_24   | Hombres |         4935 |


**Proyección de población de los municipios: división por género y unión de edad**

→ [Descarga el archivo de proyección de población de los municipios: división por género y unión de edad](https://raw.githubusercontent.com/isaacarroyov/datos_facil_acceso/main/GobiernoMexicano/conapo_proyecciones/conapo_pob_mun_gender_2015_2030.csv)


| n_year | nombre_estado   | cve_ent | nombre_municipio       | cve_mun | genero  | pob_mid_year |
|-------:|:----------------|--------:|:-----------------------|--------:|:--------|-------------:|
|   2025 | Morelos         |      17 | Cuautla                |   17006 | Total   |       219233 |
|   2023 | Oaxaca          |      20 | Santa María Chilchotla |   20406 | Hombres |        10339 |
|   2027 | San Luis Potosí |      24 | Santo Domingo          |   24033 | Total   |        13233 |
|   2018 | Campeche        |      04 | Campeche               |   04002 | Mujeres |       158667 |
|   2017 | Chihuahua       |      08 | Batopilas              |   08008 | Hombres |         6548 |