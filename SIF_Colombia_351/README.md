# SIF Colombia - Informes FIC 351 - Migración Access -> SQL Server

Migra las 13 tablas de `Informes FIC - 351.accdb` a SQL Server (POC).

## Uso

1. Correr `schema.sql` una vez contra la base destino (crea las 13 tablas, PKs, FKs e índices).
2. Revisar que el `.accdb` tenga el esquema esperado (opcional, no toca SQL Server):
   ```
   python import_data.py --check-schema-only
   ```
3. Importar los datos:
   ```
   python import_data.py --sql-server "servidor" --sql-user "usuario"
   ```
   Pide la contraseña de forma interactiva (`getpass`, no queda en el historial). Es re-corrible: borra e inserta de nuevo cada tabla, así que se puede volver a ejecutar sin duplicar filas.

Requiere: Python 3 de 64 bits, `pyodbc`, driver "Microsoft Access Driver (*.mdb, *.accdb)" y "ODBC Driver 17 for SQL Server" (ambos de 64 bits).

## Decisiones de modelado (resumen)

Ver los comentarios en `schema.sql` para el detalle completo. En corto:

- `tbl_Inmuebles` y `tbl_Contratos` son fotos mensuales, no catálogos únicos -> PK compuesta.
- 4 relaciones del diagrama original **no se pudieron sostener con datos reales** y se dejaron como índice simple en vez de FK:
  - `tbl_Cruce351` -> `tbl_Inmuebles`
  - `tbl_ValorLibros_xInmueble.COD_CTA` -> `tbl_Cuentas_EEFF`
  - `tbl_Contratos` -> `tbl_Inmuebles` (`tbl_Inmuebles` solo cubre desde 2024-01, `tbl_Contratos` tiene historial desde 2008)
  - `tbl_EEFF.COD_CTA` -> `tbl_Cuentas_EEFF`
- Un puñado de filas placeholder/basura (totales de reporte, filas 100% vacías) se filtran al importar -- ver el diccionario `TABLES` en `import_data.py`.
