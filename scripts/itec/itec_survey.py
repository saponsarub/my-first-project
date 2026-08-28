# -*- coding: utf-8 -*-
"""สำรวจ view ทั้งหมดของฐาน MIS (ITEC) — read-only

ดึง: รายชื่อ view · คอลัมน์ + ชนิดข้อมูล · จำนวนแถว · ช่วงวันที่
เขียนผลลง COM7-Knowledge-Base/02_System/_raw/itec-*.csv

credential อ่านจาก env:
    $env:MIS_USER="..."; $env:MIS_PWD="..."; python scripts/itec/itec_survey.py
"""
import csv
import os
import sys
import time

import pyodbc

sys.stdout.reconfigure(encoding="utf-8")

SERVER = os.environ.get("MIS_SERVER", "192.168.43.250,18963")
USER = os.environ.get("MIS_USER")
PWD = os.environ.get("MIS_PWD")
DB = os.environ.get("MIS_DB", "_db1_3f9c2a7e-8b41-4d6f-9c25-1a7e5c0d2b8f")
OUT = os.environ.get(
    "ITEC_OUT",
    r"C:\Projects\my-first-project\COM7-Knowledge-Base\02_System\_raw")

if not USER or not PWD:
    sys.exit('ต้องตั้ง credential ก่อน:  $env:MIS_USER="..."; $env:MIS_PWD="..."')

cn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};DATABASE={DB};"
    f"UID={USER};PWD={PWD};TrustServerCertificate=yes;", timeout=60)
cur = cn.cursor()

# ---------- 1. รายชื่อ view ----------
cur.execute("""
SELECT s.name, v.name, v.create_date, v.modify_date
FROM sys.views v JOIN sys.schemas s ON s.schema_id = v.schema_id
ORDER BY s.name, v.name
""")
views = [(r[0], r[1], r[2], r[3]) for r in cur.fetchall()]
print(f"พบ {len(views)} view")

# ---------- 2. คอลัมน์ ----------
cur.execute("""
SELECT s.name, v.name, c.column_id, c.name, t.name,
       c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
JOIN sys.columns c ON c.object_id = v.object_id
JOIN sys.types   t ON t.user_type_id = c.user_type_id
ORDER BY s.name, v.name, c.column_id
""")
cols = cur.fetchall()
with open(f"{OUT}\\itec-columns.csv", "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["schema", "view", "ordinal", "column", "type",
                "max_length", "precision", "scale", "is_nullable"])
    for r in cols:
        w.writerow(list(r))
print(f"เขียน itec-columns.csv — {len(cols)} คอลัมน์")

# ---------- 3. จำนวนแถว + ช่วงวันที่ ----------
rows_out = []
for sch, vw, cdate, mdate in views:
    full = f"[{sch}].[{vw}]"
    n, secs, err = None, None, ""
    t0 = time.time()
    try:
        cur.execute(f"SELECT COUNT_BIG(*) FROM {full} WITH (NOLOCK)")
        n = cur.fetchone()[0]
        secs = round(time.time() - t0, 2)
    except Exception as e:
        err = str(e)[:120]
        secs = round(time.time() - t0, 2)
    ncol = sum(1 for c in cols if c[0] == sch and c[1] == vw)
    print(f"  {full:<48} {str(n):>12}  {secs:>6}s  {err}")
    rows_out.append([sch, vw, n, ncol, secs, cdate, mdate, err])

with open(f"{OUT}\\itec-views.csv", "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["schema", "view", "rows", "columns", "count_seconds",
                "create_date", "modify_date", "error"])
    w.writerows(rows_out)
print("เขียน itec-views.csv")
cn.close()
