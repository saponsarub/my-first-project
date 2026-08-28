# -*- coding: utf-8 -*-
"""สำรวจเบื้องต้น: ฐานข้อมูลอะไรบ้างที่เข้าถึงได้ · มี view/table อะไร

credential อ่านจาก env ไม่ hardcode
    $env:MIS_USER="..."; $env:MIS_PWD="..."; python scripts/itec/itec_probe.py
"""
import os
import sys

import pyodbc

sys.stdout.reconfigure(encoding="utf-8")

SERVER = os.environ.get("MIS_SERVER", "192.168.43.250,18963")
USER = os.environ.get("MIS_USER")
PWD = os.environ.get("MIS_PWD")
if not USER or not PWD:
    sys.exit('ต้องตั้ง credential ก่อน:  $env:MIS_USER="..."; $env:MIS_PWD="..."')


def connect(db=None):
    cs = (f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};"
          f"UID={USER};PWD={PWD};TrustServerCertificate=yes;")
    if db:
        cs += f"DATABASE={db};"
    return pyodbc.connect(cs, timeout=30)


cn = connect()
cur = cn.cursor()
cur.execute("SELECT @@VERSION")
print("SERVER:", cur.fetchone()[0].split("\n")[0])
cur.execute("SELECT DB_NAME(), SUSER_NAME()")
db, who = cur.fetchone()
print("DEFAULT DB:", db, "· USER:", who)

print("\n=== ฐานข้อมูลที่มองเห็น ===")
cur.execute("SELECT name, state_desc FROM sys.databases ORDER BY name")
dbs = [(r[0], r[1]) for r in cur.fetchall()]
for n, s in dbs:
    print(f"  {n:<40} {s}")

for name, state in dbs:
    if state != "ONLINE" or name in ("master", "tempdb", "model", "msdb"):
        continue
    try:
        c2 = connect(name)
        k = c2.cursor()
        k.execute("""SELECT o.type_desc, COUNT(*)
                     FROM sys.objects o
                     WHERE o.type IN ('U','V')
                     GROUP BY o.type_desc""")
        rows = k.fetchall()
        if rows:
            print(f"\n--- {name} ---")
            for t, c in rows:
                print(f"    {t:<12} {c}")
            k.execute("""SELECT TOP 25 s.name + '.' + o.name, o.type_desc
                         FROM sys.objects o JOIN sys.schemas s ON s.schema_id = o.schema_id
                         WHERE o.type IN ('U','V') ORDER BY o.name""")
            for nm, td in k.fetchall():
                print(f"      {nm:<55} {td}")
        c2.close()
    except Exception as e:
        print(f"\n--- {name} --- เข้าไม่ได้: {str(e)[:90]}")

cn.close()
