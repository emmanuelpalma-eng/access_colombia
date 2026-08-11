"""
Importa las 7 tablas de "Info portafolio.accdb" a SQL Server usando pyodbc.
Requiere que schema.sql ya se haya corrido una vez contra la base destino.

Pensado para correrse en tu propia terminal (no via un agente), porque pide
la contrasena de SQL de forma interactiva con getpass (no queda en el
historial de la terminal ni en ningun chat).

USO:
    1) Revisar el esquema real de Access antes de importar (no toca SQL Server):
       python import_data.py --check-schema-only

    2) Import real (borra e inserta de nuevo cada tabla, re-corrible sin duplicar):
       python import_data.py --sql-server "mi_servidor" --sql-user "mi_usuario"

Parametros opcionales:
    --access-path   Ruta al .accdb (por defecto, la ruta ya conocida)
    --sql-database  Nombre de la base destino (por defecto poc_colombia)
    --batch-size    Filas por lote para el insert masivo (por defecto 5000;
                     tbl_Valores tiene ~4.18M filas, un lote mas grande reduce
                     el numero de round-trips)
"""

import argparse
import getpass
import os
import sys

import pyodbc

DEFAULT_ACCESS_PATH = (
    r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades"
    r"\Colombia\Bases_Colombia\Info portafolio.accdb"
)

# Orden de carga = orden de dependencias de FK definido en schema.sql.
# Cada tupla es (nombre_tabla, mapeo_columnas_origen->destino, filtro_where_opcional).
# tbl_Centros tiene una columna Id IDENTITY en el destino que no existe en el
# origen -- no requiere manejo especial porque el INSERT solo usa las columnas
# que sí vienen de Access.
TABLES = [
    ("tbl_Fechas", {}, None),
    ("tbl_Niveles", {}, None),
    ("tbl_Tiempos", {}, None),
    ("tbl_Cuentas", {}, None),
    ("tbl_Totales", {}, None),
    ("tbl_Centros", {}, None),
    ("tbl_Valores", {}, "Cod_Cuenta <> 0"),  # 1 fila placeholder sin cuenta real
]

# FKs que sí se sostienen con datos reales (ver schema.sql para las que se
# evaluaron y se descartaron: tbl_Valores.Fecha y tbl_Valores.Cod_Centro).
FK_CONSTRAINTS = [
    ("tbl_Totales", "FK_tbl_Totales_tbl_Niveles"),
    ("tbl_Centros", "FK_tbl_Centros_tbl_Niveles"),
    ("tbl_Valores", "FK_tbl_Valores_tbl_Niveles"),
    ("tbl_Valores", "FK_tbl_Valores_tbl_Tiempos"),
    ("tbl_Valores", "FK_tbl_Valores_tbl_Cuentas"),
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


def set_fk_check(conn, enabled):
    verb = "WITH CHECK CHECK" if enabled else "NOCHECK"
    cursor = conn.cursor()
    for table, constraint in FK_CONSTRAINTS:
        cursor.execute(f"ALTER TABLE dbo.[{table}] {verb} CONSTRAINT [{constraint}]")
    conn.commit()


def check_schema(access_path):
    conn = access_connection(access_path)
    try:
        cursor = conn.cursor()
        for table_name, _overrides, _where in TABLES:
            # No usar cursor.columns() (SQLColumns): el driver de Access
            # puede devolver metadatos con una codificacion que pyodbc no
            # logra decodificar para ciertas tablas (UnicodeDecodeError).
            # SELECT * + cursor.description evita ese camino del driver.
            cursor.execute(f"SELECT * FROM [{table_name}]")
            cols = [d[0] for d in cursor.description]
            cursor.execute(f"SELECT COUNT(*) FROM [{table_name}]")
            row_count = cursor.fetchone()[0]
            print(f"== {table_name}  ({row_count} filas en Access) ==")
            print("  " + ", ".join(cols))
    finally:
        conn.close()


def import_data(access_path, server, database, user, password, batch_size):
    sql_conn = sql_connection(server, database, user, password)
    access_conn = access_connection(access_path)

    try:
        print("Desactivando FKs...")
        set_fk_check(sql_conn, enabled=False)

        for table_name, overrides, where in TABLES:
            print(f"Cargando {table_name}...", end=" ")
            sys.stdout.flush()

            # DELETE previo para que el script se pueda re-correr sin duplicar
            # filas en tablas que no tienen PK propia (tbl_Valores) o cuya PK
            # es subrogada (tbl_Centros).
            sql_conn.cursor().execute(f"DELETE FROM dbo.[{table_name}]")

            access_cursor = access_conn.cursor()
            query = f"SELECT * FROM [{table_name}]"
            if where:
                query += f" WHERE {where}"
            access_cursor.execute(query)
            src_columns = [d[0] for d in access_cursor.description]
            dest_columns = [overrides.get(c, c) for c in src_columns]

            col_list = ", ".join(f"[{c}]" for c in dest_columns)
            placeholders = ", ".join("?" for _ in dest_columns)
            insert_sql = f"INSERT INTO dbo.[{table_name}] ({col_list}) VALUES ({placeholders})"

            sql_cursor = sql_conn.cursor()
            sql_cursor.fast_executemany = True

            total = 0
            try:
                while True:
                    rows = access_cursor.fetchmany(batch_size)
                    if not rows:
                        break
                    sql_cursor.executemany(insert_sql, [tuple(r) for r in rows])
                    total += len(rows)
                    if total % (batch_size * 20) == 0:
                        print(f"\n  ... {total} filas hasta ahora", end="")
                        sys.stdout.flush()
                sql_conn.commit()
                print(f"OK ({total} filas)")
            except Exception as ex:
                sql_conn.rollback()
                print(f"ERROR: {ex}")

        print("Reactivando y validando FKs...")
        try:
            set_fk_check(sql_conn, enabled=True)
            print("FKs validadas sin problemas.")
        except Exception as ex:
            sql_conn.rollback()
            print(f"Alguna FK no se pudo revalidar: {ex}")
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
    parser.add_argument("--batch-size", type=int, default=5000)
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
