"""
Importa las 13 tablas de "Informes FIC - 351.accdb" a SQL Server (poc_colombia)
usando pyodbc, via el esquema consolidado en Colombia/poc_colombia/schema/.

Flujo por tabla: carga a stg.<tabla> (sin PK/FK, TRUNCATE + insert masivo) y
luego llama a etl.usp_ReemplazarDimension (dimensiones) o
etl.usp_CargarFactoParticionado (hechos) para mover los datos a dbo con las
validaciones de FK correspondientes -- ya no hay logica de NOCHECK/CHECK
ad-hoc en este script, vive centralizada en los SPs (ver
poc_colombia/schema/09_sp_etl.sql).

Pensado para correrse en tu propia terminal (no via un agente), porque pide
la contrasena de SQL de forma interactiva con getpass.

USO:
    1) Revisar el esquema real de Access antes de importar (no toca SQL Server):
       python import_data.py --check-schema-only

    2) Import real:
       python import_data.py --sql-server "mi_servidor" --sql-user "mi_usuario"

Requisito previo: correr Colombia/poc_colombia/ (ver su README) contra la
base destino -- este script ya no crea el esquema.
"""

import argparse
import getpass
import os
import sys

import pyodbc

DEFAULT_ACCESS_PATH = (
    r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades"
    r"\Colombia\Bases_Colombia\Informes FIC - 351.accdb"
)

# Cada tupla: (tabla, mapeo_columnas_origen->destino, filtro_where_opcional, tipo)
# tipo = "dimension" (otras tablas tienen FK hacia esta -> usp_ReemplazarDimension)
#      | "fact" (tabla de hechos, nadie la referencia -> usp_CargarFactoParticionado)
TABLES = [
    ("tbl_Fechas", {}, None, "dimension"),
    ("tbl_Cuentas_EEFF", {}, None, "dimension"),
    ("tbl_Usuarios", {}, None, "dimension"),
    ("tbl_Inmuebles", {}, None, "dimension"),
    ("tbl_Cruce_SIF", {}, "Cod_Cta <> 0", "dimension"),  # 6 filas placeholder sin cuenta real
    ("tbl_Cruce351", {}, None, "dimension"),  # Cod_Inm admite NULL (3 filas sin asignar)
    ("tbl_Valores_Valor_Libros", {}, None, "fact"),
    ("VL_Disp_xa_Venta", {}, None, "fact"),
    # Cod_Inm 0 y 5000: filas de totales/consolidado ("351 DF"), no una propiedad real.
    # Cod_Inm 997: propiedad real pero tbl_Inmuebles no tiene foto para esos meses.
    ("tbl_ValorLibros_xInmueble", {}, "Cod_Inm NOT IN (0, 5000, 997)", "fact"),
    ("VL_CentralPoint", {}, "FECHA IS NOT NULL", "fact"),  # 3 filas completamente vacias
    ("tbl_Contratos", {}, None, "dimension"),
    ("tbl_EEFF", {}, None, "fact"),
    ("F351", {"######": "Campo13"}, None, "fact"),
]


def access_connection(access_path):
    conn_str = (
        r"Driver={Microsoft Access Driver (*.mdb, *.accdb)};"
        f"DBQ={access_path};"
    )
    return pyodbc.connect(conn_str, autocommit=True)


def sql_connection(server, database, user, password):
    conn_str = (
        "Driver={ODBC Driver 17 for SQL Server};"
        f"Server={server};Database={database};"
        f"UID={user};PWD={password};"
        "Encrypt=yes;TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str, autocommit=False)


def check_schema(access_path):
    conn = access_connection(access_path)
    try:
        cursor = conn.cursor()
        for table_name, _overrides, _where, _kind in TABLES:
            # No usar cursor.columns() (SQLColumns): el driver de Access
            # puede devolver metadatos con una codificacion que pyodbc no
            # logra decodificar para ciertas tablas (UnicodeDecodeError).
            cursor.execute(f"SELECT * FROM [{table_name}]")
            cols = [d[0] for d in cursor.description]
            cursor.execute(f"SELECT COUNT(*) FROM [{table_name}]")
            row_count = cursor.fetchone()[0]
            print(f"== {table_name}  ({row_count} filas en Access) ==")
            print("  " + ", ".join(cols))
    finally:
        conn.close()


def load_to_staging(access_conn, sql_conn, table_name, overrides, where, batch_size):
    sql_conn.cursor().execute(f"TRUNCATE TABLE stg.[{table_name}]")

    access_cursor = access_conn.cursor()
    query = f"SELECT * FROM [{table_name}]"
    if where:
        query += f" WHERE {where}"
    access_cursor.execute(query)
    src_columns = [d[0] for d in access_cursor.description]
    dest_columns = [overrides.get(c, c) for c in src_columns]

    col_list = ", ".join(f"[{c}]" for c in dest_columns)
    placeholders = ", ".join("?" for _ in dest_columns)
    insert_sql = f"INSERT INTO stg.[{table_name}] ({col_list}) VALUES ({placeholders})"

    sql_cursor = sql_conn.cursor()
    sql_cursor.fast_executemany = True

    total = 0
    while True:
        rows = access_cursor.fetchmany(batch_size)
        if not rows:
            break
        sql_cursor.executemany(insert_sql, [tuple(r) for r in rows])
        total += len(rows)
    sql_conn.commit()
    return total


def import_data(access_path, server, database, user, password, batch_size):
    sql_conn = sql_connection(server, database, user, password)
    access_conn = access_connection(access_path)

    try:
        for table_name, overrides, where, kind in TABLES:
            print(f"Cargando {table_name}...", end=" ")
            sys.stdout.flush()
            try:
                staged = load_to_staging(access_conn, sql_conn, table_name, overrides, where, batch_size)

                sp_cursor = sql_conn.cursor()
                if kind == "dimension":
                    sp_cursor.execute(
                        "EXEC etl.usp_ReemplazarDimension @TablaDestino = ?, @TablaStaging = ?",
                        f"dbo.{table_name}", f"stg.{table_name}",
                    )
                else:
                    sp_cursor.execute(
                        "EXEC etl.usp_CargarFactoParticionado @TablaDestino = ?, @TablaStaging = ?",
                        f"dbo.{table_name}", f"stg.{table_name}",
                    )
                sql_conn.commit()
                print(f"OK ({staged} filas)")
            except Exception as ex:
                sql_conn.rollback()
                print(f"ERROR: {ex}")
    finally:
        access_conn.close()
        sql_conn.close()

    print("Proceso terminado.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--access-path", default=DEFAULT_ACCESS_PATH)
    parser.add_argument("--sql-server")
    parser.add_argument("--sql-database", default="poc_colombia")
    parser.add_argument("--sql-user")
    parser.add_argument("--batch-size", type=int, default=2000)
    parser.add_argument("--check-schema-only", action="store_true")
    args = parser.parse_args()

    if not os.path.isfile(args.access_path):
        print(f"No se encontro el archivo Access en: {args.access_path}")
        sys.exit(1)

    if args.check_schema_only:
        check_schema(args.access_path)
        return

    if not args.sql_server or not args.sql_user:
        print("Debes indicar --sql-server y --sql-user (o usar --check-schema-only).")
        sys.exit(1)

    password = getpass.getpass(f"Password SQL para {args.sql_user}@{args.sql_server}: ")
    import_data(args.access_path, args.sql_server, args.sql_database, args.sql_user, password, args.batch_size)


if __name__ == "__main__":
    main()
