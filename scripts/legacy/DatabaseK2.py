"""ต่อฐาน K2 (HPCOM7) ดึงข้อมูลตัวอย่าง

credential อ่านจาก env ไม่ hardcode เพราะไฟล์นี้อยู่ใน git repo
    $env:K2_USER="..."; $env:K2_PWD="..."; python DatabaseK2.py
"""
import os
import sys

import pyodbc
import pandas as pd

server = os.environ.get("K2_SERVER", "43.254.133.123")
database = os.environ.get("K2_DB", "HPCOM7")
username = os.environ.get("K2_USER")
password = os.environ.get("K2_PWD")

if not username or not password:
    sys.exit('ต้องตั้ง credential ก่อน:  $env:K2_USER="..."; $env:K2_PWD="..."')

conn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "TrustServerCertificate=yes;"
)

print("Connected!")
query = """
SELECT TOP (1000)
    *
FROM [HPCOM7].[dbo].[CUSTOMER_CARD]
"""

df = pd.read_sql(query, conn)

print(df)