# SIF Colombia - PowerBI (solo dimensiones requeridas)

Carga únicamente `tbl_Fondos` (15 filas + 1 placeholder `COD_FONDO=0`) y
`tbl_Arrendatarios` (336 filas) desde `Informes FIC - PowerBI.accdb`.

**Por qué existe esto**: al probar el modelo consolidado con datos reales,
`SIF_Colombia_351` y `SIF_Colombia_Info_portafolio` fallaban con violaciones
de FK porque varias tablas (`tbl_Centros.Cod_Fondo`, `tbl_Contratos.COD_FONDO`,
`tbl_Inmuebles.Cod_Fondo`, `tbl_EEFF.COD_FONDO`, `tbl_Valores*.Cod_Fondo`) 
referencian `tbl_Fondos`, y nadie la había cargado todavía.

**Orden de ejecución recomendado** (antes de correr 351 o Info Portafolio):

```
python import_dimensiones.py --sql-server "servidor" --sql-user "usuario"
```

El resto de PowerBI (24 tablas: `tbl_Contratos`/`tbl_Inmuebles`/`tbl_Centros`
son copias ya cubiertas por las otras 2 fuentes; `tbl_PBI_*`, `tbl_TRM`,
`tbl_Valores_Resumen`, etc. son la capa derivada para dashboards, pendiente
de diseño -- ver `poc_colombia/README.md`) queda fuera de alcance de este
mini-proyecto.
