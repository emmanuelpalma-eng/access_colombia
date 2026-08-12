"""
Carga SOLO las dimensiones de "Informes FIC - PowerBI.accdb" que son
requisito duro para que SIF_Colombia_351 y SIF_Colombia_Info_portafolio
funcionen: tbl_Fondos y tbl_Arrendatarios. Varias tablas del modelo
consolidado (tbl_Centros.Cod_Fondo, tbl_Contratos.COD_FONDO/NIT, etc.)
tienen FK hacia estas 2 dimensiones -- sin cargarlas primero, esos imports
fallan con "FOREIGN KEY constraint conflicted".

El resto de PowerBI (tbl_Contratos/tbl_Inmuebles/tbl_Centros -- copias ya
cubiertas por 351/Info Portafolio -- y la capa derivada tbl_PBI_*, tbl_TRM,
etc.) queda fuera de alcance por ahora (Fase 2, ver poc_colombia/README.md).

Requiere: poc_colombia ya creado (ver poc_colombia/README.md).

USO:
    python import_dimensiones.py --sql-server "servidor" --sql-user "usuario"
"""

import argparse
import decimal
import getpass
import os
import sys

import pyodbc

DEFAULT_ACCESS_PATH = (
    r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades"
    r"\Colombia\Bases_Colombia\Informes FIC - PowerBI.accdb"
)

TABLES = ["tbl_Fondos", "tbl_Arrendatarios"]

# Placeholder que varias fuentes usan como centinela "no aplica a un fondo
# especifico" (ej. niveles de rollup en tbl_Centros) -- no viene en el
# origen de PowerBI, se agrega manualmente despues de cargar los datos reales.
FONDO_PLACEHOLDER = (0, None, "N/A", "No aplica", "No aplica / Consolidado (placeholder)", None, None)


def _clean_row(row):
    return tuple(float(v) if isinstance(v, decimal.Decimal) else v for v in row)


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


def import_dimensiones(access_path, server, database, user, password):
    access_conn = access_connection(access_path)
    sql_conn = sql_connection(server, database, user, password)

    try:
        for table_name in TABLES:
            print(f"Cargando {table_name}...", end=" ")
            sys.stdout.flush()
            try:
                access_cursor = access_conn.cursor()
                access_cursor.execute(f"SELECT * FROM [{table_name}]")
                cols = [d[0] for d in access_cursor.description]
                rows = [_clean_row(r) for r in access_cursor.fetchall()]

                sql_cursor = sql_conn.cursor()
                sql_cursor.execute(f"TRUNCATE TABLE stg.[{table_name}]")
                col_list = ", ".join(f"[{c}]" for c in cols)
                placeholders = ", ".join("?" for _ in cols)
                sql_cursor.fast_executemany = True
                sql_cursor.executemany(
                    f"INSERT INTO stg.[{table_name}] ({col_list}) VALUES ({placeholders})", rows
                )

                sql_cursor.execute(
                    "EXEC etl.usp_ReemplazarDimension @TablaDestino = ?, @TablaStaging = ?",
                    f"dbo.{table_name}", f"stg.{table_name}",
                )

                if table_name == "tbl_Fondos":
                    sql_cursor.execute(
                        "IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Fondos WHERE COD_FONDO = 0) "
                        "INSERT INTO dbo.tbl_Fondos (COD_FONDO, COD_FONDO_FIDU, ABREV_FONDO, "
                        "NOM_CORTO_FONDO, NOM_FONDO, FIDU, FONDO) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        *FONDO_PLACEHOLDER,
                    )

                sql_conn.commit()
                print(f"OK ({len(rows)} filas)")
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
    parser.add_argument("--sql-server", required=True)
    parser.add_argument("--sql-database", default="poc_colombia")
    parser.add_argument("--sql-user", required=True)
    args = parser.parse_args()

    if not os.path.isfile(args.access_path):
        print(f"No se encontro el archivo Access en: {args.access_path}")
        sys.exit(1)

    password = getpass.getpass(f"Password SQL para {args.sql_user}@{args.sql_server}: ")
    import_dimensiones(args.access_path, args.sql_server, args.sql_database, args.sql_user, password)


if __name__ == "__main__":
    main()
