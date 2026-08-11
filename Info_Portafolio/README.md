# Info portafolio - Migración Access -> SQL Server

Migra las 7 tablas de `Info portafolio.accdb` a SQL Server (POC). La tabla de
hechos `tbl_Valores` tiene ~4.18 millones de filas.

## Uso

1. Correr `schema.sql` una vez contra la base destino.
2. Revisar que el `.accdb` tenga el esquema esperado (opcional, no toca SQL Server):
   ```
   python import_data.py --check-schema-only
   ```
3. Importar los datos:
   ```
   python import_data.py --sql-server "servidor" --sql-user "usuario"
   ```
   Pide la contraseña de forma interactiva (`getpass`). Es re-corrible: borra e
   inserta de nuevo cada tabla. Por el volumen de `tbl_Valores`, la carga puede
   tardar varios minutos.

Requiere: Python 3 de 64 bits, `pyodbc`, driver "Microsoft Access Driver (*.mdb, *.accdb)" y "ODBC Driver 17 for SQL Server" (ambos de 64 bits).

## Decisiones de modelado (resumen)

Ver los comentarios en `schema.sql` para el detalle completo. En corto:

- No había diagrama ERD para esta base -- el esquema se extrajo y validó
  directamente contra los datos reales del `.accdb` (unicidad de PK
  candidatas y huérfanos de FK) antes de escribir `schema.sql`.
- `tbl_Tiempos` no es una dimensión de fecha: es un tipo de periodo (Mes /
  Últimos 12 meses / Acumulado año). Cada `Fecha` en `tbl_Valores` puede
  repetirse hasta 3 veces.
- `tbl_Centros` es una tabla de **jerarquía**: el mismo `Cod_Centro` se
  reutiliza en cada `Cod_Nivel` (arrendatario, centro, ciudad, sector, etc.).
  No tiene una llave natural 100% única (quedan 8 pares con dos filas
  legítimas, ej. un local con arrendatario real y una fila "VACANTE" al mismo
  tiempo) -> se usa un `Id` IDENTITY como PK.
- `tbl_Valores.Fecha` y `tbl_Valores.Cod_Centro` **no tienen FK real** hacia
  sus dimensiones (791 filas con fechas sueltas fuera de ciclo, y
  `tbl_Centros` sin llave única) -- se dejan como índice para no perder esas
  filas reales.
- 1 fila placeholder (`Cod_Cuenta = 0`) se filtra al importar `tbl_Valores`.
