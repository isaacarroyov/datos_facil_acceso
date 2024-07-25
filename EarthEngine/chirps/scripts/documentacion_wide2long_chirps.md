# CHIRPS: Extracción y procesamiento de datos de lluvia


> \[!NOTE\]
>
> Se puede observar que se cambia el directorio de trabajo a la carpeta **`/EarthEngine/chirps/scripts`** para después agregar `/../../..` en la variable **`path2main`**. Este cambio se hace para que al renderizar, el código se pueda ejecutar correctamente, ya que el archivo toma como directorio de trabajo la carpeta en la que se encuentra el script en el que se esta haciendo el código.

``` r
setwd("./EarthEngine/chirps/scripts")
```

## Introducción y objetivos

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec lobortis porttitor ligula, id consequat tortor aliquet ut. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Maecenas laoreet vehicula turpis et aliquet. Quisque feugiat metus ac dui accumsan, in eleifend tellus venenatis. Morbi at enim vitae dui fermentum feugiat. Nullam pellentesque orci vel velit euismod laoreet. Nulla dolor sapien, fringilla in nisi eu, vestibulum dapibus risus. Morbi quis porttitor erat, sed cursus erat. Nulla ut pretium est. Suspendisse in ultrices nulla, vitae tempus metus. Nam metus dolor, tempor ut libero quis, sagittis hendrerit urna. Phasellus sit amet interdum nisi, id mollis nibh. Pellentesque non velit pellentesque, iaculis nisl in, dapibus nisl. Curabitur tristique ipsum sit amet vulputate venenatis. Morbi a faucibus mauris.

``` r
Sys.setlocale(locale = "es_ES")
library(tidyverse)

path2main <- paste0(getwd(), "/../../..")
path2ee <- paste0(path2main, "/EarthEngine")
path2chirps <- paste0(path2ee, "/chirps")
```

## 01

Duis nulla turpis, elementum eget purus sed, gravida lobortis purus. Sed sem enim, placerat ac neque blandit, viverra hendrerit lacus. Suspendisse dictum odio vitae purus ullamcorper, id facilisis metus ultrices. Morbi leo ipsum, condimentum in consequat et, vestibulum in eros. Sed a sagittis nulla, sed mattis erat. Mauris tempus nibh nisi, et feugiat eros gravida vel. Aenean rutrum vitae nulla a porta. Donec volutpat velit mauris, molestie pretium ex dapibus sed. Sed mattis turpis ut orci hendrerit, a varius metus rhoncus.

## 02

Phasellus aliquam erat lacinia enim dapibus, eget mollis justo rutrum. Maecenas ornare laoreet tellus ac iaculis. Etiam aliquam pulvinar nisl, at dignissim dui dictum dignissim. Sed quis odio cursus, viverra quam eu, fringilla ante. Sed sit amet hendrerit libero. Nullam vitae ullamcorper dui. Ut elementum, sapien sed malesuada dictum, dui ante lobortis mauris, eleifend dignissim nibh ex in risus. Vestibulum tempor congue lectus, nec pellentesque leo sodales sed. Sed vitae est id metus rutrum vestibulum sed sed neque. Interdum et malesuada fames ac ante ipsum primis in faucibus. In pharetra varius rutrum. Integer libero eros, imperdiet ut elit sed, accumsan volutpat elit.

## 03

Nulla blandit nibh a egestas efficitur. Morbi pretium mi eget diam posuere tempus. Nam in ex lacinia, tincidunt massa non, malesuada nibh. Aenean faucibus arcu lorem, ut suscipit mauris suscipit ut. Proin dignissim lorem et leo imperdiet, sit amet vulputate turpis semper. Aenean et ante id urna elementum aliquam. Morbi turpis nibh, egestas ac elementum et, viverra at mauris. Phasellus dapibus feugiat erat, non imperdiet urna. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur non diam sed lectus molestie rhoncus ac ut nisl. Maecenas at dui ut tortor pretium scelerisque finibus et magna. Morbi non libero porta, aliquet erat sit amet, dapibus quam. Ut et consequat massa. Phasellus efficitur tristique sem, eget tristique nisl scelerisque ut. Praesent dapibus, orci et aliquam feugiat, augue nisl interdum tellus, ac vulputate nisi tortor sed lacus. Aenean rhoncus urna et lorem placerat, eu maximus elit volutpat.

## 04

Integer ultricies placerat nunc in commodo. Aenean scelerisque tristique urna, gravida consectetur nulla commodo eget. Suspendisse orci orci, laoreet sed molestie quis, pellentesque at lorem. Ut suscipit ipsum libero, sit amet ullamcorper libero pellentesque ut. Nam eu iaculis dui. Proin ut ante sit amet ligula porta dignissim. Nullam lobortis massa varius felis lacinia aliquam. Phasellus risus nunc, pharetra a imperdiet eu, euismod ac mauris.

## Guardar bases de datos de métricas de precitación

Duis nulla turpis, elementum eget purus sed, gravida lobortis purus. Sed sem enim, placerat ac neque blandit, viverra hendrerit lacus. Suspendisse dictum odio vitae purus ullamcorper, id facilisis metus ultrices. Morbi leo ipsum, condimentum in consequat et, vestibulum in eros. Sed a sagittis nulla, sed mattis erat. Mauris tempus nibh nisi, et feugiat eros gravida vel. Aenean rutrum vitae nulla a porta. Donec volutpat velit mauris, molestie pretium ex dapibus sed. Sed mattis turpis ut orci hendrerit, a varius metus rhoncus.

### Semanal

Phasellus aliquam erat lacinia enim dapibus, eget mollis justo rutrum. Maecenas ornare laoreet tellus ac iaculis. Etiam aliquam pulvinar nisl, at dignissim dui dictum dignissim. Sed quis odio cursus, viverra quam eu, fringilla ante. Sed sit amet hendrerit libero. Nullam vitae ullamcorper dui. Ut elementum, sapien sed malesuada dictum, dui ante lobortis mauris, eleifend dignissim nibh ex in risus. Vestibulum tempor congue lectus, nec pellentesque leo sodales sed. Sed vitae est id metus rutrum vestibulum sed sed neque. Interdum et malesuada fames ac ante ipsum primis in faucibus. In pharetra varius rutrum. Integer libero eros, imperdiet ut elit sed, accumsan volutpat elit.

## Mensual

Nulla blandit nibh a egestas efficitur. Morbi pretium mi eget diam posuere tempus. Nam in ex lacinia, tincidunt massa non, malesuada nibh. Aenean faucibus arcu lorem, ut suscipit mauris suscipit ut. Proin dignissim lorem et leo imperdiet, sit amet vulputate turpis semper. Aenean et ante id urna elementum aliquam. Morbi turpis nibh, egestas ac elementum et, viverra at mauris. Phasellus dapibus feugiat erat, non imperdiet urna. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur non diam sed lectus molestie rhoncus ac ut nisl. Maecenas at dui ut tortor pretium scelerisque finibus et magna. Morbi non libero porta, aliquet erat sit amet, dapibus quam. Ut et consequat massa. Phasellus efficitur tristique sem, eget tristique nisl scelerisque ut. Praesent dapibus, orci et aliquam feugiat, augue nisl interdum tellus, ac vulputate nisi tortor sed lacus. Aenean rhoncus urna et lorem placerat, eu maximus elit volutpat.

## Anual

Integer ultricies placerat nunc in commodo. Aenean scelerisque tristique urna, gravida consectetur nulla commodo eget. Suspendisse orci orci, laoreet sed molestie quis, pellentesque at lorem. Ut suscipit ipsum libero, sit amet ullamcorper libero pellentesque ut. Nam eu iaculis dui. Proin ut ante sit amet ligula porta dignissim. Nullam lobortis massa varius felis lacinia aliquam. Phasellus risus nunc, pharetra a imperdiet eu, euismod ac mauris.
