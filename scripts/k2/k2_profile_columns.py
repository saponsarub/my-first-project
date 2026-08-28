# -*- coding: utf-8 -*-
"""Profile ทุกคอลัมน์ของตารางแกน K2 — null rate · distinct · min/max · ตัวอย่างค่า

ผลลง _raw/column-profile.csv  (ไม่มี PII: คอลัมน์ที่เป็นข้อมูลส่วนบุคคลจะไม่เก็บตัวอย่างค่า)
รันด้วย:  $env:K2_USER="..."; $env:K2_PWD="..."; python k2_profile_columns.py
"""
import csv
import os
import re
import sys

import pyodbc

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "COM7-Knowledge-Base", "3 Source System Survey", "K2 (HPCOM7)", "_raw")

USERNAME = os.environ.get("K2_USER")
PASSWORD = os.environ.get("K2_PWD")
if not USERNAME or not PASSWORD:
    sys.exit('ต้องตั้ง credential ก่อน:  $env:K2_USER="..."; $env:K2_PWD="..."')

# ตารางแกนที่ต้องมี data dictionary ระดับ field
TABLES = [
    "CONTRACT", "CUSTOMER_CARD", "COLLECTION_OD", "COLLECTION_OD_ASSIGNMENT",
    "INVOICE", "REPAYMENT", "APPLICATION", "PRODUCT", "PERSON", "ADDRESS",
    "QUOTATION", "ACCOUNT", "PAYMENT", "GUARANTOR", "CONTACT_DEBT_COLLECTION",
]

# คอลัมน์ที่ห้ามเก็บตัวอย่างค่า (PII / ไฟล์แนบ)
PII = re.compile(
    r"(NAME|TAX_ID|CARD|PHONE|MOBILE|TEL|EMAIL|LINEID|FACEBOOK|ADDR|_NO$|_MOI$|_SOI$|_ROAD$"
    r"|_VILLAGE$|_BUILDING$|_ROOM|BIRTH|LAT|LONG|_FILE|_PATH|PASSWORD|SIGNATURE|SERIAL|REMARK|NOTE)",
    re.IGNORECASE)
NUMERIC = {"int", "bigint", "smallint", "tinyint", "decimal", "numeric", "float", "real", "money"}
DATE = {"date", "datetime", "datetime2", "smalldatetime"}


def main():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};SERVER=43.254.133.123;DATABASE=HPCOM7;"
        f"UID={USERNAME};PWD={PASSWORD};TrustServerCertificate=yes;", timeout=1800)
    cur = conn.cursor()
    rows_out = []

    for t in TABLES:
        cur.execute("""
            SELECT c.name, ty.name, c.max_length, c.is_nullable
            FROM sys.columns c
            JOIN sys.types ty ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(?) ORDER BY c.column_id""", (t,))
        cols = cur.fetchall()
        cur.execute(f"SELECT COUNT(*) FROM [{t}]")
        total = cur.fetchone()[0]
        print(f"{t:<26} {len(cols):>3} คอลัมน์ · {total:>12,} แถว")

        for cname, ctype, mlen, nullable in cols:
            try:
                if ctype in NUMERIC:
                    cur.execute(f"""SELECT COUNT(*) - COUNT([{cname}]),
                                           COUNT(DISTINCT [{cname}]),
                                           MIN([{cname}]), MAX([{cname}]) FROM [{t}]""")
                elif ctype in DATE:
                    cur.execute(f"""SELECT COUNT(*) - COUNT([{cname}]),
                                           COUNT(DISTINCT [{cname}]),
                                           CONVERT(varchar(10), MIN([{cname}]), 120),
                                           CONVERT(varchar(10), MAX([{cname}]), 120) FROM [{t}]""")
                elif ctype in ("text", "ntext", "image", "xml", "varbinary"):
                    cur.execute(f"SELECT COUNT(*) - COUNT([{cname}]), NULL, NULL, NULL FROM [{t}]")
                else:
                    cur.execute(f"""SELECT SUM(CASE WHEN [{cname}] IS NULL OR LTRIM([{cname}])='' THEN 1 ELSE 0 END),
                                           COUNT(DISTINCT [{cname}]),
                                           MIN(LEN([{cname}])), MAX(LEN([{cname}])) FROM [{t}]""")
                empty, distinct, mn, mx = cur.fetchone()
            except Exception as e:
                empty = distinct = mn = mx = None
                print(f"   ! {cname}: {str(e)[:60]}")

            sample = ""
            if distinct and distinct <= 12 and not PII.search(cname) and ctype not in DATE:
                try:
                    cur.execute(f"""SELECT TOP 12 [{cname}], COUNT(*) n FROM [{t}]
                                    WHERE [{cname}] IS NOT NULL
                                    GROUP BY [{cname}] ORDER BY n DESC""")
                    sample = " · ".join(f"{v}({n:,})" for v, n in cur.fetchall())[:220]
                except Exception:
                    pass

            pct = round(100.0 * (empty or 0) / total, 1) if total else None
            rows_out.append([t, total, cname, ctype, mlen, "Y" if nullable else "N",
                             empty, pct, distinct, mn, mx, sample])

    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "column-profile.csv")
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["table", "table_rows", "column", "type", "max_length", "nullable",
                    "empty_count", "empty_pct", "distinct", "min", "max", "sample_values"])
        w.writerows(rows_out)
    print(f"\nเขียน {len(rows_out):,} แถว -> {path}")
    conn.close()


if __name__ == "__main__":
    main()
