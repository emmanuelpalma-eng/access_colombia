import pyodbc
import json
import sys

files = {
    "Info_portafolio": r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades\Colombia\Bases_Colombia\Info portafolio.accdb",
    "Informes_FIC_351": r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades\Colombia\Bases_Colombia\Informes FIC - 351.accdb",
    "Informes_FIC_PowerBI": r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades\Colombia\Bases_Colombia\Informes FIC - PowerBI.accdb",
    "Informes_FIC_Reportes": r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades\Colombia\Bases_Colombia\Informes FIC - Reportes.accdb",
    "Informes_FIC_Gastos_Otros": r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades\Colombia\Bases_Colombia\Informes FIC- Gastos Otros.accdb",
    "Informes_RE": r"C:\Users\pal2101\OneDrive - Patria Investimentos\Producción\Utilidades\Colombia\Bases_Colombia\Informes RE.accdb",
}

result = {}

for key, path in files.items():
    conn_str = (
        r"Driver={Microsoft Access Driver (*.mdb, *.accdb)};"
        f"DBQ={path};"
    )
    try:
        cnxn = pyodbc.connect(conn_str, autocommit=True)
    except Exception as e:
        result[key] = {"error": str(e)}
        continue

    cursor = cnxn.cursor()
    db_info = {"tables": {}, "relationships": []}

    # list tables (exclude system/msys)
    table_names = []
    for row in cursor.tables(tableType='TABLE'):
        tname = row.table_name
        if tname.startswith("MSys") or tname.startswith("~"):
            continue
        table_names.append(tname)

    for tname in table_names:
        cols = []
        for col in cursor.columns(table=tname):
            cols.append({
                "name": col.column_name,
                "type": col.type_name,
                "size": col.column_size,
                "nullable": bool(col.nullable),
            })
        pks = []
        try:
            for pk in cursor.primaryKeys(table=tname):
                pks.append(pk.column_name)
        except Exception:
            pass
        db_info["tables"][tname] = {"columns": cols, "primary_keys": pks}

    # foreign keys / relationships
    for tname in table_names:
        try:
            for fk in cursor.foreignKeys(foreignTable=tname):
                db_info["relationships"].append({
                    "pk_table": fk.pktable_name,
                    "pk_column": fk.pkcolumn_name,
                    "fk_table": fk.fktable_name,
                    "fk_column": fk.fkcolumn_name,
                })
        except Exception:
            pass

    # row counts (quick sanity, skip if too slow - limit)
    for tname in table_names:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM [{tname}]")
            cnt = cursor.fetchone()[0]
            db_info["tables"][tname]["row_count"] = cnt
        except Exception as e:
            db_info["tables"][tname]["row_count"] = None

    result[key] = db_info
    cnxn.close()

out_path = r"C:\Users\pal2101\AppData\Local\Temp\claude\C--Users-pal2101\d9f1f20b-4185-4a23-805c-99725c84dd6c\scratchpad\schema_dump.json"
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print("DONE, written to", out_path)
for key, info in result.items():
    if "error" in info:
        print(key, "ERROR:", info["error"])
    else:
        print(key, "-> tables:", len(info["tables"]), "relationships:", len(info["relationships"]))
