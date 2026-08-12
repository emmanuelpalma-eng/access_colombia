# SIF_Colombia_Parametros

Cargador **autoritativo** de todas las dimensiones compartidas de
`poc_colombia`, desde `Informes FIC - Parámetros.accdb` (más 4 hojas de
`Bases_Colombia\Input\*.xlsx` que aún no existen en ningún Access).

Este archivo fue detectado como la fuente externa "Parámetros" del diagrama
de flujo original: sus conteos de fila calzan exacto con las copias que ya
cargaban `SIF_Colombia_351` (tbl_Fechas, tbl_Inmuebles, tbl_Contratos,
tbl_Usuarios, VL_Disp_xa_Venta), `SIF_Colombia_Info_portafolio` (tbl_Niveles,
tbl_Tiempos, tbl_Cuentas, tbl_Totales, tbl_Centros) y
`SIF_Colombia_PowerBI` (tbl_Fondos, tbl_Arrendatarios).

**Reemplaza**:
- `SIF_Colombia_PowerBI/import_dimensiones.py` → ver `SIF_Colombia_PowerBI/import_dimensiones.py.legacy`.
- La carga de dimensiones que hacían `SIF_Colombia_351` e
  `SIF_Colombia_Info_portafolio` directamente desde sus propios `.accdb`
  (esos dos proyectos quedaron recortados a solo sus hechos/EEFF propios).

**Agrega** (nunca modeladas antes, ver `poc_colombia/schema/11_detalle_contratos_inmuebles.sql`):
`tbl_MI`, `tbl_Inmuebles_Otros`, `tbl_Contratos_Otros_Fondos`,
`tbl_Contratos_Restituidos_OtrosFondos`, `tbl_Contratos_Detalle` (detalle
legal/financiero de contratos, ~80 columnas, unión por nombre de columna
entre la tabla Access `Contratos` y la hoja Excel "Contratos no vigentes"),
`tbl_Inmuebles_Estrategia`, `tbl_Inmuebles_Compras`,
`tbl_Inmuebles_MI_Contratos`.

## Orden de ejecución (dentro de `poc_colombia/`)

Este proyecto corre **primero**, antes de `SIF_Colombia_Info_portafolio` y
`SIF_Colombia_351` (ambos ahora dependen de las dimensiones que este script
carga vía FK).

## Uso

```
python import_data.py --check-schema-only
python import_data.py --sql-server "mi_servidor" --sql-user "mi_usuario"
```

Requiere `openpyxl` además de `pyodbc` (por las 4 hojas que solo existen en Excel).
