"""ต่อฐาน MIS แล้วดึง rpt.dim_item_itec

credential อ่านจาก env ไม่ hardcode เพราะไฟล์นี้อยู่ใน git repo
    $env:MIS_USER="..."; $env:MIS_PWD="..."; python TESTCONNECT.py
"""
import os
import sys

import pyodbc
import pandas as pd

server = os.environ.get("MIS_SERVER", "192.168.43.250,18963")
username = os.environ.get("MIS_USER")
password = os.environ.get("MIS_PWD")

if not username or not password:
    sys.exit('ต้องตั้ง credential ก่อน:  $env:MIS_USER="..."; $env:MIS_PWD="..."')

conn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={server};"
  # f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "TrustServerCertificate=yes;"
)

print("Connected!")
query = """
SELECT TOP (1000)
    *
FROM rpt.dim_item_itec
"""

df = pd.read_sql(query, conn)
print(df)