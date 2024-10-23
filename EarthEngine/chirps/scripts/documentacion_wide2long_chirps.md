# CHIRPS: Extracción y procesamiento de datos de lluvia II


- [<span class="toc-section-number">1</span> Introducción y objetivos](#introducción-y-objetivos)
- [<span class="toc-section-number">2</span> Los conjuntos de datos](#los-conjuntos-de-datos)
  - [<span class="toc-section-number">2.1</span> Ubicación de los archivos](#ubicación-de-los-archivos)
  - [<span class="toc-section-number">2.2</span> Carga de los archivos](#carga-de-los-archivos)
  - [<span class="toc-section-number">2.3</span> Decisiones sobre los datos](#decisiones-sobre-los-datos)
- [<span class="toc-section-number">3</span> *Wide to Long*](#wide-to-long)
- [<span class="toc-section-number">4</span> Precipitación normal (1981 - 2010)](#precipitación-normal-1981---2010)
- [<span class="toc-section-number">5</span> Cálculo de anomalías](#cálculo-de-anomalías)
  - [<span class="toc-section-number">5.1</span> Anomalía en milimetros](#anomalía-en-milimetros)
  - [<span class="toc-section-number">5.2</span> Anomalía en porcentaje](#anomalía-en-porcentaje)
  - [<span class="toc-section-number">5.3</span> Función para cálculo de anomalías](#función-para-cálculo-de-anomalías)
- [<span class="toc-section-number">6</span> Detalles finales](#detalles-finales)
  - [<span class="toc-section-number">6.1</span> Adjuntar nombre de estados y municipios](#adjuntar-nombre-de-estados-y-municipios)
  - [<span class="toc-section-number">6.2</span> Formato numérico y de fecha para periodos](#formato-numérico-y-de-fecha-para-periodos)
  - [<span class="toc-section-number">6.3</span> Creación de bases de datos de métricas de precipitación](#creación-de-bases-de-datos-de-métricas-de-precipitación)
- [<span class="toc-section-number">7</span> Guardar bases de datos de métricas de precipitación](#guardar-bases-de-datos-de-métricas-de-precipitación)
  - [<span class="toc-section-number">7.1</span> Estados](#estados)
  - [<span class="toc-section-number">7.2</span> Municipios](#municipios)
  - [<span class="toc-section-number">7.3</span> Precipitaciones normales](#precipitaciones-normales)

> \[!NOTE\]
>
> Se puede observar que se cambia el directorio de trabajo a la carpeta **`/EarthEngine/chirps/scripts`** para después agregar `/../../..` en la variable **`path2main`**. Este cambio se hace para que al renderizar, el código se pueda ejecutar correctamente, ya que el archivo toma como directorio de trabajo la carpeta en la que se encuentra el script en el que se esta haciendo el código.

``` r
setwd("./EarthEngine/chirps/scripts")
```

## Introducción y objetivos

La extracción de la **precipitación en milímetros (mm)** fue a través de Google Earth Engine. El periodo de extracción de los datos fue de 44 años, iniciando en 1981 hasta 2024. En total se tienen 352 archivos CSV en la carpeta **`EarthEngine/chirps/data/ee_imports`**

| **Tipo de archivo CSV** | **Número de archivos** |
|----|----|
| Precipitación anual de los estados | 1 archivo por cada año :arrow_right: 44 archivos |
| Precipitación mensual de los estados | 1 archivo por cada año :arrow_right: 44 archivos |
| Precipitación semanal de los estados | 1 archivo por cada año :arrow_right: 44 archivos |
| Precipitación diaria de los estados | 1 archivo por cada año :arrow_right: 44 archivos |
| Precipitación anual de los municipios | 1 archivo por cada año :arrow_right: 44 archivos |
| Precipitación mensual de los municipios | 1 archivo por cada año :arrow_right: 44 archivos |
| Precipitación semanal de los municipios | 1 archivo por cada año :arrow_right: 44 archivos |
| Precipitación diaria de los municipios | 1 archivo por cada año :arrow_right: 44 archivos |

El siguiente paso es poder unir todo en 8 archivos

- Anual: Precipitación en milímetros, anomalía \[de precipitación\] en milímetros (con respecto de la normal) y anomalía en porcentaje de los estados, de 1981 a 2024.
- Mensual: Precipitación en milímetros, anomalía en milímetros y anomalía en porcentaje de los estados, de 1981 a 2024.
- Semanal: Precipitación en milímetros, anomalía en milímetros y anomalía en porcentaje de los estados, de 1981 a 2024.
- Diaria: Precipitación en milímetros, anomalía en milímetros y anomalía en porcentaje de los estados, de 1981 a 2024.
- Anual: Precipitación en milímetros, anomalía en milímetros y anomalía en porcentaje de los municipios, de 1981 a 2024.
- Mensual: Precipitación en milímetros, anomalía en milímetros y anomalía en porcentaje de los municipios, de 1981 a 2024.
- Semanal: Precipitación en milímetros, anomalía en milímetros y anomalía en porcentaje de los municipios, de 1981 a 2024.
- Diaria: Precipitación en milímetros, anomalía en milímetros y anomalía en porcentaje de los municipios, de 1981 a 2024.

``` r
Sys.setlocale(locale = "es_ES")
library(tidyverse)

path2main <- paste0(getwd(), "/../../..")
path2ee <- paste0(path2main, "/EarthEngine")
path2chirps <- paste0(path2ee, "/chirps")
path2data <- paste0(path2chirps, "/data")
```

## Los conjuntos de datos

### Ubicación de los archivos

Todos los archivos se encuentran en una misma carpeta, lo que los distingue es el nombre del archivo. El nombre tiene la estructura de `chirps_pr_mm_GEOMETRIA_PERIODO_AAAA.csv`, donde:

- `GEOMETRIA`: Indica las geometrías de la información, tales como `ent` (Estados) y `mun` (Municipios).
- `PERIODO`: Tiene los valores de los periodos de extracción, tales como `year` (anual), `month` (mensual), `week` (semanala) y `day` (diaria).
- `AAAA`: Indica el año de la información, de 1981 a 2024.

Para dividir en 8 grupos a todos los archivos, se usarán 2 partes del nombre: `_GEOMETRIA_PERIODO_`

``` r
# Obtener el nombre (path incluido) de todos los archivos que se 
# importaron de Google Earth Engine 
all_csv_chirps <- list.files(
    path = paste0(path2data, "/ee_imports"),
    pattern = "*.csv",
    full.names = TRUE)

# - - Entidades - - #
# ~ Diario ~ #
idx_ent_day <- str_detect(all_csv_chirps, "_ent_day_")
# ~ Semanal ~ #
idx_ent_week <- str_detect(all_csv_chirps, "_ent_week_")
# ~ Mensual ~ #
idx_ent_month <- str_detect(all_csv_chirps, "_ent_month_")
# ~ Anual ~ #
idx_ent_year <- str_detect(all_csv_chirps, "_ent_year_")

# - - Municipios - - #
# ~ Diario ~ #
idx_mun_day <- str_detect(all_csv_chirps, "_mun_day_")
# ~ Semanal ~ #
idx_mun_week <- str_detect(all_csv_chirps, "_mun_week_")
# ~ Mensual ~ #
idx_mun_month <- str_detect(all_csv_chirps, "_mun_month_")
# ~ Anual ~ #
idx_mun_year <- str_detect(all_csv_chirps, "_mun_year_")
```

Las variables `idx_` son vectores booleanos que indican la posición en la que se encuentra un archivo que coincide con el patron de caracteres deseado. Cada uno de esos vectores tiene 44 elementos, los cuales tienen que ser leeidos como `tibbles` y concatenados. De esta manera se tiene en un `tibble`, la información de 44 años de precipitación (divididos semanal, mensual o anualmente).

### Carga de los archivos

Para poder leer y unir 44 archivos en uno solo, se usa `purrr::map`. `purrr` es una librería que forma parte del `{tidyverse}`, por lo que ya se encuentra cargada en el ambiante. Con `map` se leeran los paths de los archivos de interés (dados por `idx_`).

``` r
# - - Entidades - - #
# ~ Anual ~ #
chirps_ent_year <- map(
    .x = all_csv_chirps[idx_ent_year],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean)

# ~ Mensual ~ #
chirps_ent_month <- map(
    .x = all_csv_chirps[idx_ent_month],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Semanal ~ #
chirps_ent_week <- map(
    .x = all_csv_chirps[idx_ent_week],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>% 
  bind_rows() %>% 
  janitor::clean_names() %>% 
  select(c(cvegeo, n_year, starts_with("x"))) 

# ~ Diario ~ #
chirps_ent_day <- map(
    .x = all_csv_chirps[idx_ent_day],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_cols() %>%
  janitor::clean_names() %>%
  select(c(tidyselect::starts_with("cvegeo"),
           tidyselect::starts_with("x")))

# - - Municipios - - #
# ~ Anual ~ #
chirps_mun_year <- map(
    .x = all_csv_chirps[idx_mun_year],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(cvegeo, n_year, mean)

# ~ Mensual ~ #
chirps_mun_month <- map(
    .x = all_csv_chirps[idx_mun_month],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Semanal ~ #
chirps_mun_week <- map(
    .x = all_csv_chirps[idx_mun_week],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_rows() %>%
  janitor::clean_names() %>%
  select(c(cvegeo, n_year, starts_with("x")))

# ~ Diario ~ #
chirps_mun_day <- map(
    .x = all_csv_chirps[idx_mun_day],
    .f = \(x) read_csv(file = x, col_types = cols(.default = "c"))) %>%
  bind_cols() %>% 
  janitor::clean_names() %>%
  select(c(tidyselect::starts_with("cvegeo"),
           tidyselect::starts_with("x")))
```

Línea 4  
Seleccionar los paths de los archivos de interes

Línea 5  
Usar una función anónima para poder dar valor a más argumentos (como que todas las columnas sean leídas como *strings*) de la función `read_csv`

Línea 6  
Todos los `tibbles` se guardan en una lista, por lo que para unirlos en un solo `tibble` se concatenan por las filas

Línea 7  
Limpieza de nombres de columnas

Línea 8  
**Caso del periodo anual**: Las columnas de interés son las que tienen código de estado o municipio (`cvegeo`), el año de la información (`n_year`) y el nombre de la columna de información (`mean`)

Línea 16  
Las columnas de interés son las que tienen el código del estado o municipio (`cvegeo`), el año de la información (`n_year`) y el número de semana o mes (después de usar `janitor::clean_names`, todas inician con `x`).

Línea 30  
**Caso del periodo diario**: Cada columna es un día del año, por lo que usar `dplyr::bind_rows()` no es de utilidad porque cada año habrá un gran espacio de columnas vacias, así que se usa `dplyr::bind_cols()`

Líneas 32-33  
**Caso del periodo diario**: Como se repite mucho la columna `cvegeo`, entonces se seleccionan todas las que incian así. Más adelante en el procesamiento de datos se arregla este *detalle* **Muestra de datos: Precipitación en milímetros anual a nivel estatal**

| cvegeo | n_year | mean               |
|:-------|:-------|:-------------------|
| 25     | 2012   | 715.0737995472939  |
| 07     | 2002   | 1890.8175706313602 |
| 01     | 1985   | 554.5302252346366  |
| 02     | 2010   | 161.18254985392224 |
| 23     | 1995   | 1452.6002760836577 |

**Muestra de datos: Precipitación en milímetros mensual a nivel estatal**

| cvegeo | n_year | x01 | x02 | x03 | x04 | x05 | x06 | x07 | x08 | x09 | x10 | x11 | x12 |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 25 | 2012 | 8.002081910771784 | 9.078194131860103 | 4.245432148995365 | 0.8111924063024587 | 0.4805014698503636 | 45.82847035007077 | 190.1685423222091 | 231.22429026141032 | 130.50970281837 | 44.509617813780174 | 7.114725168627959 | 43.10104874504511 |
| 07 | 2002 | 38.99664121905262 | 66.95147406500753 | 33.7011112511111 | 25.343206725032886 | 118.42358376104104 | 322.695395564078 | 238.40081035341217 | 232.71763032382583 | 445.5615337497574 | 190.59085202793733 | 123.0281351469849 | 54.407196444117 |
| 01 | 1985 | 9.558769440008394 | 3.828289024647326 | 4.465417296415644 | 8.787392602874972 | 20.101997511422404 | 152.7658437224622 | 115.62645598316148 | 96.1548473553145 | 58.1832005744891 | 58.2982545575875 | 7.853042337757421 | 18.906714828495836 |
| 02 | 2010 | 38.997024648851976 | 28.909910132917226 | 21.02283924106932 | 12.614580033601074 | 0.3671345100617597 | 0.013355120032271831 | 2.093100650098661 | 5.015776877602795 | 4.319623976839639 | 12.638956789333117 | 6.912177347959977 | 28.278070525554362 |
| 23 | 1995 | 35.742715619401295 | 18.74646313623549 | 37.483081691824644 | 57.27765378589855 | 47.082283174239876 | 195.79054514766395 | 173.8629484484224 | 154.99552701213273 | 286.91104010818935 | 306.97029565648137 | 52.00130581192142 | 85.7364164912458 |

**Muestra de datos: Precipitación en milímetros semanal a nivel estatal**

| cvegeo | n_year | x01 | x02 | x03 | x04 | x05 | x06 | x07 | x08 | x09 | x10 | x11 | x12 | x13 | x14 | x15 | x16 | x17 | x18 | x19 | x20 | x21 | x22 | x23 | x24 | x25 | x26 | x27 | x28 | x29 | x30 | x31 | x32 | x33 | x34 | x35 | x36 | x37 | x38 | x39 | x40 | x41 | x42 | x43 | x44 | x45 | x46 | x47 | x48 | x49 | x50 | x51 | x52 |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 25 | 2012 | 4.565119851369261 | 2.431284281476585 | 5.4206302279657335 | 0.1213121933088649 | 5.761660988685486 | 1.2641278096247275 | 0.9163800769911142 | 0.9302300897001377 | 0.24481883126321458 | 0.263559384222404 | 3.6340719212420187 | 0.02554890485921055 | 0.28519381299985236 | 0.004624147604255918 | 0.009254301068574222 | 0.0 | 0.7900718105801949 | 0.4794069928332775 | 0.0 | 1.626634906662983E-5 | 0.006271497737045376 | 0.2824222825831337 | 1.9386215478163447 | 0.050564212386888 | 19.008122317651942 | 28.630367112570198 | 31.104090252919946 | 42.38800650664616 | 55.97136024230213 | 44.20788540995156 | 44.90875517108719 | 31.230245924206713 | 65.93829637017426 | 59.11651419175208 | 55.970084537497115 | 33.26069276719733 | 25.533819688021808 | 2.5716905103805443 | 55.61955002816251 | 0.03847333819913828 | 0.003508765872641792 | 44.46655417598047 | 3.339489864292791E-4 | 0.3134919905269784 | 0.2486126601861145 | 2.543442548857407 | 2.1568731336581384 | 1.8530574443711718 | 0.49149287057958935 | 25.02013912628581 | 0.977838668423643 | 12.075308412177012 |
| 07 | 2002 | 12.793817911098213 | 1.3815447731872958 | 7.124696197193321 | 18.602662174449925 | 12.759397565635686 | 4.086040963988357 | 8.410704626857145 | 37.912541429406645 | 4.998323010903791 | 11.560260342948096 | 4.067205675381982 | 10.769731508934703 | 6.218669611910267 | 0.5915940588118281 | 15.258941393073428 | 3.7575223044917334 | 5.349707831364975 | 4.828163221152684 | 5.233509928806056 | 69.23379984003057 | 12.420337073049835 | 38.23829298308863 | 97.72532643985173 | 80.48306067204636 | 66.81964634331725 | 66.52228396106709 | 46.77729253649441 | 78.04424682793308 | 44.918380817949696 | 47.162778994124785 | 44.254005199877554 | 34.395192561796094 | 44.38394363757085 | 54.49279334819513 | 87.91058749297767 | 109.99543404724344 | 98.29569387218791 | 69.27224611284332 | 150.03619721498706 | 79.38089183619876 | 30.13503579027676 | 13.495656730633172 | 26.045275071858587 | 86.17849002929835 | 51.90952728780011 | 31.53348261348191 | 0.5523658504964503 | 1.8957018436957638 | 18.174746238091302 | 4.856727470424114 | 6.441623174909765 | 23.131472187965123 |
| 01 | 1985 | 0.0 | 5.14541487921937 | 4.4121658504324355 | 0.0011887103565890824 | 0.0 | 0.0 | 0.0 | 0.9914186637083253 | 3.1619027815235277 | 0.09586024122803993 | 0.3210843609872138 | 1.2025894312444305 | 2.5208508423714333 | 1.851751801255585 | 2.6823242367349587 | 2.5696308264686194 | 1.6836857384158033 | 4.763246826938254 | 0.0 | 9.859925975586302 | 0.0 | 5.47882470889785 | 7.562515204940493 | 31.233267745451563 | 61.063169119723334 | 52.90689165234678 | 21.423002813640924 | 7.880593591097238 | 38.8505248835429 | 44.524141744369835 | 3.7942245449045124 | 53.63455756407039 | 39.00955706723383 | 1.4253086078368862 | 1.2393925217795119 | 19.950302656321497 | 1.3032207609818638 | 15.728595124554907 | 21.201082032630833 | 0.8249636685561208 | 9.270193476544629 | 37.39243870221529 | 10.810658710271483 | 0.0 | 0.0 | 4.751674813267223 | 3.036389249174764 | 0.06497827531543326 | 0.41158457542797955 | 1.4078196875247024 | 15.964445381381061 | 1.1228651841621042 |
| 02 | 2010 | 1.9234826105182075 | 18.806963305920988 | 15.176532243481745 | 3.088311651409663 | 8.687033055145049 | 3.8318216222165202 | 4.974621463075098 | 11.41643399248055 | 5.267677654519688 | 0.134330599866299 | 0.05617161383006334 | 15.047256461015015 | 0.8981995948951141 | 0.051688874135377295 | 8.12814449723564 | 3.927576600184197 | 0.12739625661313309 | 0.300872007051824 | 5.38084120130311E-4 | 0.06470154126567397 | 0.0 | 0.0064849348079542585 | 0.006870185224317572 | 0.0 | 0.0 | 0.0 | 0.006102267253815537 | 1.6003847263482847 | 0.050768022155244286 | 0.4589995674883728 | 0.6085123147220911 | 1.0466692660982186 | 1.6523932084688542 | 1.6849780703411574 | 0.130302790694676 | 0.1362806553408633 | 0.0012256271053264797 | 0.11463499178661515 | 8.326438251888472 | 0.18632934999196069 | 2.6517624600363128 | 4.263082623856072 | 1.148594100297875 | 0.03767431178188882 | 0.4041329373370472 | 4.748995279936645 | 1.721374818904396 | 0.4881504613266949 | 0.5442033504683819 | 1.0074194730446178 | 17.606225063894065 | 8.632072176820591 |
| 23 | 1995 | 9.25610456414677 | 10.100362432267788 | 2.732679361223756 | 4.21118427909037 | 10.815287766957718 | 4.978627073364706 | 5.5849063784016115 | 3.9770788151775776 | 0.6453764185037915 | 13.177291226110214 | 23.41794131042425 | 0.21894824706289254 | 1.5212314245601037 | 7.73397632046501 | 7.487236778713087 | 0.06403140071267302 | 40.49470235117114 | 19.58658912535048 | 0.9475773563690251 | 11.690730264695707 | 13.95156112667253 | 29.379324687886946 | 27.138488422890955 | 51.28645941203528 | 88.09967761758325 | 9.307344299411309 | 71.95186016980887 | 35.87520792551464 | 24.99772408669302 | 31.357588854016466 | 51.75434844304416 | 64.11827293957667 | 15.030641209512877 | 18.115641574052628 | 17.310369046315543 | 68.27755087336465 | 38.12730374586678 | 34.525751648748766 | 152.60132880586426 | 25.850839977131553 | 176.1129790975521 | 48.80433736747758 | 25.234458220873478 | 27.808983156272912 | 4.854428971750183 | 6.5473378113982275 | 1.637661144757836 | 44.45769825535917 | 2.5027376751703834 | 41.28056403351152 | 10.7118067276847 | 14.948135861088693 |

**Muestra de datos: Precipitación en milímetros diario a nivel estatal**

| cvegeo_367 | cvegeo_2223 | x20240820_precipitation | x20240821_precipitation | x20240822_precipitation | x20240823_precipitation | x20240824_precipitation | x20240825_precipitation | x20240826_precipitation | x20240827_precipitation | x20240828_precipitation | x20240829_precipitation |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 25 | 25 | 10.600595832626844 | 1.5173912877529463 | 3.3442393113414433 | 6.861319390122767 | 6.78269099367056 | 2.9051734543862544 | 3.6776144691156936 | 4.938404817130739 | 4.072720046107506 | 3.2810954481484753 |
| 04 | 04 | 3.020264200050022 | 14.081583258921738 | 2.260947987468791 | 1.5111945170621315 | 3.832963515540293 | 19.787970580198685 | 6.1303048072621324 | 9.887745153871434 | 4.549253322296866 | 8.61227377266913 |
| 07 | 07 | 3.6771083593793192 | 9.506978003057958 | 15.03085190323926 | 13.714052025196136 | 8.325976040743944 | 11.594982863200686 | 8.127878963838132 | 10.297131407974554 | 6.27835144627146 | 7.0043849940831455 |
| 01 | 01 | 2.001342988383354 | 1.6299983583402162 | 0.9499606263852854 | 1.2942102052123752 | 2.3017478721051576 | 4.78123634879177 | 0.699373376829762 | 0.5937779169500021 | 0.6206872634400437 | 1.6289012974095025 |
| 02 | 02 | 0.6881991251495991 | 0.5063587460329287 | 0.7493756644034139 | 0.04706532491422096 | 0.13453642653738673 | 0.08424679197631525 | 0.08439725078107171 | 0.09560977453566492 | 0.2680227704345072 | 0.25226822420904615 |

### Decisiones sobre los datos

> \[!NOTE\]
>
> Como lo indican los objetivos, no solo estará la Precipitación (mm), también se contará con las anomalías, por lo que se tendrá que incorporar este cálculo en el flujo de trabajo.
>
> Esta es una solución temporal, en lo que se arregla el código de la extracción de las anomalías directamente de Google Earth Engine.

1.  Transformar el formato *wide* a *long*, para tener el número de semanas y meses como una columna. Para el caso de los datos anuales, únicamente renombrar la columna `mean` a `pr`
2.  Cambiar a número el valor de la precipitación.
3.  Crear los respectivos `tibble`s de promedio normal de precipitación para cada uno de los archivos.
4.  Crear las columnas de las anomalías de precipitación en milímetros (`anomaly_pr_mm`) y porcentaje (`anomaly_pr_prop`).

## *Wide to Long*

Para facilitar la transformación se va crear una función que haga el pivote dependiendo del número de columnas en el `tibble`.

``` r
func_wide2long <- function(df, periodo) {
  
  if (periodo %in% c("day", "week", "month")) {
    df_pivoted <- df %>%
      pivot_longer(
        cols = starts_with("x"),
        names_to = "period",
        values_to = "pr_mm") %>%
      mutate(
        pr_mm = as.numeric(pr_mm),
        period = str_remove_all(
          string = period,
          pattern = "x|_precipitation"))
    
    if(periodo == "day") {
      df_transformed <- rename(.data = df_pivoted,
                               full_date = period)
    } else if (periodo == "week") {
      df_transformed <- rename(.data = df_pivoted,
                               n_week = period)
    } else {
      df_transformed <- rename(.data = df_pivoted,
                               n_month = period)}
  } else {
    df_transformed <- df %>%
      rename(pr_mm = mean) %>%
      mutate(pr_mm = as.numeric(pr_mm))}

  return(df_transformed)}
```

Líneas 3-8  
Si el periodo es diario, semanal o mensual se usa `pivot_longer`

Líneas 9-13  
Se cambia el valor de la precipitación a numérico y se eliminan las `x` + `_precipitation` del número de los días, semanas y meses.

Líneas 15-17,19-20,22-23  
Se renombra dependiendo del tipo de periodo

Líneas 24-27  
Si `df` no es de más de 4 columnas, es porque el periodo es anual y solamente se renombra la columna `mean` a `pr_mm` y se comvierte a valor numérico

Línea 29  
Se regresa el conjunto de datos con los cambios

``` r
# - - Estados - - #
chirps_ent_year_long <- func_wide2long(df = chirps_ent_year, periodo = "year")
chirps_ent_month_long <- func_wide2long(df = chirps_ent_month, periodo = "month")
chirps_ent_week_long <- func_wide2long(df = chirps_ent_week, periodo = "week")
chirps_ent_day_long <- func_wide2long(
    df = chirps_ent_day,
    periodo = "day") %>%
  select(1, full_date, pr_mm) %>%
  mutate(full_date = ymd(full_date)) %>%
  rename(cvegeo = cvegeo_367)
                
# - - Municipios - - #
chirps_mun_year_long <- func_wide2long(df = chirps_mun_year, periodo = "year")
chirps_mun_month_long <- func_wide2long(df = chirps_mun_month, periodo = "month")
chirps_mun_week_long <- func_wide2long(df = chirps_mun_week, periodo = "week")
chirps_mun_day_long <- func_wide2long(
    df = chirps_mun_day,
    periodo = "day") %>%
  select(1, full_date, pr_mm) %>%
  mutate(full_date = ymd(full_date)) %>%
  rename(cvegeo = cvegeo_367)
```

**Muestra de datos de `chirps_mun_week_long`**

| cvegeo | n_year | n_week |     pr_mm |
|:-------|:-------|:-------|----------:|
| 28030  | 2000   | 17     |  9.653540 |
| 14125  | 1998   | 21     |  0.000000 |
| 21009  | 1987   | 46     |  0.000000 |
| 20455  | 2010   | 19     |  5.403203 |
| 20318  | 1991   | 22     | 41.837505 |

## Precipitación normal (1981 - 2010)

Para facilitar el cálculo se va crear una función que la precipitación normal dependiendo del periodo de la información.

``` r
func_normal_pr_mm <- function(df) {
  
  if ("n_week" %in% colnames(df)) {
    df_normal_pr_mm <- df %>%
      filter(n_year %in% 1981:2010) %>%
      group_by(cvegeo, n_week) %>%
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
      ungroup()

  } else if ("n_month" %in% colnames(df)) {
    df_normal_pr_mm <- df %>%
      filter(n_year %in% 1981:2010) %>%
      group_by(cvegeo, n_month) %>%
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
      ungroup()

  } else if ("full_date" %in% colnames(df)){
    df_normal_pr_mm <- df %>%
      filter(year(full_date) %in% 1981:2010) %>%
      group_by(
        cvegeo,
        n_month = month(full_date),
        n_day = day(full_date)) %>%
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
      ungroup()
  } else { 
    df_normal_pr_mm <- df %>%
      filter(n_year %in% 1981:2010) %>%
      group_by(cvegeo) %>%
      summarise(normal_pr_mm = mean(pr_mm, na.rm = TRUE)) %>%
      ungroup()
  }
  
  return(df_normal_pr_mm)}
```

Líneas 3-8  
Filtro de los 30 años *base* y agrupación si `df` es de periodo semanal

Líneas 10-15  
Filtro de los 30 años *base* y agrupación si `df` es de periodo mensual

Líneas 17-25  
Filtro de los 30 años *base* y agrupación si `df` es de periodo diaria

Líneas 27-31  
Filtro de los 30 años *base* y agrupación si `df` es de periodo anual

Línea 34  
Conjunto de valores normales

``` r
# - - Estados - - #
normal_pr_mm_ent_year <- func_normal_pr_mm(df = chirps_ent_year_long)
normal_pr_mm_ent_month <- func_normal_pr_mm(df = chirps_ent_month_long)
normal_pr_mm_ent_week <- func_normal_pr_mm(df = chirps_ent_week_long)
normal_pr_mm_ent_day <- func_normal_pr_mm(df = chirps_ent_day_long)

# - - Municipio - - #
normal_pr_mm_mun_year <- func_normal_pr_mm(df = chirps_mun_year_long)
normal_pr_mm_mun_month <- func_normal_pr_mm(df = chirps_mun_month_long)
normal_pr_mm_mun_week <- func_normal_pr_mm(df = chirps_mun_week_long)
normal_pr_mm_mun_day <- func_normal_pr_mm(df = chirps_mun_day_long)
```

**Muestra de `normal_pr_mm_ent_year`**

| cvegeo | normal_pr_mm |
|:-------|-------------:|
| 25     |     693.6512 |
| 04     |    1329.8219 |
| 07     |    1997.8444 |
| 01     |     529.2339 |
| 02     |     146.5491 |

## Cálculo de anomalías

### Anomalía en milimetros

Es la diferencia en milimetros, de la precipitación de un determinado mes $\left( \overline{x}_{i} \right)$ y el promedio histórico o la normal $\left( \mu_{\text{normal}} \right)$ de ese mes

$$\text{anom}_{\text{mm}} = \overline{x}_{i} - \mu_{\text{normal}}$$

### Anomalía en porcentaje

Es el resultado de dividir la diferencia de la precipitación de un determinado mes $\left( \overline{x}_{i} \right)$ y el promedio histórico o la normal $\left( \mu_{\text{normal}} \right)$ entre la normal de ese mismo mes.

$$\text{anom}_{\text{\%}} = \frac{\overline{x}_{i} - \mu_{\text{normal}}}{\mu_{\text{normal}}}$$

### Función para cálculo de anomalías

La función tomará dos `tibble`s, el de la información de precipitación y el de la precipitación normal.

``` r
func_anomaly_pr <- function(df, df_normal) {

  if ("n_week" %in% colnames(df)) { 
    df_anomaly_pr <- left_join(
        x = df,
        y = df_normal,
        by = join_by(cvegeo, n_week)) %>%
      mutate(
        anomaly_pr_mm = pr_mm - normal_pr_mm,
        anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
      select(-normal_pr_mm)

  } else if ("n_month" %in% colnames(df)) {
    df_anomaly_pr <- left_join(
        x = df,
        y = df_normal,
        by = join_by(cvegeo, n_month)) %>%
      mutate(
        anomaly_pr_mm = pr_mm - normal_pr_mm,
        anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
      select(-normal_pr_mm)

  } else if("full_date" %in% colnames(df)) {
    df_anomaly_pr <- left_join(
        x = df %>%
              mutate(
                n_month = month(full_date),
                n_day = day(full_date)),
        y = df_normal,
        by = join_by(cvegeo, n_month, n_day)) %>%
      mutate(
        anomaly_pr_mm = pr_mm - normal_pr_mm,
        anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
      select(-normal_pr_mm)
    
  } else {
    df_anomaly_pr <- left_join(
      x = df,
      y = df_normal,
      by = join_by(cvegeo)) %>%
    mutate(
      anomaly_pr_mm = pr_mm - normal_pr_mm,
      anomaly_pr_prop = anomaly_pr_mm / normal_pr_mm) %>%
    select(-normal_pr_mm)}
  
  return(df_anomaly_pr)}
```

Líneas 4-7  
Se usa un `lef_join` para unir los datos de precipitación con la precipitación normal. Se unen por región y periodo (este caso, semanal)

Líneas 8-10  
Se hace el cálculo de las anomalías

Línea 11  
Se *elimina* la columna que indica el valor de la precipitación normal

Líneas 13-21  
Proceso 1-3 para periodo mensual

Líneas 23-34  
Proceso 1-3 para periodo diario

Líneas 36-44  
Proceso para periodo anual. Para este caso se une por el periodo, únicamente por la región

Línea 46  
Se regresa el conjunto de datos con las anomalías integradas

``` r
# - - Estados - - #
chirps_ent_year_anomalies <- func_anomaly_pr(
    df = chirps_ent_year_long,
    df_normal = normal_pr_mm_ent_year)

chirps_ent_month_anomalies <- func_anomaly_pr(
    df = chirps_ent_month_long,
    df_normal = normal_pr_mm_ent_month)

chirps_ent_week_anomalies <- func_anomaly_pr(
    df = chirps_ent_week_long,
    df_normal = normal_pr_mm_ent_week)

chirps_ent_day_anomalies <- func_anomaly_pr(
    df = chirps_ent_day_long,
    df_normal = normal_pr_mm_ent_day)

# - - Municipios - - #
chirps_mun_year_anomalies <- func_anomaly_pr(
    df = chirps_mun_year_long,
    df_normal = normal_pr_mm_mun_year)

chirps_mun_month_anomalies <- func_anomaly_pr(
    df = chirps_mun_month_long,
    df_normal = normal_pr_mm_mun_month)

chirps_mun_week_anomalies <- func_anomaly_pr(
    df = chirps_mun_week_long,
    df_normal = normal_pr_mm_mun_week)

chirps_mun_day_anomalies <- func_anomaly_pr(
    df = chirps_mun_day_long,
    df_normal = normal_pr_mm_mun_day)
```

**Muestra de `chirps_mun_month_anomalies`**

| cvegeo | n_year | n_month |     pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:-------|:-------|:--------|----------:|--------------:|----------------:|
| 14117  | 1996   | 01      |  5.359884 |     -6.740752 |      -0.5570577 |
| 13036  | 1985   | 09      | 89.510192 |    -42.149359 |      -0.3201390 |
| 28002  | 2009   | 10      | 66.132091 |    -36.130446 |      -0.3533107 |
| 29022  | 1981   | 09      | 82.381082 |    -55.631325 |      -0.4030893 |
| 20320  | 2002   | 11      | 37.621507 |     11.317534 |       0.4302595 |

## Detalles finales

Como últimos pasos: \* Se agregan los nombres de los estados y municipios \* Para los conjuntos de datos de periodo mensual, se crea una columna en formato de fecha. Para todos los datos, el año, meses y semana se vuelve valor numérico

### Adjuntar nombre de estados y municipios

``` r
db_cve_nom_ent_mun <- read_csv(
    file = paste0(path2main, "/GobiernoMexicano/cve_nom_municipios.csv"))

func_adjuntar_cve_nom_ent_mun <- function(df, region) { 
  
  if (region == "ent") {
    df_con_nombres <- left_join(
        x = df,
        y = distinct(.data = db_cve_nom_ent_mun, cve_ent, nombre_estado),
        by = join_by(cvegeo == cve_ent)) %>%
      rename(cve_ent = cvegeo) %>%
      relocate(nombre_estado, .after = cve_ent)
  } else {
    df_con_nombres <- left_join(
        x = df,
        y = db_cve_nom_ent_mun,
        by = join_by(cvegeo == cve_geo)) %>%
      select(-cve_mun) %>%
      rename(cve_geo = cvegeo) %>%
      relocate(cve_ent, .before = cve_geo) %>%
      relocate(nombre_estado, .after = cve_ent) %>%
      relocate(nombre_municipio, .after = cve_geo)}
  
  return(df_con_nombres)}
```

Líneas 1-2  
Carga de base de datos de nombres y claves de estados y municipios

Líneas 6-12  
Asignación y orden de nombres para estados

Líneas 13-22  
Asignación y orden de nombres para municipios

Línea 24  
Se regresa el conjunto de datos con los nombres de las regiones

### Formato numérico y de fecha para periodos

``` r
func_string2numberdate <- function(df) {
  if ("n_week" %in% colnames(df)) {
    df_detalles_finales <- df %>%
      mutate(
        across(
          .cols = c(n_year, n_week),
          .fns = as.integer))

  } else if ("n_month" %in% colnames(df)) {
    df_detalles_finales <- df %>%
      mutate(date_year_month = paste(n_year, n_month, "15", sep = "-")) %>%
      relocate(date_year_month, .before = n_year) %>%
      mutate(across(.cols = c(n_year, n_month), .fns = as.integer))
  } else {
    df_detalles_finales <- mutate(.data = df, n_year = as.integer(n_year))}
  
  return(df_detalles_finales)}
```

### Creación de bases de datos de métricas de precipitación

``` r
# - - Estados - - #
db_pr_ent_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_year_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_month_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_week <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_week_anomalies,
    region = "ent") %>%
  func_string2numberdate()

db_pr_ent_day <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_ent_day_anomalies,
    region = "ent") %>%
    mutate(n_year = year(full_date)) %>%
    relocate(n_month, .after = n_year) %>%
    relocate(n_day, .after = n_month)

# - - Municipios - - #
db_pr_mun_year <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_year_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_month <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_month_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_week <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_week_anomalies,
    region = "mun") %>%
  func_string2numberdate()

db_pr_mun_day <- func_adjuntar_cve_nom_ent_mun(
    df = chirps_mun_day_anomalies,
    region = "mun") %>%
    mutate(n_year = year(full_date)) %>%
    relocate(n_month, .after = n_year) %>%
    relocate(n_day, .after = n_month)
```

## Guardar bases de datos de métricas de precipitación

En la carpeta de `data` existen 3 carpetas: \* `ee_imports` \* `estados` \* `municipios` \* `normal`

La carpeta `ee_imports` son los archivos creados a partir de Google Earth Engine, y los conjuntos de datos creados por este script, se encuentran en las otras dos carpetas, `estados` y `municipios`

### Estados

**Base de datos de métrias de precipitación anual a nivel estatal**

Se guarda bajo el nombre **`db_pr_ent_year.csv`**

``` r
write_csv(
    x = db_pr_ent_year,
    file = paste0(path2data, "/estados/db_pr_ent_year.csv"),
    na = "")
```

| cve_ent | nombre_estado   | n_year |     pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:--------|:----------------|-------:|----------:|--------------:|----------------:|
| 25      | Sinaloa         |   2012 |  715.0738 |      21.42257 |       0.0308838 |
| 07      | Chiapas         |   2002 | 1890.8176 |    -107.02688 |      -0.0535712 |
| 01      | Aguascalientes  |   1985 |  554.5302 |      25.29634 |       0.0477980 |
| 02      | Baja California |   2010 |  161.1825 |      14.63347 |       0.0998537 |
| 23      | Quintana Roo    |   1995 | 1452.6003 |     167.24272 |       0.1301138 |

**Base de datos de métrias de precipitación mensual a nivel estatal**

Se guarda bajo el nombre **`db_pr_ent_month.csv`**

``` r
write_csv(
    x = db_pr_ent_month,
    file = paste0(path2data, "/estados/db_pr_ent_month.csv"),
    na = "")
```

| cve_ent | nombre_estado | date_year_month | n_year | n_month | pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:---|:---|:---|---:|---:|---:|---:|---:|
| 14 | Jalisco | 1993-11-15 | 1993 | 11 | 17.406663 | 4.436529 | 0.3420573 |
| 14 | Jalisco | 2015-06-15 | 2015 | 6 | 194.864848 | 41.090921 | 0.2672164 |
| 15 | Estado de México | 2008-03-15 | 2008 | 3 | 2.426141 | -5.172940 | -0.6807323 |
| 02 | Baja California | 2003-02-15 | 2003 | 2 | 52.151188 | 24.600239 | 0.8928999 |
| 18 | Nayarit | 1991-06-15 | 1991 | 6 | 96.752522 | -35.131155 | -0.2663799 |

**Base de datos de métrias de precipitación semanal a nivel estatal**

Se guarda bajo el nombre **`db_pr_ent_week.csv`**

``` r
write_csv(
    x = db_pr_ent_week,
    file = paste0(path2data, "/estados/db_pr_ent_week.csv"),
    na = "")
```

| cve_ent | nombre_estado  | n_year | n_week |    pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:--------|:---------------|-------:|-------:|---------:|--------------:|----------------:|
| 21      | Puebla         |   1995 |     52 | 27.18696 |    22.0810199 |       4.3245786 |
| 25      | Sinaloa        |   2016 |     33 | 66.64450 |    23.2708532 |       0.5365206 |
| 01      | Aguascalientes |   2007 |     43 |  3.34919 |    -1.7033558 |      -0.3371282 |
| 27      | Tabasco        |   2022 |     10 | 27.10595 |    13.6523176 |       1.0147684 |
| 31      | Yucatán        |   1987 |     27 | 31.59915 |     0.0490694 |       0.0015553 |

**Base de datos de métrias de precipitación diaria a nivel estatal**

Se guarda bajo el nombre **`db_pr_ent_day.csv`**

``` r
write_csv(
    x = db_pr_ent_day,
    file = paste0(path2data, "/estados/db_pr_ent_day.csv.bz2"),
    na = "")
```

| cve_ent | nombre_estado | full_date | pr_mm | anomaly_pr_mm | anomaly_pr_prop | n_year | n_month | n_day |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|
| 02 | Baja California | 2004-02-08 | 0.0000000 | -2.2562070 | -1.0000000 | 2004 | 2 | 8 |
| 29 | Tlaxcala | 1997-11-17 | 0.0000000 | -0.4540698 | -1.0000000 | 1997 | 11 | 17 |
| 08 | Chihuahua | 2015-12-18 | 0.0908186 | -0.5576279 | -0.8599443 | 2015 | 12 | 18 |
| 28 | Tamaulipas | 1997-02-25 | 0.0000000 | -1.1047876 | -1.0000000 | 1997 | 2 | 25 |
| 21 | Puebla | 2015-11-28 | 5.0997708 | 4.2083085 | 4.7206806 | 2015 | 11 | 28 |

### Municipios

**Base de datos de métrias de precipitación anual a nivel municipal**

Se guarda bajo el nombre **`db_pr_mun_year.csv`**

``` r
write_csv(
    x = db_pr_mun_year,
    file = paste0(path2data, "/municipios/db_pr_mun_year.csv"),
    na = "")
```

| cve_ent | nombre_estado | cve_geo | nombre_municipio | n_year | pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:---|:---|:---|:---|---:|---:|---:|---:|
| 30 | Veracruz | 30108 | Minatitlán | 1990 | 2233.4879 | -536.47491 | -0.1936759 |
| 07 | Chiapas | 07062 | Ostuacán | 2005 | 2826.5362 | -463.78120 | -0.1409533 |
| 20 | Oaxaca | 20089 | San Andrés Dinicuiti | 1998 | 627.0260 | -20.07578 | -0.0310241 |
| 09 | Ciudad de México | 09010 | Álvaro Obregón | 2009 | 962.0613 | -158.41321 | -0.1413805 |
| 21 | Puebla | 21201 | Xochiltepec | 1985 | 857.3468 | 28.84472 | 0.0348155 |

**Base de datos de métrias de precipitación mensual a nivel municipal**

Se guarda bajo el nombre **`db_pr_mun_month.csv.bz2`**

``` r
write_csv(
    x = db_pr_mun_month,
    file = paste0(path2data, "/municipios/db_pr_mun_month.csv.bz2"),
    na = "")
```

| cve_ent | nombre_estado | cve_geo | nombre_municipio | date_year_month | n_year | n_month | pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|
| 14 | Jalisco | 14117 | Cañadas de Obregón | 1996-01-15 | 1996 | 1 | 5.359884 | -6.740752 | -0.5570577 |
| 13 | Hidalgo | 13036 | San Agustín Metzquititlán | 1985-09-15 | 1985 | 9 | 89.510192 | -42.149359 | -0.3201390 |
| 28 | Tamaulipas | 28002 | Aldama | 2009-10-15 | 2009 | 10 | 66.132091 | -36.130446 | -0.3533107 |
| 29 | Tlaxcala | 29022 | Acuamanala de Miguel Hidalgo | 1981-09-15 | 1981 | 9 | 82.381082 | -55.631325 | -0.4030893 |
| 20 | Oaxaca | 20320 | San Pedro Molinos | 2002-11-15 | 2002 | 11 | 37.621507 | 11.317534 | 0.4302595 |

**Base de datos de métrias de precipitación semanal a nivel municipal**

Se guarda bajo el nombre **`db_pr_mun_week.csv.bz2`**

``` r
write_csv(
    x = db_pr_mun_week,
    file = paste0(path2data, "/municipios/db_pr_mun_week.csv.bz2"),
    na = "")
```

| cve_ent | nombre_estado | cve_geo | nombre_municipio | n_year | n_week | pr_mm | anomaly_pr_mm | anomaly_pr_prop |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|
| 28 | Tamaulipas | 28030 | Padilla | 2000 | 17 | 9.653540 | -3.897031 | -0.2875916 |
| 14 | Jalisco | 14125 | San Ignacio Cerro Gordo | 1998 | 21 | 0.000000 | -10.929033 | -1.0000000 |
| 21 | Puebla | 21009 | Ahuehuetitla | 1987 | 46 | 0.000000 | -1.833413 | -1.0000000 |
| 20 | Oaxaca | 20455 | Santiago Ayuquililla | 2010 | 19 | 5.403203 | -8.486885 | -0.6110030 |
| 20 | Oaxaca | 20318 | San Pedro Mixtepec | 1991 | 22 | 41.837505 | 8.984074 | 0.2734592 |

**Base de datos de métrias de precipitación diaria a nivel municipal**

Se guarda bajo el nombre **`db_pr_mun_day.csv.bz2`**

``` r
write_csv(
    x = db_pr_mun_day,
    file = paste0(path2data, "/municipios/db_pr_mun_day.csv.bz2"),
    na = "")
```

| cve_ent | nombre_estado | cve_geo | nombre_municipio | full_date | pr_mm | anomaly_pr_mm | anomaly_pr_prop | n_year | n_month | n_day |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|
| 26 | Sonora | 26047 | Pitiquito | 2024-04-14 | 0.4217752 | 0.4088424 | 31.61295 | 2024 | 4 | 14 |
| 20 | Oaxaca | 20099 | San Andrés Tepetlapa | 2007-04-03 | 0.0000000 | -0.0199290 | -1.00000 | 2007 | 4 | 3 |
| 15 | Estado de México | 15042 | Ixtlahuaca | 1981-10-09 | 0.0000000 | -3.9986659 | -1.00000 | 1981 | 10 | 9 |
| 20 | Oaxaca | 20422 | Santa María Nativitas | 1987-10-26 | 0.0000000 | -0.8682132 | -1.00000 | 1987 | 10 | 26 |
| 20 | Oaxaca | 20239 | San Martín Huamelúlpam | 1984-10-31 | 0.0000000 | -3.2358146 | -1.00000 | 1984 | 10 | 31 |

### Precipitaciones normales

**Base de datos de métrias de precipitación normal anual a nivel estatal**

Se guarda bajo el nombre **`db_pr_normal_ent_year.csv`**

``` r
normal_pr_mm_ent_year %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_year.csv"),
    na = "")
```

| nombre_estado   | cve_ent | normal_pr_mm |
|:----------------|:--------|-------------:|
| Sinaloa         | 25      |     693.6512 |
| Campeche        | 04      |    1329.8219 |
| Chiapas         | 07      |    1997.8444 |
| Aguascalientes  | 01      |     529.2339 |
| Baja California | 02      |     146.5491 |

**Base de datos de métrias de precipitación normal mensual a nivel estatal**

Se guarda bajo el nombre **`db_pr_normal_ent_month.csv`**

``` r
normal_pr_mm_ent_month %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_month.csv"),
    na = "")
```

| nombre_estado | cve_ent | n_month | normal_pr_mm |
|:--------------|:--------|:--------|-------------:|
| Tabasco       | 27      | 12      |    140.37264 |
| Jalisco       | 14      | 11      |     12.97013 |
| Guanajuato    | 11      | 09      |    103.71007 |
| Sinaloa       | 25      | 11      |     18.12924 |
| Quintana Roo  | 23      | 06      |    174.96036 |

**Base de datos de métrias de precipitación normal semanal a nivel estatal**

Se guarda bajo el nombre **`db_pr_normal_ent_week.csv`**

``` r
normal_pr_mm_ent_week %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_week.csv"),
    na = "")
```

| nombre_estado       | cve_ent | n_week | normal_pr_mm |
|:--------------------|:--------|:-------|-------------:|
| Oaxaca              | 20      | 29     |   55.0565409 |
| Jalisco             | 14      | 03     |    5.1302020 |
| Baja California Sur | 03      | 25     |    0.0367408 |
| Nayarit             | 18      | 46     |    3.7167726 |
| Veracruz            | 30      | 25     |   57.1681508 |

**Base de datos de métrias de precipitación normal diaria a nivel estatal**

Se guarda bajo el nombre **`db_pr_normal_ent_day.csv`**

``` r
normal_pr_mm_ent_day %>%
  left_join(
    y = distinct(db_cve_nom_ent_mun, nombre_estado, cve_ent),
    by = join_by(cvegeo == cve_ent)) %>%
  rename(cve_ent = cvegeo) %>%
  relocate(nombre_estado, .before = cve_ent) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_ent_day.csv"),
    na = "")
```

| nombre_estado       | cve_ent | n_month | n_day | normal_pr_mm |
|:--------------------|:--------|--------:|------:|-------------:|
| Baja California Sur | 03      |      10 |    11 |    0.7572439 |
| Querétaro           | 22      |      11 |    13 |    0.4484632 |
| Jalisco             | 14      |       1 |    17 |    0.9178389 |
| Tlaxcala            | 29      |       4 |    30 |    1.9197711 |
| Tabasco             | 27      |       7 |    27 |    5.5709997 |

**Base de datos de métrias de precipitación normal anual a nivel municipal**

Se guarda bajo el nombre **`db_pr_normal_mun_year.csv`**

``` r
normal_pr_mm_mun_year %>%
  left_join(
    y = distinct(.data = db_cve_nom_ent_mun,
                 cve_geo,
                 nombre_estado,
                 cve_ent,
                 nombre_municipio),
    by = join_by(cvegeo == cve_geo)) %>%
  rename(cve_geo = cvegeo) %>%
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .after = nombre_estado) %>%
  relocate(nombre_municipio, .before = cve_geo) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_year.csv"),
    na = "")
```

| nombre_estado    | cve_ent | nombre_municipio          | cve_geo | normal_pr_mm |
|:-----------------|:--------|:--------------------------|:--------|-------------:|
| Oaxaca           | 20      | Acatlán de Pérez Figueroa | 20002   |    2177.4551 |
| Estado de México | 15      | Amecameca                 | 15009   |     848.0109 |
| Veracruz         | 30      | Ixcatepec                 | 30078   |    1259.6317 |
| Morelos          | 17      | Tetela del Volcán         | 17022   |    1068.4810 |
| Oaxaca           | 20      | Santo Domingo Tlatayápam  | 20518   |     881.6413 |

**Base de datos de métrias de precipitación normal mensual a nivel municipal**

Se guarda bajo el nombre **`db_pr_normal_mun_month.csv`**

``` r
normal_pr_mm_mun_month %>%
  left_join(
    y = distinct(.data = db_cve_nom_ent_mun,
                 cve_geo,
                 nombre_estado,
                 cve_ent,
                 nombre_municipio),
    by = join_by(cvegeo == cve_geo)) %>%
  rename(cve_geo = cvegeo) %>%
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .after = nombre_estado) %>%
  relocate(nombre_municipio, .before = cve_geo) %>%
  mutate(n_month = as.integer(n_month)) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_month.csv"),
    na = "")
```

| nombre_estado | cve_ent | nombre_municipio        | cve_geo | n_month | normal_pr_mm |
|:--------------|:--------|:------------------------|:--------|--------:|-------------:|
| Oaxaca        | 20      | Santa María Texcatitlán | 20436   |       1 |     6.998389 |
| Tamaulipas    | 28      | Soto la Marina          | 28037   |       4 |    34.954641 |
| Guerrero      | 12      | Coyuca de Catalán       | 12022   |      11 |    16.597458 |
| Veracruz      | 30      | Poza Rica de Hidalgo    | 30131   |       5 |    68.533040 |
| Oaxaca        | 20      | San Agustín Yatareni    | 20087   |       6 |   168.384020 |

**Base de datos de métrias de precipitación semanal a nivel municipal**

Se guarda bajo el nombre **`db_pr_mun_week.csv.bz2`**

``` r
normal_pr_mm_mun_week %>%
  left_join(
    y = distinct(.data = db_cve_nom_ent_mun,
                 cve_geo,
                 nombre_estado,
                 cve_ent,
                 nombre_municipio),
    by = join_by(cvegeo == cve_geo)) %>%
  rename(cve_geo = cvegeo) %>%
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .after = nombre_estado) %>%
  relocate(nombre_municipio, .before = cve_geo) %>%
  mutate(n_week = as.integer(n_week)) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_week.csv"),
    na = "")
```

| nombre_estado | cve_ent | nombre_municipio     | cve_geo | n_week | normal_pr_mm |
|:--------------|:--------|:---------------------|:--------|-------:|-------------:|
| Hidalgo       | 13      | Apan                 | 13008   |     52 |    2.0476671 |
| Oaxaca        | 20      | San Dionisio del Mar | 20130   |     33 |   42.2270598 |
| Yucatán       | 31      | Telchac Pueblo       | 31082   |     29 |   29.5879961 |
| Michoacán     | 16      | Huetamo              | 16038   |     43 |    8.2894663 |
| Oaxaca        | 20      | San Pedro Pochutla   | 20324   |     10 |    0.7985811 |

**Base de datos de métrias de precipitación normal diaria a nivel municipal**

Se guarda bajo el nombre **`db_pr_normal_mun_day.csv.bz2`**

``` r
normal_pr_mm_mun_day %>%
  left_join(
    y = distinct(.data = db_cve_nom_ent_mun,
                 cve_geo,
                 nombre_estado,
                 cve_ent,
                 nombre_municipio),
    by = join_by(cvegeo == cve_geo)) %>%
  rename(cve_geo = cvegeo) %>%
  relocate(nombre_estado, .before = cve_geo) %>%
  relocate(cve_ent, .after = nombre_estado) %>%
  relocate(nombre_municipio, .before = cve_geo) %>%
  write_csv(
    file = paste0(path2data, "/normal/db_pr_normal_mun_day.csv.bz2"),
    na = "")
```

| nombre_estado | cve_ent | nombre_municipio | cve_geo | n_month | n_day | normal_pr_mm |
|:---|:---|:---|:---|---:|---:|---:|
| Oaxaca | 20 | Santiago Tapextla | 20485 | 2 | 11 | 0.0770775 |
| Oaxaca | 20 | San Juan Yaeé | 20222 | 12 | 26 | 1.9624096 |
| Guanajuato | 11 | Coroneo | 11010 | 12 | 4 | 0.2345465 |
| Oaxaca | 20 | San Juan Bautista Guelache | 20178 | 9 | 7 | 3.4307732 |
| Yucatán | 31 | Dzilam de Bravo | 31028 | 11 | 5 | 2.4970103 |
